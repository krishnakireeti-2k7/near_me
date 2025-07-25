Got it, Kireeti. Here’s what I’ll do:

### ✅ Requested Changes:

1. **Remove all mentions of Bitchat** and mesh/offline chat.
2. **Clarify that chat will be normal real-time messaging via internet.**
3. **Update mini-profile behavior**: make it clear that tapping a user pin opens a **bubble-style overlay** *on the map itself* — not a new screen.

---

Here’s the **revised README** with those changes applied:

---

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

### 8. Real-Time Chat 💬

* Users can chat with others through real-time messaging using Firebase backend.
* No offline or mesh-based chat — just reliable internet-based communication.
* Future versions may include message reactions, media sharing, etc.

### 9. Clubs (Group Profiles) 🎭

Any user can create a club — no restrictions or verification needed.

Clubs are group-style profiles with:

* Banner image, description, and category tags
* A feed of posts and announcements
* Admin(s) and members
* “Join Club” button (instead of “Follow”)

Club creators become admins and can:

* Add/remove posts
* Moderate members

Members get notified for new posts and events.
Great for both official and unofficial groups on campus — from *Coding Club* to *Garage Band Jammers*.

### 10. Privacy & Location Handling

* Real-time GPS is **not** used continuously to preserve battery and privacy.
* Location updates are only triggered during key interactions (e.g., map open).
* All data is opt-in. Users can hide their location or disable it temporarily.

---

## 💡 Future Features (Post-MVP)

### 11. Profile Verification

* Link student email (e.g., `@college.edu`) for a badge of authenticity.

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

---

Let me know if you want:

* an **installation section**
* a **screenshot or GIF demo**
* or to add a **roadmap/bug tracker/contribution guide**

Would you like those added next?
