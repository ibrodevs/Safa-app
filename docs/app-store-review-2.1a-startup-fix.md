# App Store Review 2.1(a) startup fix

Apple review reported that build `1.0.7 (27)` opened to a blank white screen on iPhone 17 Pro Max (iOS 27.0.1) and iPad Pro 11-inch M4 (iPadOS 27.0.1).

## What changed

`lib/main.dart` no longer awaits Yandex MapKit and Firebase before `runApp()`.

The first Flutter frame is rendered first. Startup integrations are initialized after that frame and are isolated with timeouts and error handling. This prevents a slow or failing third-party SDK from keeping iOS on the white launch screen.

Additional safeguards:

- MapKit lifecycle calls only run after MapKit successfully initializes.
- Push registration refresh only runs after Firebase successfully initializes.
- Notification and push initialization failures are logged instead of being silently swallowed.
- The MapKit API key is no longer printed to logs during startup.

## Required device test before resubmission

Test a clean install and an update install on a real iPhone. Test an iPad too if available, because the rejected build was reviewed on both form factors.

1. Delete Safa, reboot the device, install the release/TestFlight build, and launch it.
2. Confirm the Safa Flutter splash screen appears immediately instead of a blank white screen.
3. Continue through the unauthenticated flow.
4. Log in with a valid client account and open Home, Map, History, and Profile.
5. Verify Yandex MapKit renders and location permission flows work.
6. Background/foreground the app several times and confirm it remains responsive.
7. Test push notification registration and receipt.
8. Repeat by installing the new build as an update over the previous App Store/TestFlight build.
9. Run the same launch test with a slow/unstable network and with network temporarily disabled.

## Build number

The rejected App Store build is `1.0.7 (27)`, while the repository currently declares another build number in `pubspec.yaml`. Do not accidentally upload build 26 again.

If App Store Connect is still reviewing version `1.0.7`, the replacement build must use a higher build number, for example build `28`. The release engineer should confirm the exact marketing version in App Store Connect before archiving/uploading.

Example when the App Store Connect version is still `1.0.7`:

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release --build-name=1.0.7 --build-number=28
```

Alternatively set the same version/build values in Xcode before Archive.

## Recommended App Review note

After verification, mention in Review Notes that startup initialization was changed so third-party services can no longer block the first UI frame, and that the replacement build was tested on iPhone and iPad launch/update flows.
