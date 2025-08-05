// file: functions/src/index.ts

import * as functions from 'firebase-functions'; // v1
import * as admin from 'firebase-admin';
import * as pubsub from 'firebase-functions/v1/pubsub'; // ✅ Import v1 pubsub scheduler
import { firestore } from 'firebase-functions/v2';
import { setGlobalOptions } from 'firebase-functions/v2/options';


setGlobalOptions({ region: 'us-central1' });

admin.initializeApp();
const db = admin.firestore();

// v2 Firestore Trigger
export const sendInterestNotification = firestore.onDocumentCreated(
  'interests/{interestId}',
  async (event) => {
    const interest = event.data?.data();
    const fromUserId = interest?.fromUserId;
    const toUserId = interest?.toUserId;

    if (!toUserId || !fromUserId) return;

    const recipientRef = db.collection('users').doc(toUserId);

    try {
      await recipientRef.update({
        totalInterestsCount: admin.firestore.FieldValue.increment(1),
      });
    } catch {
      await recipientRef.set({ totalInterestsCount: 1 }, { merge: true });
    }

    const updatedRecipientData = (await recipientRef.get()).data();
    const fcmToken = updatedRecipientData?.fcmToken;

    const senderName =
      (await db.collection('users').doc(fromUserId).get()).data()?.name ??
      'Someone';

    if (fcmToken) {
      await admin.messaging().send({
        notification: {
          title: 'New Interest!',
          body: `${senderName} is interested in you!`,
        },
        token: fcmToken,
      });
    }
  }
);

// ✅ Scheduled Function: Delete interests older than 30 days
export const cleanupOldInterests = pubsub.schedule('every 24 hours').onRun(
    async (context) => {
        const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
        );

        const oldInterestsSnapshot = await db.collection('interests')
            .where('timestamp', '<', thirtyDaysAgo)
            .get();

        if (oldInterestsSnapshot.empty) {
            console.log('No old interests to delete.');
            return;
        }

        const batch = db.batch();
        oldInterestsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`Deleted ${oldInterestsSnapshot.docs.length} old interests.`);
    }
);
