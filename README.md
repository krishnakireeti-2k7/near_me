# NearMe - A Map-Based Social App for Students

## 📱 Overview

NearMe is a Flutter-based, full-stack social networking app designed for college students to discover and connect with peers around their campus. It leverages location data to plot users on a campus map, allowing them to browse student profiles, discover common interests, and chat in real time.

The app is built with a strong focus on user privacy, clean UI/UX, and scalability for real-world student communities. The first MVP will use Firebase as a backend with real-time chat support.

---

## 🔑 Core Features

### 1. Google Sign-In

* Users authenticate using their Google account.
* On first sign-in, they are redirected to create their profile.

### 2. Profile Creation

* After signing in, users are prompted to set up their profile.

* **Profile fields include:**

  * Name
  * College Year (e.g., 1st, 2nd, 3rd, 4th)
  * Branch/Department
  * Interests (e.g., Flutter, Web Dev, Design)
  * Profile Picture (upload via gallery or camera)
  * Social handles (optional)

* Profiles are stored in Firebase Firestore and accessible via UID.

### 3. Campus Map View

* The map is centered around the user's campus (with a static fallback region if GPS fails).
* Each user is shown as a pin (avatar) on the map, using their last known location.
* **Tapping a pin opens a floating bubble-style mini-profile card directly on the map** — not a separate screen.

### 4. User Discovery

* A list view of nearby users is also available as an alternative to the map.
* Users can sort or filter profiles by department, year, or interest tags.

### 5. Profile View

* Tapping on a user pin or list entry reveals their full profile.
* Includes name, year, department, interests, and social links.

### 6. Interest Button ("🔥 Interested")

Each profile has an "Interested" button like a soft-like.

When a user taps this:

* A notification is sent to the profile owner:
  `"Someone is interested in your profile!"`
* This is stored in Firestore for analytics and optional mutual matching in the future.
* Duplicate interest actions (spamming) are throttled or blocked.

### 7. Notifications (Cloud Messaging)

Users will receive push notifications via Firebase Cloud Messaging for:

* When someone hits "Interested" on their profile.
* When they receive a new message.

Notification preferences will be configurable in future versions (e.g., mute for 24h, etc.).

### 8. Ephemeral Chat System
To optimize Firestore usage and reduce infrastructure costs, NearMe implements an ephemeral messaging system. Chat messages are automatically deleted 12 hours after creation.

🔧 Implementation Details:
Each message document includes a timestamp field at creation.

A scheduled Cloud Function runs periodically (e.g. every hour) to:

Query messages older than 12 hours.

Delete expired messages from Firestore.

Alternatively, TTL (Time-To-Live) policies may be used if supported in future updates.


### 9 🌐 Google Places Integration
The search bar at the top of the map screen will be powered by the Google Places API.

Users can type in any location, and real-time suggestions will appear (e.g., cities, landmarks, campuses, etc.).

On selecting a location, the map camera will instantly shift to the selected area.

Users in that location will be displayed as pins on the map, just like nearby users.

👤 Dual Suggestions: Locations + Users
The search results UI will be split into two sections:

The top half will show location suggestions (powered by Google Places).

The bottom half will show user suggestions that match the search query by name.

### 10📍 Location Control (User Privacy Feature)
When a user taps on their own profile on the map, a bottom sheet appears. This now includes two important controls:

🟢 Location Sharing Toggle
A switch allows users to pause or resume automatic location updates.

When turned off, the app stops updating the user’s location every 5 minutes.

When turned back on, the app will instantly update the location and resume the 5-minute interval updates.

🔄 Manual Location Update Button
A "Update Location Now" button is also provided for manual control.

On tap, the user's location is instantly updated, even if the 5-minute timer hasn't triggered yet.

This is helpful for users who move often and want real-time accuracy.


---

## 💡 Future Features (Post-MVP)

### 12. Event Broadcasting

* Users can post small events (e.g., "Flutter meetup near cafeteria") pinned to the map.

### 13. Analytics for Admins (Optional)

* Admin dashboard with number of active users, peak times, and interest tag heatmaps.

---

## 🔧 Tech Stack

* **Frontend:** Flutter (Dart), Riverpod
* **Authentication:** Firebase Auth (Google)
* **Database:** Firebase Firestore
* **Storage:** Firebase Storage (for profile pictures)
* **Maps API:** Google Maps
* **Location:** `geolocator` package
* **Chat:** Firebase-powered real-time messaging

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
 │   ├── chat/        # Real-time chat module
 ├── widgets/         # Reusable UI components
```

---

## 🔓 Permissions

* Location permission (with rationale)
* Gallery/Camera access for profile picture

---

## 🧠 AI Code Assist Notes

* Keep features modular and organized in feature folders.
* Use Riverpod for state management and DI.
* Ensure location updates are permission-safe and efficient.
* Firebase models should use `fromJson`/`toJson` for serialization.
* User pins on map should be rendered based on Firestore geo-coordinates.
* Include comments and test IDs for Copilot-style tools.

---

## 💬 Final Note

This README is designed to help both human collaborators and AI tools understand the architecture, purpose, and roadmap of the NearMe app. Let’s build something unforgettable!