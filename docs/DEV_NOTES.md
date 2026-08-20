# O7Lite development notes

## Generate g.dart

Generated `*.g.dart` files are intentionally excluded from version control. Generate them after installing dependencies:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

For iOS development, also run `pod install` inside `ios/`.

---

## Build Flavors

The app supports eight build flavors with independent versioning:

| Flavor | Device | Entry Point |
|--------|--------|-------------|
| sunmi | Sunmi POS | `lib/main_sunmi.dart` |
| landi | Landi POS | `lib/main_landi.dart` |
| castle | Castle POS | `lib/main_castle.dart` |
| anfu | Anfu POS | `lib/main_anfu.dart` |
| wizarpos | WizarPOS Q2 | `lib/main_wizarpos.dart` |
| coherent | Coherent/Centerm POS | `lib/main_coherent.dart` |
| morefun | MoreFun POS | `lib/main_morefun.dart` |
| mobile | Standard mobile devices | `lib/main_mobile.dart` |

### Important Notes
- WizarPOS Terminal: `minSdkVersion 23`
- Sunmi, Landi, Castle, Anfu, and MoreFun terminals: `minSdkVersion 24`
- Coherent terminals use Flutter's configured minimum SDK version.
- Mobile devices: `minSdkVersion 29`
- All flavors use the same `applicationId`: `com.oxpay.o7lite`
- ABI filters: `armeabi-v7a`, `arm64-v8a` only (no x86 simulator - reduces APK size)

---

## Build APK (Release)

### Using Flutter CLI
```bash
# Build APK for specific flavor
flutter build apk --flavor sunmi --release --obfuscate --split-debug-info=build/debug-info/sunmi
flutter build apk --flavor landi --release --obfuscate --split-debug-info=build/debug-info/landi
flutter build apk --flavor castle --release --obfuscate --split-debug-info=build/debug-info/castle
flutter build apk --flavor anfu --release --obfuscate --split-debug-info=build/debug-info/anfu
flutter build apk --flavor wizarpos --release --obfuscate --split-debug-info=build/debug-info/wizarpos
flutter build apk --flavor coherent --release --obfuscate --split-debug-info=build/debug-info/coherent
flutter build apk --flavor morefun --release --obfuscate --split-debug-info=build/debug-info/morefun
flutter build apk --flavor mobile --release --obfuscate --split-debug-info=build/debug-info/mobile
```

### APK Output Location
```
build/app/outputs/flutter-apk/oxpaylite-x-{flavor}-{version}-release-{date}.apk
```

Example: `oxpaylite-x-sunmi-1.0.0-release-04-02-2026.apk`

---

## Build AAB (Android App Bundle) for Play Store

### Mobile AAB for Play Store
```bash
flutter build appbundle --flavor mobile --release --obfuscate --split-debug-info=build/debug-info/mobile
```

### AAB Output Location
```
build/app/outputs/bundle/mobileRelease/app-mobile-release.aab
```

---

## Update Version for Each Flavor

Edit `android/app/build.gradle.kts` and update `versionCode` and `versionName` for the specific flavor:

```kotlin
productFlavors {
    create("sunmi") {
        versionCode = 52        // Update this
        versionName = "3.0.45"  // Update this
        // ...
    }
    
    create("landi") {
        versionCode = 10        // Independent version
        versionName = "2.1.0"   // Independent version
        // ...
    }
    // ... other flavors
}
```

---

## IDE Launch Configuration (VS Code)

Copy this JSON into `.vscode/launch.json` for common launch configurations:

> **Note**: iOS Simulator config has NO `--flavor` arg (Xcode doesn't define custom schemes). Android configs require `--flavor`.

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "iOS Simulator (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_mobile.dart"
        },
        {
            "name": "Mobile Android (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_mobile.dart",
            "args": ["--flavor", "mobile"]
        },
        {
            "name": "Mobile Android (Profile)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_mobile.dart",
            "flutterMode": "profile",
            "args": ["--flavor", "mobile"]
        },
        {
            "name": "Mobile Android (Release)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_mobile.dart",
            "flutterMode": "release",
            "args": ["--flavor", "mobile"]
        },
        {
            "name": "Sunmi POS (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_sunmi.dart",
            "args": ["--flavor", "sunmi"]
        },
        {
            "name": "Castle POS (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_castle.dart",
            "args": ["--flavor", "castle"]
        },
        {
            "name": "Landi POS (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_landi.dart",
            "args": ["--flavor", "landi"]
        },
        {
            "name": "Anfu POS (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_anfu.dart",
            "args": ["--flavor", "anfu"]
        },
        {
            "name": "WizarPOS (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_wizarpos.dart",
            "args": ["--flavor", "wizarpos"]
        }
    ]
}
```

---

## Debug Build

```bash
# Debug APK (no obfuscation, faster build)
flutter build apk --flavor sunmi --debug
flutter build apk --flavor mobile --debug

# Run on device
flutter run --flavor sunmi
flutter run --flavor mobile
```

---

## Gradle Commands

```bash
cd android

# List all build tasks
./gradlew app:tasks --group=build

# Assemble specific flavor
./gradlew assembleSunmiRelease
./gradlew assembleLandiRelease
./gradlew assembleCastleRelease
./gradlew assembleAnfuRelease
./gradlew assembleWizarposRelease
./gradlew assembleCoherentRelease
./gradlew assembleMorefunRelease
./gradlew assembleMobileRelease

# Bundle for Play Store
./gradlew bundleMobileRelease
```

---

## Keystore Configuration

Signing credentials are stored in `android/local.properties` (not committed to git).

### Setup local.properties

Add these lines to `android/local.properties`:

```properties
# Default release keystore (used for all flavors except wizarpos)
RELEASE_STORE_FILE=/path/to/your/keystore/o7lite-keystore
RELEASE_STORE_PASSWORD=your_password_here
RELEASE_KEY_ALIAS=your_release_alias_here
RELEASE_KEY_PASSWORD=your_key_password_here

# WizarPOS keystore (separate signing for wizarpos flavor)
WIZARPOS_STORE_FILE=/path/to/your/keystore/keystore-oxpaylite-wizarpos
WIZARPOS_STORE_PASSWORD=your_wizarpos_password_here
WIZARPOS_KEY_ALIAS=your_wizarpos_alias_here
WIZARPOS_KEY_PASSWORD=your_wizarpos_key_password_here
```

Keystores should be stored outside the project directory for security.
