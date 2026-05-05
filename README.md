# LearnHub (edu_pro)

Flutter e-learning app with Firebase auth, role-based flows (Student/Instructor), Firestore courses, and YouTube playlist lessons.

## Implemented

- Firebase Authentication
  - Email/Password
  - Google Sign-In
- Role selection at registration
  - Student
  - Instructor
- Role-based app routing after login
  - Student -> Student Shell
  - Instructor -> Instructor Dashboard
- Firestore data model
  - `users`
  - `instructors`
  - `courses`
- Student experience
  - Categories
  - Top Courses (admin)
  - New Courses (instructor)
  - Course thumbnails from YouTube playlist
  - Open playlist videos inside app
- Instructor experience
  - Dashboard with total courses
  - Add Course (title, category, playlist URL)
  - My Courses (real-time list + delete)
- YouTube playlist integration
  - Playlist items API
  - Pagination support
  - Cache duration: 15 minutes

## Firestore Collections

### users

```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "role": "student | instructor",
  "createdAt": "timestamp"
}
```

### instructors

```json
{
  "userId": "string",
  "name": "string",
  "bio": "string",
  "image": "string",
  "createdAt": "timestamp"
}
```

### courses

```json
{
  "id": "string",
  "title": "string",
  "category": "string",
  "playlistId": "string",
  "instructorId": "admin | uid",
  "instructorName": "string",
  "isAdminCourse": true,
  "createdAt": "timestamp"
}
```

## Required Setup

## 1) Firebase project

- Create Firebase project
- Enable Authentication:
  - Email/Password
  - Google
- Create Firestore database (production/test mode as needed)
- Add Android app package name exactly as in your Flutter project

## 2) Android Firebase config

Download `google-services.json` and place it here:

- `android/app/google-services.json`

Without this file, Android build fails at `processDebugGoogleServices`.

## 3) iOS Firebase config (if needed)

Download `GoogleService-Info.plist` and place it here:

- `ios/Runner/GoogleService-Info.plist`

## 4) YouTube API key

Build with dart defines:

```powershell
cd "D:\New folder\edu_pro"
flutter build apk --release `
  --dart-define=YOUTUBE_API_KEY=YOUR_ACTUAL_KEY `
  --dart-define=YOUTUBE_PLAYLIST_ID=PLb6ZzJ93PVwpsrq-WMPzdHzoI5BXfMoIj
```

Optional (for Google auth token edge cases):

```powershell
--dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

## Important security note

If you have shared API keys publicly, rotate/regenerate them in Google Cloud Console immediately.

## Run locally

```powershell
cd "D:\New folder\edu_pro"
flutter pub get
flutter analyze
flutter run
```

## Build APK

```powershell
cd "D:\New folder\edu_pro"
flutter build apk --release --dart-define=YOUTUBE_API_KEY=YOUR_ACTUAL_KEY
```

## Architecture

- `presentation` -> UI/screens/providers
- `domain` -> entities/repositories interfaces
- `data` -> firebase/youtube services + repository implementations

## Notes

- Admin courses are seeded automatically (once) when app starts and user logs in.
- Student home separates admin and instructor courses using `isAdminCourse`.
- Instructor can only manage own courses in dashboard/my-courses screens.
