.PHONY: help clean clean-sdk clean-godot setup-godot build-godot-headers setup-sdk unsign-sdk setup-apple build-apple build-android build-all package

# ============================================================================
# Directory Configuration (based on ROOT_DIR)
# ============================================================================
ROOT_DIR := $(shell pwd)

# Source directories
GODOT_DIR = $(ROOT_DIR)/godot
SOURCE_DIR = $(ROOT_DIR)/source
IOS_SOURCE_DIR = $(SOURCE_DIR)/ios
ANDROID_SOURCE_DIR = $(SOURCE_DIR)/android
ADDONS_DIR = $(ROOT_DIR)/addons/godotx_firebase

# Output directories
IOS_PLUGINS_DIR = $(ROOT_DIR)/ios/plugins
ANDROID_OUTPUT_DIR = $(ROOT_DIR)/android

# Binary directories
FIREBASE_SDK_DIR = $(ROOT_DIR)/source/ios/firebase_sdk

# Temporary directories
TMP_DIR = /tmp

# ============================================================================
# Module Configuration
# ============================================================================
APPLE_MODULES = firebase_core firebase_analytics firebase_crashlytics firebase_messaging
APPLE_MODULE_NAMES = Core Analytics Crashlytics Messaging

ANDROID_MODULES = firebase_core firebase_analytics firebase_crashlytics firebase_messaging

# ============================================================================
# Build Configuration
# ============================================================================
BUILD_CONFIGS = Debug Release
APPLE_SDK_ARCHS = iphoneos/arm64 iphonesimulator/arm64 iphonesimulator/x86_64

# ============================================================================
# Version Configuration
# ============================================================================
GODOT_VERSION = 4.5-stable
GODOT_REPO = https://github.com/godotengine/godot.git
FIREBASE_VERSION = 12.6.0

# ============================================================================
# Help
# ============================================================================

help:
	@echo "Godotx Firebase Build System"
	@echo "============================="
	@echo ""
	@echo "Available targets:"
	@echo "  setup-godot         - Clone Godot source (required for compilation)"
	@echo "  build-godot-headers - Generate Godot headers (required for iOS plugin compilation)"
	@echo "  setup-sdk           - Download Firebase SDK"
	@echo "  unsign-sdk          - Remove signatures from Firebase SDK frameworks"
	@echo "  setup-apple         - Install Apple dependencies (CocoaPods + XcodeGen)"
	@echo "  build-apple         - Build all Apple modules (iOS)"
	@echo "  build-android       - Build all Android modules"
	@echo "  build-all           - Build everything (Apple + Android)"
	@echo "  package             - Create distribution package (godotx_firebase.zip)"
	@echo "  clean               - Clean build artifacts"
	@echo "  clean-sdk           - Remove Firebase SDK"
	@echo "  clean-godot         - Remove Godot source"

# ============================================================================
# Godot Setup Target
# ============================================================================

setup-godot:
	@echo "====================================================================="
	@echo "Setting up Godot source code..."
	@echo "====================================================================="
	@echo ""
	@if [ -d "$(GODOT_DIR)" ]; then \
		echo "→ Godot directory already exists"; \
		cd $(GODOT_DIR) && \
		echo "  • Fetching latest changes..." && \
		git fetch origin && \
		echo "  • Checking out $(GODOT_VERSION)..." && \
		git checkout $(GODOT_VERSION) && \
		git pull origin $(GODOT_VERSION) && \
		cd ..; \
		echo "  ✓ Godot updated to $(GODOT_VERSION)"; \
	else \
		echo "→ Cloning Godot repository..."; \
		git clone --depth 1 --branch $(GODOT_VERSION) $(GODOT_REPO) $(GODOT_DIR) && \
		echo "  ✓ Godot $(GODOT_VERSION) cloned successfully"; \
	fi
	@echo ""
	@echo "====================================================================="
	@echo "✓ Godot source ready!"
	@echo "====================================================================="

build-godot-headers: setup-godot
	@echo "====================================================================="
	@echo "Building Godot headers..."
	@echo "====================================================================="
	@echo ""
	@echo "→ Generating iOS headers with scons..."
	@cd $(GODOT_DIR) && scons platform=ios target=template_release
	@echo ""
	@echo "====================================================================="
	@echo "✓ Godot headers generated!"
	@echo "====================================================================="

