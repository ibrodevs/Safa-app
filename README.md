# DoGO Flutter App

Flutter client for DoGO/SafaApp. The app supports client and carrier registration, JWT login, secure token storage, session restore, delivery service cards, multi-stop shipment creation, history, profile, payments and push notifications.

## Requirements

- Flutter SDK matching `environment.sdk` in `pubspec.yaml`
- Android Studio/Xcode for platform builds
- Firebase project configuration
- Google Maps API keys restricted by Android package `kg.genesis.safa_app` and the iOS bundle identifier

## Setup

```bash
cd front
flutter pub get
cp .env.example .env
```

Runtime API URL is read from Dart defines:

```bash
flutter run --dart-define=DOGO_API_BASE_URL=http://127.0.0.1:8000/api/
```

Finik values are loaded from `assets/finik_key.env`. Keep real values local and do not commit them.

## Google Maps

Android reads `GOOGLE_MAPS_API_KEY` from Gradle properties or environment:

```bash
GOOGLE_MAPS_API_KEY=your_key flutter run
```

iOS has `GoogleMapsApiKey` placeholder in `ios/Runner/Info.plist`; configure the build setting or xcconfig value before enabling Google Maps screens.

The current production map screen still uses the existing `flutter_map` flow while Google Maps configuration is prepared. Do not remove the old map until the Google Maps screen has been fully verified.

## Build APK

For a test phone, debug APK is enough:

```bash
flutter build apk --debug \
  --dart-define=DOGO_API_BASE_URL=https://yourusername.pythonanywhere.com/api/
```

Release APK requires Android signing files:

- `android/key.properties`
- release keystore file referenced by `storeFile`
- `keyAlias`, `keyPassword`, `storePassword`

Build release:

```bash
GOOGLE_MAPS_API_KEY=your_key flutter build apk --release \
  --dart-define=DOGO_API_BASE_URL=https://yourusername.pythonanywhere.com/api/
```

Install on Android:

```bash
flutter install
# or
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Firebase

Keep `firebase_options.dart`, Android `google-services.json`, and iOS Firebase files aligned with the Firebase project. FCM registration happens after app start and never prints tokens in app logs.

## Auth Checks

1. Register a client or carrier.
2. Confirm OTP.
3. Log out from profile.
4. Open `Login` from the role selection screen.
5. Enter `996XXXXXXXXX` and password.
6. Restart the app; Splash restores the session from `flutter_secure_storage`.
7. Use a wrong password; the app should show a friendly error.

## Tests

```bash
flutter test
```

Manual map verification still requires real device permissions, network, backend URL, Firebase configuration and map provider keys.
