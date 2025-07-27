import * as admin from 'firebase-admin';
import { firestore } from 'firebase-functions/v2'; // Import firestore from v2

admin.initializeApp();
const db = admin.firestore();

// This function is triggered whenever a new document is created in the 'interests' collection.
export const sendInterestNotification = firestore.onDocumentCreated(
    'interests/{interestId}',
    async (event) => {
        // Get the data from the new interest document
        const interest = event.data?.data();
        const fromUserId = interest?.fromUserId;
        const toUserId = interest?.toUserId;

        if (!toUserId || !fromUserId) {
            console.log("Missing toUserId or fromUserId. Exiting.");
            return;
        }

        // 1. Fetch the recipient's FCM token from the 'users' collection
        const recipientDoc = await db.collection('users').doc(toUserId).get();
        const recipientData = recipientDoc.data();
        const fcmToken = recipientData?.fcmToken;

        if (!fcmToken) {
            console.log(`FCM token not found for user ${toUserId}. Cannot send notification.`);
            return;
        }

        // 2. Fetch the sender's profile to get their name for the notification message
        const senderDoc = await db.collection('users').doc(fromUserId).get();
        const senderData = senderDoc.data();
        const senderName = senderData?.name ?? 'Someone';

        // 3. Construct the notification message
        const payload = {
            notification: {
                title: 'New Interest!',
                body: `${senderName} is interested in you!`,
            },
            token: fcmToken,
        };

        // 4. Send the notification
        try {
            const response = await admin.messaging().send(payload);
            console.log('Successfully sent message:', response);
        } catch (error) {
            console.error('Error sending message:', error);
        }
    });