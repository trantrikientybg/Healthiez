# Healthiez

Flutter app with physical health, home, and mental health tabs. Physical health includes saved height/weight with BMI and a daily water tracker. Home and mental health are currently placeholders.

## Run locally on Windows

Use Flutter 3.47.8 stable (Dart 3.13.7), or a compatible newer stable release.
This machine's SDK is installed at `D:\programming\flutter` and its `bin` directory is on the user PATH. Open a new terminal after installation.

From PowerShell:

```powershell
cd D:\programming\Healthiez
flutter pub get
flutter run -d chrome --dart-define-from-file=supabase.local.json
```

Chrome is installed on this machine. Browser development does not require Android Studio or Visual Studio. If an existing terminal cannot find Flutter, use `D:\programming\flutter\bin\flutter.bat` in place of `flutter`.

Copy `supabase.example.json` to `supabase.local.json` and fill in the project URL and **publishable** key. The local file is ignored by Git. Never put a management token, secret key, or service-role key in this file or client code. Publishable keys are included in the built application; database policies protect private records.

## Physical health storage

Signed-out use keeps the existing device storage. With a Supabase Auth session, measurements, BMI inputs, daily water, and steps use `physical_health_records`. The screen resets when accounts change. Login UI belongs to the team's auth feature and is not implemented here. Existing guest records stay on the device and are not automatically uploaded to an account.

The table stores the latest physical snapshot and the latest step snapshot per installation. Sensor baselines belong to one device; steps are not added together across phones. Account saves require a connection. Failed reads offer Retry; failed writes preserve the confirmed values and allow another attempt. There is no offline sync queue or historical chart data. Simultaneous edits on multiple devices use the last saved snapshot; restart the app to load another device's changes.

The migration in `supabase/migrations/` has been applied to the configured development project. Apply it to other projects with the Supabase SQL editor or your normal migration workflow. Run `supabase/tests/physical_health_records.sql` in the SQL editor to verify validation, separate device records, and account access policies. Test fixtures are rolled back.

## Check the project

```powershell
flutter doctor -v
flutter analyze
flutter test
flutter build web --dart-define-from-file=supabase.local.json
```

For Android development, install Android Studio and its Android SDK, run `flutter doctor --android-licenses`, then select a device or emulator with `flutter devices` and `flutter run -d <device-id>`.

Windows desktop support is disabled in this machine's Flutter configuration so browser development works without Windows Developer Mode. To build a native Windows app later, enable Developer Mode in Windows Settings, install Visual Studio with the Desktop development with C++ workload, and run `flutter config --enable-windows-desktop`. iOS builds require macOS and Xcode.
