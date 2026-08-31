# DoGO Flutter App

Flutter client for DoGO/SafaApp. The app supports client and carrier registration, JWT login, secure token storage, session restore, delivery service cards, multi-stop shipment creation, history, profile, payments and push notifications.

## Requirements

- Flutter SDK matching `environment.sdk` in `pubspec.yaml`
- Android Studio/Xcode for platform builds
- JDK 21 for Android builds (required by the official Yandex MapKit plugin)
- Firebase project configuration
- Yandex MapKit Mobile SDK key

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

Finik uses compile-time `--dart-define` values; no real key is stored in assets or git. See [`docs/FINIK_SETUP.md`](docs/FINIK_SETUP.md) and the backend guide `DoGO/docs/FINIK_CHATFLOW_SETUP.md`.

## Yandex MapKit

The client, point picker and carrier screens use the official Yandex MapKit
Lite Flutter SDK. The Android app contains its restricted mobile MapKit key,
so normal runs and builds do not require a `MAPKIT_API_KEY` environment value:

```bash
flutter run \
  --dart-define=DOGO_API_BASE_URL=http://127.0.0.1:8000/api/
```

Use a key created specifically for **MapKit — Mobile SDK**. The backend
`YANDEX_API_KEY` used for geocoding is a separate configuration.

For iOS, allow both bundle identifiers in the MapKit key restrictions, or pass
a separate iOS key with `--dart-define=MAPKIT_API_KEY=...`:

- Debug / Personal Team: `kg.ibroabdraimov.safa.dev`
- Profile / Release: `kg.genesis.safa.app`

## iOS signing

Debug builds use `kg.ibroabdraimov.safa.dev` and an entitlement file without
APNs so they can be installed with the free `Ibro Abdraimov` Personal Team.
Apple does not support remote push notifications for Personal Teams; local
notifications continue to work.

Profile and Release builds keep `kg.genesis.safa.app` and the production APNs
entitlement. Build those configurations with the paid Apple Developer team
that owns this bundle identifier and has Push Notifications enabled.

## Build APK

Use the guarded build script. It refuses to create an APK when the Finik key
or environment is missing, so an old/non-payment build cannot be mistaken for
the current application:

```bash
FINIK_API_KEY=your_finik_mobile_key \
FINIK_BETA=false \
./tool/build_apk.sh debug
```

Use `release` instead of `debug` only when the release keystore is configured.
Release builds create separate `armeabi-v7a`, `arm64-v8a`, and `x86_64` APKs,
with minification, resource shrinking, obfuscation and external debug symbols.
Install the APK matching the phone CPU; most current Android phones use
`arm64-v8a`. This is much smaller than a universal debug APK.
Before compiling, the script checks the live backend Finik endpoint, payment
flow version, HTTPS callback, beta mode and API-key fingerprint. It therefore
requires the updated backend to be deployed and reloaded first.

For a test phone, use `./tool/build_apk.sh debug`; do not call
`flutter build apk` directly, because that bypasses the payment preflight.

Release APK requires Android signing files:

- `android/key.properties`
- release keystore file referenced by `storeFile`
- `keyAlias`, `keyPassword`, `storePassword`

Build release through the same guarded script:

```bash
DOGO_API_BASE_URL=https://yourusername.pythonanywhere.com/api/ \
FINIK_API_KEY=your_production_finik_api_client_key \
FINIK_BETA=false \
./tool/build_apk.sh release
```

Install on Android:

```bash
flutter install
# or
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
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

## UI redesign and responsive testing

The UI is built on a single design system. Do not hardcode colors, spacing,
radii or text styles in screens — import the tokens instead:

```dart
import 'package:dogo/core/design/app_design.dart';   // AppColors, AppSpacing, AppRadius, AppTypography, …
import 'package:dogo/core/widgets/app_widgets.dart'; // AppPrimaryButton, AppTextField, AppOrderCard, …
```

| Layer | Location |
|---|---|
| Design tokens and theme | `lib/core/design/` |
| Reusable components | `lib/core/widgets/` |
| Service definitions (`delivery` / `cars` / `amanat`) | `lib/features/main_module/services/service_config.dart` |

Rules that the redesign relies on:

- spacing grid is 4 / 8 / 12 / 16 / 20 / 24 / 32 px (`AppSpacing`) — no arbitrary values;
- radii come from `AppRadius`, shadows from `AppShadows` (soft only);
- only `SFProText` is used — it is the single font family declared in `pubspec.yaml`
  with a full weight range, so max weight is `w700`;
- orange (`AppColors.primary`) is reserved for primary buttons, active elements,
  selected tabs and important markers;
- every screen wraps its body in `AppScreenScaffold`, every modal in `AppBottomSheet` —
  both handle the keyboard, safe areas and max content width;
- interactive targets are at least 44 px; status is never conveyed by color alone.

The three service sections share one order flow. To change the behaviour of a
section, edit `ServiceConfig` — do not fork the screen. `service_type` is read
from there and sent to the backend unchanged.

### Responsive testing

Widget tests run every main surface across the supported width range and text scales.
The helpers live in `test/support/test_harness.dart`:

```dart
testAcrossScreenSizes('does not overflow', (tester, size) async { … });
```

| Constant | Values |
|---|---|
| `kScreenSizes` | 320×568, 360×640, 390×844, 430×932, 600×960 |
| `kTextScales` | 1.0, 1.2, 1.4 |

```bash
flutter test test/widgets   # components
flutter test test/screens   # screens and the responsive matrix
```

`testAcrossScreenSizes` fails on any exception, which includes
`RenderFlex overflowed by N pixels`. When adding a screen, add it to
`test/screens/responsive_matrix_test.dart`.

Full check before a PR:

```bash
flutter pub get
flutter analyze   # must report: No issues found!
flutter test
dart format .
```

Design decisions, known limitations and the list of scenarios that still need a
real device are documented in [`docs/UI_REDESIGN_AUDIT.md`](docs/UI_REDESIGN_AUDIT.md)
and [`docs/UI_REDESIGN_REPORT.md`](docs/UI_REDESIGN_REPORT.md).
