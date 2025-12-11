
# MailMind (Mail Organizer)

MailMind (renamed to "Mail Organizer" in the Android build) is a Flutter-based email assistant prototype that syncs Gmail messages, detects deadlines and reminders in email text, classifies priorities with a TFLite model, and stores metadata locally with Hive.

**What we changed / implemented**
- **App label**: Set Android application label to "Mail Organizer" (`android/app/src/main/AndroidManifest.xml`).
- **Launcher icon**: Replaced default launcher icons with `icon.jpg` (generated resized icons using `flutter_launcher_icons` and also copied raw `icon.jpg` into `res/mipmap-*/ic_launcher.png`).
- **Spam fixes**: Fixed Gmail API fetch to include `labelIds` so spam-labelled messages are preserved and shown in the Spam screen.
- **Deadline detection**: Improved `DeadlineDetectorDart` to detect dates even when explicit "deadline" keywords are missing (lenient mode) and added additional logging for debugging.
- **Local storage**: Ensured `EmailLocalStorage` (Hive) initializes before use and that detected deadline metadata is saved and loaded into UI state.
- **Build**: Built and installed debug and release APKs; release APK installed to connected device.

**Tech stack**
- **Framework**: Flutter (Dart)
- **Local storage**: Hive / hive_flutter
- **Networking**: Gmail REST API via `http` package
- **ML**: TensorFlow Lite model for priority classification (`assets/models/priority_classifier.tflite`)
- **Icon generation**: `flutter_launcher_icons`
- **Platform**: Android (primary testing), iOS support scaffolded

**Important files**
- `lib/shell/mail_shell.dart` — app shell and sync logic
- `lib/core/email_repository.dart` — coordination between API, storage, and detectors
- `lib/core/gmail_api_service.dart` — Gmail API client
- `lib/core/deadline_detector.dart` — deadline detection and date parsing logic
- `lib/core/deadline_store.dart` — deadline metadata persistence
- `pubspec.yaml` — dependencies (includes `flutter_launcher_icons` entry)

## Run the project (development)
Prerequisites:
- Flutter SDK installed and on PATH
- Android SDK + Platform tools (`adb`) available
- An Android device connected or emulator running
- (Optional) Google OAuth credentials configured for Gmail API access if you use real accounts

1. Open a terminal in the project root:

```powershell
cd 'C:\Users\ASUS\Desktop\Hackathon\mail_mind'
```

2. Get packages:

```powershell
flutter pub get
```

3. (Optional) Regenerate launcher icons from `icon.jpg`:

```powershell
flutter pub run flutter_launcher_icons:main
```

4. Run the app on a connected device (debug):

```powershell
flutter run -d <device-id>
# or
flutter run
```

5. Build APKs:

```powershell
# Debug APK
flutter build apk --debug
# Release APK
flutter build apk --release
```

6. Install release APK to the device (example):

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

## Notes & troubleshooting
- The deadline detector uses both keyword matching and date extraction. Some emails contain dates but not explicit keywords — a lenient mode was added to surface likely deadlines (future dates within 90 days).
- Gmail API responses must include `labelIds` to detect SPAM — ensure requests include `labelIds` in `fields` or use `format=full`.
- Hive boxes must be initialized before reading/writing. The app ensures `EmailLocalStorage.init()` runs during startup.
- If icons look blurry or incorrect, regenerate properly sized PNGs with `flutter_launcher_icons` or provide a high-resolution PNG and re-run the generator.
- A previous attempt to change APK filename used a Gradle snippet incompatible with Kotlin DSL and was removed; default APK filenames are used now. You can rename build outputs in CI or via a separate packaging script.

## How to contribute / extend
- Add more robust NLP for deadline detection (SpaCy / server-side models) or integrate ML-based NER for date extraction.
- Improve reminder scheduling and local notifications (use `flutter_local_notifications`).
- Add IMAP fallback for non-Gmail accounts.

If you want, I can also:
- Re-run `flutter build apk` and upload the produced APK to a specific path.
- Add CI steps to automatically build and create named artifacts.

---

If anything here is unclear or you want the README to include screenshots or sample logs, tell me which items to add and I'll update it.

