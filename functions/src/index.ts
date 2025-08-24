// file: index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { firestore, https } from 'firebase-functions/v2';
import { setGlobalOptions } from 'firebase-functions/v2/options';
import { onSchedule } from 'firebase-functions/v2/scheduler'; // ✅ CORRECT IMPORT

setGlobalOptions({ region: 'us-central1' });

admin.initializeApp();
const db = admin.firestore();

// Firestore Trigger for Interests
export const sendInterestNotification = firestore.onDocumentCreated(
  'interests/{interestId}',
  async (event) => {
    functions.logger.info('sendInterestNotification triggered', { interestId: event.params.interestId });
    const interest = event.data?.data();
    const fromUserId = interest?.fromUserId;
    const toUserId = interest?.toUserId;

    if (!toUserId || !fromUserId) {
      functions.logger.error('Missing toUserId or fromUserId', { interest });
      return;
    }

    const recipientRef = db.collection('users').doc(toUserId);

    try {
      await recipientRef.update({
        totalInterestsCount: admin.firestore.FieldValue.increment(1),
      });
      functions.logger.info('Updated totalInterestsCount for user', { toUserId });
    } catch (error) {
      functions.logger.warn('Failed to update totalInterestsCount, setting initial value', { error, toUserId });
      await recipientRef.set({ totalInterestsCount: 1 }, { merge: true });
    }

    const updatedRecipientData = (await recipientRef.get()).data();
    const fcmToken = updatedRecipientData?.fcmToken;

    const senderName =
      (await db.collection('users').doc(fromUserId).get()).data()?.name ??
      'Someone';

    if (fcmToken) {
      try {
        await admin.messaging().send({
          notification: {
            title: 'New Interest!',
            body: `${senderName} is interested in you!`,
          },
          data: { screen: 'notifications' },
          token: fcmToken,
        });
        functions.logger.info('Interest notification sent to', { toUserId, fcmToken });
      } catch (error) {
        functions.logger.error('Failed to send interest notification', { toUserId, error });
      }
    } else {
      functions.logger.warn('No FCM token found for recipient', { toUserId });
    }
  }
);

// Firestore Trigger for Friend Requests
export const sendFriendRequestNotification = firestore.onDocumentCreated(
  'friendships/{requestId}',
  async (event) => {
    functions.logger.info('sendFriendRequestNotification triggered', {
      requestId: event.params.requestId,
      documentData: event.data?.data()
    });
    const friendRequest = event.data?.data();
    const senderId = friendRequest?.senderId;
    const receiverId = friendRequest?.user1Id === senderId ? friendRequest?.user2Id : friendRequest?.user1Id;

    if (!senderId || !receiverId) {
      functions.logger.error('Missing senderId or receiverId', { friendRequest });
      return;
    }

    functions.logger.info('Processing friend request', { senderId, receiverId });

    const recipientRef = db.collection('users').doc(receiverId);

    try {
      await recipientRef.update({
        totalFriendRequestsCount: admin.firestore.FieldValue.increment(1),
      });
      functions.logger.info('Updated totalFriendRequestsCount for user', { receiverId });
    } catch (error) {
      functions.logger.warn('Failed to update totalFriendRequestsCount, setting initial value', { error, receiverId });
      await recipientRef.set({ totalFriendRequestsCount: 1 }, { merge: true });
    }

    const updatedRecipientData = (await recipientRef.get()).data();
    const fcmToken = updatedRecipientData?.fcmToken;

    const senderName =
      (await db.collection('users').doc(senderId).get()).data()?.name ??
      'Someone';

    if (fcmToken) {
      try {
        await admin.messaging().send({
          notification: {
            title: 'New Friend Request!',
            body: `${senderName} wants to be friends with you!`,
          },
          data: { screen: 'notifications' },
          token: fcmToken,
        });
        functions.logger.info('Friend request notification sent to', { receiverId, fcmToken });
      } catch (error) {
        functions.logger.error('Failed to send friend request notification', { receiverId, error });
      }
    } else {
      functions.logger.warn('No FCM token found for recipient', { receiverId });
    }
  }
);

// Scheduled Function: Delete chat batches older than 12 hours
// ✅ Uses onSchedule from the correct module
export const cleanupOldChatBatches = onSchedule('every 12 hours', async () => {
  functions.logger.info('Running cleanupOldChatBatches job...');
  const twelveHoursAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 12 * 60 * 60 * 1000)
  );

  const oldBatchesSnapshot = await db
    .collection('chat_batches')
    .where('startTimestamp', '<', twelveHoursAgo)
    .get();

  if (oldBatchesSnapshot.empty) {
    functions.logger.info('No old chat batches to delete.');
    return;
  }

  const batch = db.batch();
  for (const batchDoc of oldBatchesSnapshot.docs) {
    const messagesSnapshot = await db
      .collection('chat_batches')
      .doc(batchDoc.id)
      .collection('messages')
      .get();
    messagesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
    batch.delete(batchDoc.ref);
  }
  await batch.commit();
  functions.logger.info(`Deleted ${oldBatchesSnapshot.docs.length} old chat batches and their messages.`);
});


// Scheduled Function: Delete friend requests older than 30 days
// ✅ Uses onSchedule from the correct module
export const cleanupOldFriendRequests = onSchedule('every 24 hours', async () => {
  functions.logger.info('Running cleanupOldFriendRequests job...');
  const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  );

  const oldFriendRequestsSnapshot = await db
    .collection('friendships')
    .where('status', '==', 'pending')
    .where('timestamp', '<', thirtyDaysAgo)
    .get();

  if (oldFriendRequestsSnapshot.empty) {
    functions.logger.info('No old friend requests to delete.');
  } else {
    const batch = db.batch();
    oldFriendRequestsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      const receiverId = doc.data().user1Id === doc.data().senderId ? doc.data().user2Id : doc.data().user1Id;
      batch.update(db.collection('users').doc(receiverId), {
        totalFriendRequestsCount: admin.firestore.FieldValue.increment(-1),
      });
    });
    await batch.commit();
    functions.logger.info(`Deleted ${oldFriendRequestsSnapshot.docs.length} old friend requests and decremented totalFriendRequestsCount.`);
  }
});

// HTTPS Cloud Function for sending notifications
export const sendNotification = https.onRequest(async (req, res) => {
  const { token, title, body, data } = req.body;

  if (!token || !title || !body) {
    functions.logger.error('Missing required fields: token, title, or body', { body: req.body });
    res.status(400).send('Missing required fields: token, title, or body');
    return;
  }

  try {
    await admin.messaging().send({
      notification: { title, body },
      data,
      token,
    });
    functions.logger.info('Notification sent via HTTPS', { token, title });
    res.status(200).send('Notification sent successfully');
  } catch (error) {
    functions.logger.error('Failed to send notification via HTTPS', { error, token });
    res.status(500).send(`Error sending notification: ${error}`);
  }
});