<p align="center">
    <a href="https://github.com/godot-x/firebase" target="_blank" rel="noopener noreferrer">
        <img width="300" src="extras/images/logo.png" alt="Firebase - Logo">
    </a>
</p>

# Godotx Firebase

Modular Firebase integration for Godot with support for iOS and Android.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
- [Advanced Configuration](#advanced-configuration)
- [Building (For Developers)](#building-for-developers)
- [Project Structure](#project-structure)
- [Development Guide](#development-guide)
- [Troubleshooting](#troubleshooting)
- [API Reference](#api-reference)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Screenshot](#screenshot)
- [License](#license)

## Overview

This project provides native Firebase plugins for Godot, built as separate modules that can be enabled independently. Each Firebase service (Core, Analytics, Crashlytics, Messaging) is compiled as a native library for iOS (`.xcframework`) and Android (`.aar`), and bundled via a Godot EditorExportPlugin.

### Key Features

- 🔥 **Firebase Core** - Required base for all Firebase services
- 📊 **Firebase Analytics** - Event tracking and user analytics
- 🐛 **Firebase Crashlytics** - Crash reporting and diagnostics
- 💬 **Firebase Messaging** - Push notifications (FCM)

### Version Information

| Component | Version |
|-----------|---------|
| Godot | 4.5-stable |
| **iOS** | |
| Firebase iOS SDK | 12.7.0 |
| Min iOS | 13.0 |
| **Android** | |
| firebase-analytics | 23.0.0 |
| firebase-crashlytics | 20.0.3 |
| firebase-crashlytics-ndk | 20.0.3 |
| firebase-messaging | 25.0.1 |
| firebase-common | 22.0.1 |
| Kotlin | 2.3.0 |
| Min Android SDK | 24 (Android 7.0) |

## Quick Start

### 1. Installation

#### Option A: Godot Asset Library (Recommended)

1. Open **AssetLib** in Godot Editor
2. Search for "Godotx Firebase"
3. Click **Download** and **Install**
4. Or download directly from: https://godotengine.org/asset-library/asset/4475

#### Option B: Manual Installation

1. **Download the ZIP** from [Releases](https://github.com/godot-x/firebase/releases)

2. **Extract the ZIP** - it contains 3 folders:
   ```
   godotx_firebase/
   ├── addons/
   ├── ios/
   └── android/
   ```

3. **Copy all 3 folders** to your Godot project root:
   ```
   your_project/
   ├── addons/
   │   └── godotx_firebase/
   ├── ios/
   │   └── plugins/
   │       ├── firebase_core/
   │       ├── firebase_analytics/
   │       ├── firebase_crashlytics/
   │       └── firebase_messaging/
   └── android/
       ├── firebase_core/
       ├── firebase_analytics/
       ├── firebase_crashlytics/
       └── firebase_messaging/
   ```

4. **Enable the plugin** in Godot:
   - Open **Project → Project Settings → Plugins**
   - Enable "Godotx Firebase"

5. **Add Firebase config files** to your project root:
   - Download from [Firebase Console](https://console.firebase.google.com/)
   - iOS: `GoogleService-Info.plist`
   - Android: `google-services.json`

### 2. Configure Export Preset

**For Android:**
1. Configure export preset:
   - Enable **Use Gradle Build** (required)
   - **Firebase/Android Config File**: Select `google-services.json`
   - Enable **Firebase Core** (required)
   - Enable other modules you need (Analytics, Crashlytics, Messaging)

**For iOS:**
1. Configure export preset:
   - **Firebase/iOS Config File**: Select `GoogleService-Info.plist`
   - Enable **Firebase Core** (required)
   - Enable other modules you need

### 3. Configure Android Gradle (Required only for Android)

1. **Install Android Build Template:**
   - **Project → Install Android Build Template**

2. **Edit `android/build/build.gradle`:**

   > **Important:** The `buildscript` block **must be at the very beginning** of the `build.gradle` file, before any other blocks like `plugins` or `android`.

   ```gradle
   // This MUST be at the beginning of the file
   buildscript {
       dependencies {
           // Add if not present
           classpath 'com.google.gms:google-services:4.4.4'

           // Add this if using Crashlytics (required for crash reports)
           classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.6'
       }
   }

   // ... rest of the file (plugins, android, dependencies blocks) ...

   // At the end of the file
   apply plugin: 'com.google.gms.google-services'

   // Add this if using Crashlytics
   apply plugin: 'com.google.firebase.crashlytics'
   ```

### 4. Export Filters (Recommended)

Some project files may be copied to the final APK/AAB/IPA assets folder unnecessarily. To reduce app size and avoid including development files, add these patterns to **Filters to exclude files/folders from project** in your export preset:

```
ios/*,android/*,addons/godotx_firebase/*,build/*
```

This excludes:
- `ios/` - Built iOS plugins (already bundled by the export plugin)
- `android/` - Built Android plugins (already bundled by the export plugin)
- `addons/godotx_firebase/` - Export plugin scripts (not needed at runtime)
- `build/` - Build output directory

### 5. Test the Integration

Run the included test scene to verify everything works:
```
scenes/Main.tscn
```

The test scene includes buttons to test all Firebase features.

## Usage Examples

### Firebase Core

Firebase Core must be initialized first before using any other Firebase module.

```gdscript
extends Node

var firebase_core
var analytics
var crashlytics

func _ready():
    # Get all singletons
    if Engine.has_singleton("GodotxFirebaseCore"):
        firebase_core = Engine.get_singleton("GodotxFirebaseCore")
        firebase_core.core_initialized.connect(_on_core_initialized)

    if Engine.has_singleton("GodotxFirebaseAnalytics"):
        analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
        analytics.analytics_initialized.connect(_on_analytics_initialized)

    if Engine.has_singleton("GodotxFirebaseCrashlytics"):
        crashlytics = Engine.get_singleton("GodotxFirebaseCrashlytics")
        crashlytics.crashlytics_initialized.connect(_on_crashlytics_initialized)

    # Initialize Core first
    if firebase_core:
        firebase_core.initialize()

func _on_core_initialized(success: bool):
    if success:
        print("Firebase Core initialized!")

        # Now initialize dependent modules
        if crashlytics:
            crashlytics.initialize()
        if analytics:
            analytics.initialize()
    else:
        print("Firebase Core initialization failed")

func _on_crashlytics_initialized(success: bool):
    print("Crashlytics initialized: ", success)

func _on_analytics_initialized(success: bool):
    print("Analytics initialized: ", success)
```

### Firebase Analytics

```gdscript
var analytics

func _ready():
    if Engine.has_singleton("GodotxFirebaseAnalytics"):
        analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
        analytics.analytics_initialized.connect(_on_analytics_initialized)

# Call this after Firebase Core is initialized
func initialize_analytics():
    if analytics:
        analytics.initialize()

func _on_analytics_initialized(success: bool):
    if success:
        # Now you can log events
        var params = {"level": "5", "score": "1000"}
        analytics.log_event("level_complete", JSON.stringify(params))
```

### Firebase Crashlytics

```gdscript
var crashlytics

func _ready():
    if Engine.has_singleton("GodotxFirebaseCrashlytics"):
        crashlytics = Engine.get_singleton("GodotxFirebaseCrashlytics")
        crashlytics.crashlytics_initialized.connect(_on_crashlytics_initialized)

# Call this after Firebase Core is initialized
func initialize_crashlytics():
    if crashlytics:
        crashlytics.initialize()

func _on_crashlytics_initialized(success: bool):
    if success:
        # Now you can use Crashlytics
        crashlytics.set_user_id("user_123")
        crashlytics.log_message("Player entered level 5")
```

### Firebase Messaging

```gdscript
var messaging = Engine.get_singleton("GodotxFirebaseMessaging")

# Connect to signals
messaging.messaging_permission_granted.connect(_on_permission_granted)
messaging.messaging_permission_denied.connect(_on_permission_denied)
messaging.messaging_token_received.connect(_on_token_received)
messaging.messaging_apn_token_received.connect(_on_apn_token_received)  # iOS only
messaging.messaging_message_received.connect(_on_message_received)
messaging.messaging_error.connect(_on_error)

# Request notification permission (this also registers for APNs on iOS)
messaging.request_permission()

# Get FCM token
messaging.get_token()

# Get APNs token (iOS only - call after request_permission)
if OS.get_name() == "iOS":
    messaging.get_apns_token()

func _on_permission_granted():
    print("Permission granted!")
    # Safe to call get_token() here

func _on_permission_denied():
    print("Permission denied by user")
    # User denied or disabled notifications in system settings
    # You can prompt user to enable in settings or continue without notifications

func _on_token_received(token: String):
    print("FCM Token: ", token)

func _on_apn_token_received(token: String):
    # iOS only - Apple Push Notification device token
    print("APN Token: ", token)

func _on_message_received(title: String, body: String):
    print("Message: ", title, " - ", body)

func _on_error(message: String):
    print("Error: ", message)
```

**Available Methods:**
- `request_permission()` - Request notification permission from user
- `get_token()` - Get FCM registration token
- `get_apns_token()` - Get APNs device token (iOS only, requires permission first)
- `subscribe_to_topic(topic: String)` - Subscribe to a topic
- `unsubscribe_from_topic(topic: String)` - Unsubscribe from a topic

**Available Signals:**
- `messaging_permission_granted()` - Notification permission granted by user
- `messaging_permission_denied()` - Notification permission denied by user or in system settings
- `messaging_token_received(token: String)` - FCM registration token received
- `messaging_apn_token_received(token: String)` - iOS APN device token received (iOS only)
- `messaging_message_received(title: String, body: String)` - Push notification received
- `messaging_error(message: String)` - Error occurred (network failures, API errors, etc)

**Important Notes:**

- **Permission Checking Pattern:** It is safe and recommended to call `request_permission()` every time your app opens. The method performs an internal check and will:
  - Return immediately with `messaging_permission_granted` if already authorized (no user prompt)
  - Return `messaging_permission_denied` if previously denied (no user prompt)
  - Show the system permission dialog only if the user hasn't been asked before

- **Permission vs Errors:** The `messaging_permission_denied` signal is the normal response when users decline notifications or have them disabled in settings. This is **not an error** - it's just feedback about permission status. The `messaging_error` signal is reserved for actual failures like network issues or API problems.

- **Token Retrieval:** Do not use `get_token()` to infer permission status. Always check permission first with `request_permission()` and wait for the appropriate signal (`messaging_permission_granted` or `messaging_permission_denied`).

- **iOS APNs:** On iOS, Firebase Messaging uses method swizzling to automatically handle APNs registration. The APNs token is captured by Firebase internally and can be accessed via the `get_apns_token()` method after calling `request_permission()`.

## Advanced Configuration

### Android R8/ProGuard Minification

By default, R8 minification is **disabled** in release builds. If you want to enable it for smaller APK/AAB sizes, follow these steps:

1. **Edit `android/build/build.gradle`** and enable minification in the release build type:

   ```gradle
   android {
       buildTypes {
           release {
               minifyEnabled true
               shrinkResources true
               proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
           }
       }
   }
   ```

2. **Create `android/build/proguard-rules.pro`** with the following content:

   ```proguard
   ####################################
   # Godot JNI
   ####################################
   -keep class org.godotengine.godot.** { *; }
   -dontwarn org.godotengine.godot.**
   ```

**Important Notes:**
- Firebase ProGuard rules are already included in each module (via `consumerProguardFiles`)
- Only add custom rules if you encounter issues with other libraries
- Test thoroughly after enabling minification to ensure everything works correctly

### Android Notification Icon

To customize the notification icon for Firebase Cloud Messaging, see:

📄 **[Android Notification Icon Customization Guide](docs/android-notification-icon.md)**

### iOS Push Notifications Setup

Firebase Messaging on iOS requires Push Notifications capability to be enabled. The plugin automatically configures this when you enable Firebase Messaging in the export preset.

### iOS Framework Dependencies

All Firebase frameworks are automatically bundled by the export plugin. The plugin uses the `.gdip` files to declare dependencies and ensures all required `.xcframework` files are included in the export.

## Building (For Developers)

### Requirements

- macOS with Xcode 14+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [CocoaPods](https://cocoapods.org): `sudo gem install cocoapods`
- Android SDK & Gradle
- Godot source (auto-downloaded by make)

### Build Commands

```bash
# Initial setup (run once)
make setup-godot         # Clone Godot source code
make build-godot-headers # Generate Godot headers
make setup-sdk           # Download Firebase iOS SDK
make unsign-sdk          # Remove code signatures (prevents build errors)
make setup-apple         # Generate Xcode projects + install CocoaPods

# Build everything
make build-all           # Build iOS + Android (both Debug & Release)

# Or build platforms separately
make build-apple         # Build iOS .xcframework files
make build-android       # Build Android .aar files

# Package for distribution
make package             # Create ZIP file

# Maintenance commands
make clean               # Clean all build artifacts
make clean-sdk           # Remove Firebase SDK (re-run setup-sdk after)
make clean-godot         # Remove Godot source (re-run setup-godot after)

# Show all available commands
make help
```

### Build Output Structure

After running `make build-all`, you'll get:

**iOS Plugins** (`ios/plugins/`):
```
ios/plugins/
├── firebase_core/
│   ├── GodotxFirebaseCore.debug.xcframework       # Your plugin (Debug)
│   ├── GodotxFirebaseCore.release.xcframework     # Your plugin (Release)
│   ├── FirebaseCore.xcframework                   # Firebase SDK
│   ├── FirebaseAnalytics.xcframework
│   ├── FBLPromises.xcframework
│   ├── GoogleUtilities.xcframework
│   ├── nanopb.xcframework
│   └── firebase_core.gdip                         # Plugin descriptor
├── firebase_analytics/
├── firebase_crashlytics/
└── firebase_messaging/
```

**Android Plugins** (`android/`):
```
android/
├── firebase_core/
│   ├── firebase_core.debug.aar                    # Debug variant
│   └── firebase_core.release.aar                  # Release variant
├── firebase_analytics/
├── firebase_crashlytics/
└── firebase_messaging/
```

Each `.aar` file contains:
- Compiled Kotlin code
- Firebase SDK dependencies (via Gradle)
- Android manifest with plugin metadata

## Project Structure

```
firebase/
├── addons/
│   └── godotx_firebase/           # ✨ Godot plugin (copy to your project)
│       ├── export_plugin.gd       # Export configuration & module bundling
│       └── plugin.cfg
│
├── source/                        # 🛠️ Source code for all plugins
│   ├── ios/
│   │   ├── firebase_sdk/          # Firebase iOS SDK (downloaded)
│   │   ├── firebase_core/
│   │   │   ├── Sources/           # C++/Objective-C++ code
│   │   │   ├── project.yml        # XcodeGen configuration
│   │   │   ├── Podfile            # CocoaPods dependencies
│   │   │   └── *.gdip             # Godot plugin definition
│   │   ├── firebase_analytics/
│   │   ├── firebase_crashlytics/
│   │   └── firebase_messaging/
│   │
│   └── android/
│       ├── firebase_core/
│       │   ├── src/main/java/     # Kotlin source code
│       │   ├── build.gradle.kts   # Gradle build configuration
│       │   └── gradlew            # Gradle wrapper
│       ├── firebase_analytics/
│       ├── firebase_crashlytics/
│       └── firebase_messaging/
│
├── ios/
│   └── plugins/                   # 📦 Built iOS plugins
│       ├── firebase_core/
│       │   ├── GodotxFirebaseCore.{debug|release}.xcframework
│       │   ├── FirebaseCore.xcframework
│       │   ├── firebase_core.gdip
│       │   └── ... (Firebase dependencies)
│       ├── firebase_analytics/
│       ├── firebase_crashlytics/
│       └── firebase_messaging/
│
├── android/                       # 📦 Built Android plugins
│   ├── firebase_core/
│   │   ├── firebase_core.debug.aar
│   │   └── firebase_core.release.aar
│   ├── firebase_analytics/
│   ├── firebase_crashlytics/
│   └── firebase_messaging/
│
├── godot/                         # Godot engine source (cloned by make)
├── godot-cpp/                     # Godot C++ bindings (if needed)
└── scenes/Main.tscn               # 🧪 Test scene with UI buttons
```

## Development Guide

### How It Works

1. **Source Code** (`source/`): Platform-specific implementations
   - **iOS**: Objective-C++ wrappers around Firebase C++ SDK
   - **Android**: Kotlin wrappers using Firebase Android SDK

2. **Build Process**:
   - **iOS**: XcodeGen generates Xcode projects → builds static libraries → creates XCFrameworks
   - **Android**: Gradle builds AAR files with embedded Firebase dependencies

3. **Plugin Integration** (`addons/godotx_firebase/`):
   - `export_plugin.gd` detects enabled modules in export presets
   - Automatically bundles `.xcframework` (iOS) or `.aar` (Android) files
   - Copies Firebase configuration files to builds

### Adding a New Firebase Module

1. Create source directories:
   ```bash
   mkdir -p source/ios/firebase_newmodule/Sources
   mkdir -p source/android/firebase_newmodule/src/main/java
   ```

2. Implement platform code:
   - iOS: Create `.h`/`.mm` files + `project.yml` + `Podfile` + `.gdip`
   - Android: Create Kotlin plugin + `build.gradle.kts` + `AndroidManifest.xml`

3. Update `Makefile`:
   - Add module to `APPLE_MODULES` and `ANDROID_MODULES`
   - Add corresponding module name to `APPLE_MODULE_NAMES`

4. Update `export_plugin.gd`:
   - Add checkbox for new module in `_get_export_options()`
   - Add bundling logic in platform-specific sections

5. Build and test:
   ```bash
   make clean
   make build-all
   ```

## Troubleshooting

### Build Issues

**"Firebase SDK not found" during iOS build**
```bash
make setup-firebase
make unsign-firebase
```

**Xcode code signing errors**
```bash
# Remove signatures
make unsign-firebase
```

**Gradle build fails with version conflicts**
- Check `build.gradle.kts` versions match Firebase BOM
- Clean Android build: `cd source/android/firebase_* && ./gradlew clean`

### Runtime Issues

**Android: Plugin not found**
- Verify `AndroidManifest.xml` uses `org.godotengine.plugin.v2.` prefix
- Check methods have `@UsedByGodot` annotation
- Enable **Use Gradle Build** in Android export preset
- Rebuild: `make build-android`

**iOS: Frameworks not found**
- Clean and rebuild: `make clean && make build-apple`
- Check `ios/plugins/firebase_*/` contains `.xcframework` files
- Verify export preset has Firebase modules enabled

**Firebase not initializing**
- Ensure **Firebase Core** is enabled first (required for all modules)
- Check config files are selected in export settings:
  - iOS: `GoogleService-Info.plist`
  - Android: `google-services.json`
- Verify config files exist in project root
- Check console for initialization errors

**Kotlin version errors (Android)**
- Project uses Kotlin version that matches Firebase SDK
- Update `build.gradle.kts` if using different Godot version

## API Reference

All plugins follow the same pattern:

```gdscript
# Get singleton
var plugin = Engine.get_singleton("GodotxFirebase<Component>")

# Connect signals
plugin.signal_name.connect(callback)

# Call methods
plugin.method_name(parameters)
```

### Available Singletons

- `GodotxFirebaseCore` - Firebase initialization and configuration
- `GodotxFirebaseAnalytics` - Event tracking and user properties
- `GodotxFirebaseCrashlytics` - Crash reporting and custom logs
- `GodotxFirebaseMessaging` - Push notifications and FCM tokens

## FAQ

**Q: Do I need to build the plugins myself?**
A: No, if you just want to use the plugins. The pre-built `.xcframework` and `.aar` files are included in the repository. Building is only needed if you want to modify the source code or add new features.

**Q: Can I use only some Firebase modules?**
A: Yes! Each module can be enabled/disabled independently in the export preset. However, **Firebase Core is always required** as it provides the base functionality.

**Q: Will this increase my app size?**
A: Yes, Firebase adds approximately:
- **iOS**: 15-20 MB per module (compressed)
- **Android**: 5-10 MB per module (compressed)

Only enabled modules are included in the final build.

**Q: Does this work with Godot 4.4 or earlier?**
A: This project is built for Godot 4.5 or later.

**Q: How do I get Firebase config files?**
A:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a project (or select existing)
3. Add iOS/Android app
4. Download `GoogleService-Info.plist` (iOS) or `google-services.json` (Android)

**Q: Why do I need to unsign Firebase frameworks?**
A: Firebase's pre-signed frameworks can cause code signing conflicts during Xcode builds. Running `make unsign-firebase` removes these signatures, allowing Xcode to sign everything together.

## Contributing

Contributions are welcome! Here's how you can help:

1. **Report bugs**: Open an issue with reproduction steps
2. **Request features**: Suggest new Firebase modules or improvements
3. **Submit PRs**:
   - Follow existing code style
   - Test on both iOS and Android
   - Update documentation as needed

### Project Conventions

- **iOS**: Objective-C++ for Godot integration
- **Android**: Kotlin for plugin implementation
- **Naming**: `GodotxFirebase{Module}` for singleton names
- **Signals**: Use snake_case (e.g., `token_received`, `initialized`)
- **Methods**: Use snake_case following GDScript conventions

## Screenshot

<img width="300" src="extras/images/screenshot.png" alt="Screenshot">

## License

MIT License - See [LICENSE](LICENSE)

## Support

- **Issues**: [GitHub Issues](https://github.com/paulocoutinhox/godot-firebase/issues)
- **Discussions**: [GitHub Discussions](https://github.com/paulocoutinhox/godot-firebase/discussions)

Made with ❤️ by [Paulo Coutinho](https://github.com/paulocoutinhox)
