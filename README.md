# NearMe - A Map-Based Social App for Students

## 📱 Overview

NearMe is a Flutter-based, full-stack social networking app designed for college students to discover and connect with peers around their campus. It leverages location data to plot users on a campus map, allowing them to browse student profiles, discover common interests, and eventually chat (online and offline via mesh networks).

The app is built with a strong focus on user privacy, clean UI/UX, and scalability for a real-world student community. The first MVP will use Firebase as a backend, and optionally support a future integration with Bitchat for offline peer-to-peer messaging.

---

## 🔑 Core Features

### 1. Google Sign-In

* Users will authenticate using their Google account.
* On first sign-in, they will be redirected to create their profile.

### 2. Profile Creation

* After signing in, users will be prompted to set up their profile.
* **Profile fields include:**

  * Name
  * College Year (e.g., 1st, 2nd, 3rd, 4th)
  * Branch/Department
  * Interests (e.g., Flutter, Web Dev, Design)
  * Profile Picture (upload via gallery or camera)
  * Social handles (optional)
* Profiles will be stored in Firebase Firestore and accessible through UID.

### 3. Campus Map View

* Map is centered around the user's campus (static default region if GPS fails).
* Each user is shown as a pin (or avatar) on the map, using their last known location.
* Clicking a pin opens a mini-profile card.

### 4. User Discovery

* A list view of nearby users will be available as an alternative to the map.
* Users can sort or filter profiles by department, year, or interest tags.

### 5. Profile View

* Tapping on a user pin or list entry opens their full profile.
* Display includes name, year, department, interests, and any social links.
* There will be a visible badge or section: **"Offline Chat: Coming Soon"**

### 6. Interest Button ("🔥 Interested")
Each profile has an "Interested" button like a soft-like.

When a user taps this:

A notification is sent to the profile owner saying:
"Someone is interested in your profile!"

This is stored in Firestore for analytics and optional mutual matching in the future.

Duplicate interest actions (spamming) will be throttled or blocked.

### 7. Notifications (Cloud Messaging)
Users will receive push notifications via Firebase Cloud Messaging for:

When someone hits "Interested" on their profile.

When they receive a message (future feature).

Notification preferences will be configurable in future versions (e.g., mute for 24h, etc.).

### 8. Placeholder for Chat

* MVP will not include real chat functionality.
* Placeholder UI will suggest that offline chat is being built.
* This prepares for future integration with Bitchat (optional mesh protocol).

### 9. Clubs (Group Profiles) 🎭
Any user can create a club — no restrictions or verification needed.
Clubs are group-style profiles with:
Banner image, description, category tags
A feed of posts and announcements
Admin(s) and members

“Join Club” button (instead of “Follow”)

Club creators become admins and can:

Add/remove posts

Moderate members

Members get notified for new posts and events

Great for both official and unofficial groups on campus — from "Coding Club" to "Chess & Chill" to "Garage Band Jammers"

### 10. Privacy & Location Handling

* Real-time GPS will NOT be used continuously to preserve battery and privacy.
* Location updates will be requested only during key interactions (e.g., map open).
* All data will be opt-in. Users can hide their location or temporarily disable it.

---

## 💡 Future Features (Post-MVP)

### 11. Offline Chat (via Bitchat integration)

* Wrap Bitchat's P2P messaging into the app using Flutter bridge or a native wrapper.
* Allow students to chat even without the internet using mesh technology.

### 12. Profile Verification

* Link student email (e.g., `@college.edu`) for badge of authenticity.

### 13. Event Broadcasting

* Allow users to post small events (e.g., "Flutter meetup near cafeteria") pinned to the map.

### 14. Analytics for Admins (Optional)

* Admin dashboard with number of active users, peak times, interest tags heatmap.

---

## 🔧 Tech Stack

* **Frontend:** Flutter (Dart), Riverpod
* **Authentication:** Firebase Auth (Google)
* **Database:** Firebase Firestore
* **Storage:** Firebase Storage (for profile pictures)
* **Maps API:** Google Maps
* **Location:** `geolocator` package
* **Chat (Future):** Bitchat open-source bridge

---

## 🗂️ Suggested Folder Structure

```plaintext
/lib
 ├── app/             # App-level setup (theme, routes, main)
 ├── core/            # Constants, helpers, API keys
 ├── features/
 │   ├── auth/        # Google sign-in
 │   ├── profile/     # Profile creation + display
 │   ├── map/         # Campus map with user pins
 │   ├── discovery/   # List-based user browsing
 │   ├── chat/        # Placeholder / future chat integration
 ├── widgets/         # Reusable UI components
```

---

## 🔓 Permissions

* Location permission (with rationale)
* Gallery/Camera access for profile picture

---

## 🧠 AI Code Assist Notes

* Ensure all features are modular and structured by feature folder.
* Use Riverpod for state control and DI.
* Location updates should be handled with permission safety and minimal polling.
* Firebase models should use `fromJson` and `toJson` conversions.
* Maps should render user markers based on geo-coordinates from Firestore.
* Include meaningful comments and test IDs for key widgets for Copilot-style tools.

---

## 💬 Final Note

This README is intended to help both human collaborators and AI tools understand the goals, structure, and future scope of the NearMe app. Let's build something unforgettable!
