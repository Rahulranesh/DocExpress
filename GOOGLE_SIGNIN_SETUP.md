# Google Sign-In Setup (DocXpress)

This project now supports Google Sign-In through:
- Flutter app: gets a Google ID token
- Backend API: verifies the token and issues your app JWT

## 1) Google Cloud / Firebase setup

Use either Firebase Console or Google Cloud OAuth screen.

1. Create/select your project.
2. Configure OAuth consent screen.
3. Create OAuth 2.0 Client IDs:
   - **Web application** client ID (required by backend + Flutter `serverClientId`)
   - **Android** client ID for package `com.ranesh.docxpress`
   - **iOS** client ID for your iOS bundle id (if you ship iOS)
4. Add app SHA keys for Android in Firebase/Google settings:
   - SHA-1
   - SHA-256

## 2) Backend configuration

Set environment variable in backend deployment (Render/local):

```bash
GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

Then deploy/restart backend.

## 3) Flutter app configuration

Pass web client ID at build/run time:

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

For release builds:

```bash
flutter build appbundle --release --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

## 4) Android-specific checks

- Package name must match: `com.ranesh.docxpress`
- Use the same SHA-1/SHA-256 from your signing key (Play/App signing key for production)
- If production login fails but debug works, missing production SHA is usually the cause

## 5) iOS-specific checks (if enabled)

- Add URL scheme from your iOS client config (`REVERSED_CLIENT_ID`) to `Info.plist`
- Ensure bundle id matches the OAuth iOS client

## 6) API endpoint added

- `POST /api/auth/google`
- Body:

```json
{
  "idToken": "google-id-token"
}
```

- Response format matches existing auth responses (`token` + `user`)

## 7) Common failure reasons

- `Google sign-in failed: missing ID token` in app:
  - `GOOGLE_WEB_CLIENT_ID` not passed via `--dart-define`
- `Google login is not configured on server`:
  - backend env missing `GOOGLE_WEB_CLIENT_ID`
- `Google authentication failed`:
  - wrong web client ID, wrong SHA, or OAuth consent/app config incomplete
