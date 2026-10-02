## Setup

1. Open your Flutter project in a code editor.
2. Add the SDK to `pubspec.yaml`:
   ```yaml
   dependencies:
     pushengage_flutter_sdk: ^1.1.0
   ```
3. Run:
   ```bash
   flutter pub get
   ```
4. **Android only** — the PushEngage Android SDK is distributed via
   [JitPack](https://jitpack.io), so add JitPack to your app's repositories
   (the `allprojects` block in `android/build.gradle(.kts)`, or
   `dependencyResolutionManagement` in `settings.gradle(.kts)` if your project
   declares repositories there). See the README's "Android: add the JitPack
   repository" section for Kotlin and Groovy snippets:
   ```groovy
   maven { url 'https://jitpack.io' }
   ```

## Demo project

We have added a demo project for showcasing the various features available and ways to interact with the SDK. The project can be found inside the `example/` folder.

Steps to run the sample project:
1. Clone this repo.
2. From the repo root, run:
   ```bash
   cd example
   flutter pub get
   flutter run
   ```
   `flutter run` installs the iOS pods automatically, so no separate `pod install` is needed.
3. To pick a specific simulator, emulator or device, list them with `flutter devices` and run
   `flutter run -d <device-id>`.