setup-sdk:
	@echo "====================================================================="
	@echo "Setting up Firebase SDK..."
	@echo "====================================================================="
	@echo ""
	@if [ ! -d "$(FIREBASE_SDK_DIR)" ]; then \
		echo "→ Downloading Firebase $(FIREBASE_VERSION)..."; \
		rm -rf $(TMP_DIR)/Firebase.zip $(TMP_DIR)/firebase_temp; \
		curl -L -o $(TMP_DIR)/Firebase.zip https://github.com/firebase/firebase-ios-sdk/releases/download/$(FIREBASE_VERSION)/Firebase.zip; \
		echo "→ Extracting Firebase SDK..."; \
		unzip -q $(TMP_DIR)/Firebase.zip -d $(TMP_DIR)/firebase_temp; \
		echo "→ Moving to ios/firebase_sdk..."; \
		mkdir -p $(FIREBASE_SDK_DIR); \
		mv $(TMP_DIR)/firebase_temp/Firebase/* $(FIREBASE_SDK_DIR)/; \
		touch $(FIREBASE_SDK_DIR)/.gdignore; \
		rm -rf $(TMP_DIR)/Firebase.zip $(TMP_DIR)/firebase_temp; \
		echo "  ✓ Firebase SDK installed"; \
	else \
		echo "  ✓ Firebase SDK already present"; \
	fi
	@echo ""
	@echo "====================================================================="
	@echo "✓ Firebase SDK ready!"
	@echo "====================================================================="

unsign-sdk:
	@echo "====================================================================="
	@echo "Removing signatures from Firebase SDK frameworks..."
	@echo "====================================================================="
	@echo ""
	# remove pastas de assinatura dos bundles
	@find $(FIREBASE_SDK_DIR) -name "_CodeSignature" -type d -exec rm -rf {} +
	@echo "  ✓ All _CodeSignature folders removed"
	@echo ""
	@echo "====================================================================="
	@echo "✓ Firebase frameworks are now UNSIGNED (build-safe)"
	@echo "====================================================================="

# ============================================================================
# Apple (iOS) Build Targets
# ============================================================================

setup-apple: setup-godot
	@echo "====================================================================="
	@echo "Setting up Apple (iOS) dependencies..."
	@echo "====================================================================="
	@echo ""
	@set -- $(APPLE_MODULE_NAMES); \
	for module in $(APPLE_MODULES); do \
		MODULE_NAME=$$1; \
		shift; \
		echo "→ Setting up $$module (GodotxFirebase$$MODULE_NAME)..."; \
		(cd $(IOS_SOURCE_DIR)/$$module && \
		echo "  • Creating build directory..." && \
		rm -rf build && mkdir -p build && \
		touch build/.gdignore && \
		echo "  • Generating Xcode project..." && \
		xcodegen generate -s project.yml -p build/ && \
		echo "  • Installing CocoaPods..." && \
		cp Podfile build/ && \
		pod install --repo-update --project-directory=build); \
		echo "  ✓ $$module setup complete"; \
		echo ""; \
	done
	@echo "====================================================================="
	@echo "✓ All Apple modules setup complete!"
	@echo "====================================================================="

build-apple: setup-apple
	@echo "====================================================================="
	@echo "Building all Apple (iOS) modules..."
	@echo "====================================================================="
	@echo ""
	@set -- $(APPLE_MODULE_NAMES); \
	for module in $(APPLE_MODULES); do \
		MODULE_NAME=$$1; \
		shift; \
		echo "→ Building $$module (GodotxFirebase$$MODULE_NAME)..." && \
		(cd $(IOS_SOURCE_DIR)/$$module && \
		\
		rm -rf $(IOS_PLUGINS_DIR)/$$module && \
		mkdir -p $(IOS_PLUGINS_DIR)/$$module && \
		\
		for config in $(BUILD_CONFIGS); do \
			config_lower=$$(echo $$config | tr '[:upper:]' '[:lower:]'); \
			echo "  • Building $$config configuration..."; \
			\
			echo "    - Cleaning $$config..." && \
			xcodebuild clean -workspace build/GodotxFirebase$$MODULE_NAME.xcworkspace \
				-scheme GodotxFirebase$$MODULE_NAME \
				-configuration $$config && \
			\
			for sdk_arch in $(APPLE_SDK_ARCHS); do \
				sdk=$$(echo $$sdk_arch | cut -d/ -f1); \
				arch=$$(echo $$sdk_arch | cut -d/ -f2); \
				build_dir="bin/$$config_lower-$$sdk-$$arch"; \
				echo "    - Building $$config for $$sdk ($$arch)..." && \
				xcodebuild \
					-workspace build/GodotxFirebase$$MODULE_NAME.xcworkspace \
					-scheme GodotxFirebase$$MODULE_NAME \
					-sdk $$sdk \
					-arch $$arch \
					-configuration $$config \
					CONFIGURATION_BUILD_DIR=$$build_dir \
					SKIP_INSTALL=NO \
					BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
					CODE_SIGNING_ALLOWED=NO \
					CODE_SIGNING_REQUIRED=NO || exit 1; \
			done && \
			\
			echo "    - Creating universal simulator library..." && \
			mkdir -p build/bin/$$config_lower-simulator && \
			lipo -create \
				build/bin/$$config_lower-iphonesimulator-arm64/libGodotxFirebase$$MODULE_NAME.a \
				build/bin/$$config_lower-iphonesimulator-x86_64/libGodotxFirebase$$MODULE_NAME.a \
				-output build/bin/$$config_lower-simulator/libGodotxFirebase$$MODULE_NAME.a && \
			\
			cp -r build/bin/$$config_lower-iphonesimulator-arm64/include build/bin/$$config_lower-simulator && \
			echo "    - Creating $$config XCFramework..." && \
			xcodebuild -create-xcframework \
				-library build/bin/$$config_lower-iphoneos-arm64/libGodotxFirebase$$MODULE_NAME.a \
				-headers build/bin/$$config_lower-iphoneos-arm64/include \
				-library build/bin/$$config_lower-simulator/libGodotxFirebase$$MODULE_NAME.a \
				-headers build/bin/$$config_lower-simulator/include \
				-output $(IOS_PLUGINS_DIR)/$$module/GodotxFirebase$$MODULE_NAME.$$config_lower.xcframework && \
			echo "    ✓ $$config build complete"; \
		done && \
		echo "    - Cleaning temporary build artifacts..." && \
		rm -rf bin && \
		rm -rf build && \
		echo "  • Copying .gdip file to output..." && \
		cp $$module.gdip $(IOS_PLUGINS_DIR)/$$module/ && \
		echo "  • Copying Firebase SDK frameworks..." && \
		case $$module in \
			firebase_core) \
				echo "    - Copying frameworks from FirebaseAnalytics..." && \
				cp -a $(FIREBASE_SDK_DIR)/FirebaseAnalytics/*.xcframework $(IOS_PLUGINS_DIR)/$$module/ ;; \
			firebase_analytics) \
				echo "    - Copying frameworks from FirebaseAnalytics..." && \
				cp -a $(FIREBASE_SDK_DIR)/FirebaseAnalytics/*.xcframework $(IOS_PLUGINS_DIR)/$$module/ ;; \
			firebase_crashlytics) \
				echo "    - Copying frameworks from FirebaseCrashlytics..." && \
				cp -a $(FIREBASE_SDK_DIR)/FirebaseCrashlytics/*.xcframework $(IOS_PLUGINS_DIR)/$$module/ ;; \
			firebase_messaging) \
				echo "    - Copying frameworks from FirebaseMessaging..." && \
				cp -a $(FIREBASE_SDK_DIR)/FirebaseMessaging/*.xcframework $(IOS_PLUGINS_DIR)/$$module/ ;; \
		esac); \
		echo "  ✓ $$module build complete (Debug + Release)"; \
		echo ""; \
	done
	@echo "====================================================================="
	@echo "✓ All Apple modules built successfully!"
	@echo "====================================================================="

# ============================================================================
# Android Build Targets
# ============================================================================

build-android:
	@echo "====================================================================="
	@echo "Building all Android modules..."
	@echo "====================================================================="
	@echo ""
	@for module in $(ANDROID_MODULES); do \
		echo "→ Building $$module..."; \
		(cd $(ANDROID_SOURCE_DIR)/$$module && \
		echo "  • Running Gradle assembleDebug..." && \
		./gradlew assembleDebug && \
		echo "  • Running Gradle assembleRelease..." && \
		./gradlew assembleRelease); \
		echo "  • Creating output directory..." && \
		rm -rf $(ANDROID_OUTPUT_DIR)/$$module && \
		mkdir -p $(ANDROID_OUTPUT_DIR)/$$module && \
		echo "  • Copying Debug AAR..." && \
		cp $(ANDROID_SOURCE_DIR)/$$module/build/outputs/aar/*-debug.aar $(ANDROID_OUTPUT_DIR)/$$module/$${module}.debug.aar 2>/dev/null || true && \
		echo "  • Copying Release AAR..." && \
		cp $(ANDROID_SOURCE_DIR)/$$module/build/outputs/aar/*-release.aar $(ANDROID_OUTPUT_DIR)/$$module/$${module}.release.aar 2>/dev/null || true && \
		touch $(ANDROID_OUTPUT_DIR)/$$module/.gdignore && \
		echo "  ✓ $$module build complete (Debug + Release)"; \
		echo ""; \
	done
	@echo "====================================================================="
	@echo "✓ All Android modules built successfully!"
	@echo "====================================================================="
	@echo ""
	@echo "Generated AARs:"
	@for module in $(ANDROID_MODULES); do \
		echo "$(ANDROID_OUTPUT_DIR)/$$module/:"; \
		ls -lh $(ANDROID_OUTPUT_DIR)/$$module/*.aar 2>/dev/null || echo "  (No AARs found)"; \
	done

# ============================================================================
# Combined Targets
# ============================================================================

build-all: build-apple build-android
	@echo ""
	@echo "====================================================================="
	@echo "✓✓✓ ALL MODULES BUILT SUCCESSFULLY! ✓✓✓"
	@echo "====================================================================="

package:
	@echo "====================================================================="
	@echo "Creating package..."
	@echo "====================================================================="
	@echo ""
	@echo "→ Creating package directory..."
	@rm -rf godotx_firebase
	@mkdir -p godotx_firebase
	@echo "→ Copying addons..."
	@cp -a addons godotx_firebase/
	@echo "→ Copying iOS plugins..."
	@cp -a ios godotx_firebase/
	@echo "→ Copying Android plugins..."
	@mkdir -p godotx_firebase/android
	@cp -a android/firebase_* godotx_firebase/android/
	@echo "→ Creating zip archive..."
	@zip -ry godotx_firebase.zip godotx_firebase
	@rm -rf godotx_firebase
	@echo ""
	@echo "====================================================================="
	@echo "✓ Package created: godotx_firebase.zip"
	@echo "====================================================================="

# ============================================================================
# Clean Targets
# ============================================================================

clean:
	@echo "====================================================================="
	@echo "Cleaning build artifacts..."
	@echo "====================================================================="
	@echo ""
	@for module in $(APPLE_MODULES); do \
		echo "→ Cleaning iOS $$module..."; \
		rm -rf $(IOS_PLUGINS_DIR)/$$module; \
		rm -rf $(IOS_SOURCE_DIR)/$$module/build; \
	done
	@for module in $(ANDROID_MODULES); do \
		echo "→ Cleaning Android $$module..."; \
		rm -rf $(ANDROID_OUTPUT_DIR)/$$module; \
		if [ -d "$(ANDROID_SOURCE_DIR)/$$module" ]; then \
			(cd $(ANDROID_SOURCE_DIR)/$$module && ./gradlew clean); \
		fi; \
	done
	@echo ""
	@echo "====================================================================="
	@echo "✓ Clean complete!"
	@echo "====================================================================="

clean-sdk:
	@echo "====================================================================="
	@echo "Removing Firebase SDK..."
	@echo "====================================================================="
	@echo ""
	@if [ -d "$(FIREBASE_SDK_DIR)" ]; then \
		echo "→ Removing Firebase SDK directory..."; \
		rm -rf $(FIREBASE_SDK_DIR); \
		echo "  ✓ Firebase SDK removed"; \
	else \
		echo "  • Firebase SDK directory does not exist"; \
	fi
	@echo ""
	@echo "====================================================================="
	@echo "✓ Done!"
	@echo "====================================================================="

clean-godot:
	@echo "====================================================================="
	@echo "Removing Godot source..."
	@echo "====================================================================="
	@echo ""
	@if [ -d "$(GODOT_DIR)" ]; then \
		echo "→ Removing Godot directory..."; \
		rm -rf $(GODOT_DIR); \
		echo "  ✓ Godot source removed"; \
	else \
		echo "  • Godot directory does not exist"; \
	fi
	@echo ""
	@echo "====================================================================="
	@echo "✓ Done!"
	@echo "====================================================================="
