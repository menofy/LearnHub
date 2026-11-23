# LearnHub

LearnHub is a Flutter e-learning app with separate student and instructor experiences. It uses Firebase Authentication and Cloud Firestore for accounts and course data, and integrates YouTube playlists for lesson videos.

**Repository:** [menofy/LearnHub](https://github.com/menofy/LearnHub)

## Features

- Email/password and Google sign-in.
- Student and instructor roles, with role-based routing after login.
- Student browsing for categories, admin courses, and instructor courses.
- Instructor dashboard with course totals, course creation, and a real-time list of the instructor's own courses with delete support.
- YouTube playlist lessons, including playlist-item pagination and a 15-minute cache, as described in the current repository README.
- Firestore data organized around users, instructors, and courses.

## Tech stack

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Google Sign-In
- Provider (listed in `pubspec.yaml`)
- YouTube playlist integration

## Run locally

### Prerequisites

- Flutter SDK compatible with the version in `pubspec.yaml` (`^3.11.0` at the time of this draft).
- A Firebase project with Authentication and Cloud Firestore configured.
- Platform-specific Firebase configuration files for the platforms you plan to run.
- A YouTube API key for playlist features that require it.

### Setup

1. Clone this repository and open its directory.
2. Configure Firebase for your target platform. The project README says Android requires `android/app/google-services.json`, and iOS requires `ios/Runner/GoogleService-Info.plist` if building for iOS.
3. Install packages:

   ```bash
   flutter pub get
   ```

4. Run static analysis:

   ```bash
   flutter analyze
   ```

5. Start the app on a connected device or emulator:

   ```bash
   flutter run
   ```

## Build an Android APK

The repository README documents passing the YouTube key and playlist ID as Dart defines. Use your own key; never commit real credentials:

```bash
flutter build apk --release \
  --dart-define=YOUTUBE_API_KEY=YOUR_API_KEY \
  --dart-define=YOUTUBE_PLAYLIST_ID=YOUR_PLAYLIST_ID
```

The repository also documents an optional `GOOGLE_SERVER_CLIENT_ID` define for Google authentication token edge cases. Verify the exact current setup before sharing a release build command.

## Configuration and security

- Do not commit API keys, OAuth secrets, or private Firebase credentials.
- Configure Firebase for your own project and target platforms.
- If a real key was accidentally committed, revoke or rotate it through its provider. Do not paste the key into this README.

## Architecture

The repository README describes presentation, domain, and data layers. The source tree includes `core`, `data`, `domain`, and feature areas for course, home, instructor, learning, onboarding, student, profile, and settings.
