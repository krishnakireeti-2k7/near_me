// file: functions/src/index.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as pubsub from 'firebase-functions/v1/pubsub';
import { firestore } from 'firebase-functions/v2';
import { setGlobalOptions } from 'firebase-functions/v2/options';
import { HttpsError, CallableRequest } from 'firebase-functions/v2/https';

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

// Scheduled Function: Delete interests older than 30 days
// ✅ Scheduled Function: Delete interests older than 30 days
export const cleanupOldInterests = pubsub.schedule('every 24 hours').onRun(
    async (context) => {
        console.log('Running cleanupOldInterests job...'); // ✅ Add this line
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

// NEW INTERFACE for type checking the data payload
interface NotificationData {
    token: string;
    title: string;
    body: string;
    customData: { [key: string]: string };
}

// ✅ FINAL FIX: Use the single 'request' parameter with correct types and access properties accordingly.
export const sendNotification = functions.https.onCall(
  async (request: CallableRequest<NotificationData>) => { 
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated', 
        'The function must be called while authenticated.'
      );
    }
  
    // The data payload is correctly accessed via request.data
    const { token, title, body, customData } = request.data;
  
    if (!token || !title || !body) {
      throw new HttpsError(
        'invalid-argument', 
        'The function must be called with a token, title, and body.'
      );
    }
  
    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: customData,
    };
  
    try {
      const response = await admin.messaging().sendToDevice(token, payload);
      console.log('Successfully sent message:', response);
      return { success: true };
    } catch (error) {
      console.error('Error sending message:', error);
      throw new HttpsError(
        'internal', 
        'Failed to send notification.', 
        error
      );
    }
});