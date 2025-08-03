// file: functions/src/index.ts

import * as admin from 'firebase-admin';
import { firestore } from 'firebase-functions/v2';
// Removed 'dayjs' import as it's no longer needed for daily counter logic here

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

        const recipientRef = db.collection('users').doc(toUserId);

        // --- UPDATED LOGIC: Only increment totalInterestsCount ---
        try {
            await recipientRef.update({
                totalInterestsCount: admin.firestore.FieldValue.increment(1)
            });
            console.log(`Successfully incremented totalInterestsCount for user: ${toUserId}`);
        } catch (error) {
            console.error(`Error incrementing totalInterestsCount for user ${toUserId}:`, error);
            // If the user document or field doesn't exist, this update might fail.
            // Consider setting initial values if document is new, or ensuring documents are created on user signup.
            await recipientRef.set({ totalInterestsCount: 1 }, { merge: true }); // Ensure it gets set if not present
        }
        // --- END UPDATED LOGIC ---

        // Fetch the recipient's FCM token from the 'users' collection (to get latest data including counters)
        const updatedRecipientDoc = await recipientRef.get();
        const updatedRecipientData = updatedRecipientDoc.data();
        const fcmToken = updatedRecipientData?.fcmToken;

        if (!fcmToken) {
            console.log(`FCM token not found for user ${toUserId}. Cannot send push notification.`);
        }

        // Fetch the sender's profile to get their name for the notification message
        const senderDoc = await db.collection('users').doc(fromUserId).get();
        const senderData = senderDoc.data();
        const senderName = senderData?.name ?? 'Someone';

        // Construct and send the push notification (only if token exists)
        if (fcmToken) {
            const payload = {
                notification: {
                    title: 'New Interest!',
                    body: `${senderName} is interested in you!`,
                },
                token: fcmToken,
            };

            try {
                const response = await admin.messaging().send(payload);
                console.log('Successfully sent push message:', response);
            } catch (error) {
                console.error('Error sending push message:', error);
            }
        }
    });