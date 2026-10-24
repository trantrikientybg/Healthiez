# Healthiez

Flutter app with physical health, home, and mental health tabs. Physical health includes saved height/weight with BMI and a daily water tracker. Home and mental health are currently placeholders.

## Run locally on Windows

Use Flutter 3.47.8 stable (Dart 3.13.7), or a compatible newer stable release.
This machine's SDK is installed at `D:\programming\flutter` and its `bin` directory is on the user PATH. Open a new terminal after installation.

From PowerShell:

```powershell
cd D:\programming\Healthiez
flutter pub get
flutter run -d chrome
```

Chrome is installed on this machine. Browser development does not require Android Studio or Visual Studio. If an existing terminal cannot find Flutter, use `D:\programming\flutter\bin\flutter.bat` in place of `flutter`.

The app initializes the Supabase project configured in `lib/main.dart`; no `.env` file is required. Backend features depend on that project's availability and permissions. Never add a Supabase secret or service-role key to client code.

## Check the project

```powershell
flutter doctor -v
flutter analyze
flutter test
flutter build web
```

For Android development, install Android Studio and its Android SDK, run `flutter doctor --android-licenses`, then select a device or emulator with `flutter devices` and `flutter run -d <device-id>`.

Windows desktop support is disabled in this machine's Flutter configuration so browser development works without Windows Developer Mode. To build a native Windows app later, enable Developer Mode in Windows Settings, install Visual Studio with the Desktop development with C++ workload, and run `flutter config --enable-windows-desktop`. iOS builds require macOS and Xcode.
