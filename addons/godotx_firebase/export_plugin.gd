@tool
extends EditorPlugin

const PLUGIN_NAME = "Godotx Firebase"

var apple_export_plugin: AppleExportPlugin
var android_export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	apple_export_plugin = AppleExportPlugin.new()
	android_export_plugin = AndroidExportPlugin.new()

	add_export_plugin(apple_export_plugin)
	add_export_plugin(android_export_plugin)


func _exit_tree() -> void:
	if apple_export_plugin:
		remove_export_plugin(apple_export_plugin)
		apple_export_plugin = null

	if android_export_plugin:
		remove_export_plugin(android_export_plugin)
		android_export_plugin = null


# ============================================================================
# Apple Export Plugin (iOS)
# ============================================================================
class AppleExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return PLUGIN_NAME


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAppleEmbedded


	func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
		var options: Array[Dictionary] = []

		if platform.get_os_name() != "iOS":
			return options

		# iOS config file
		options.append({
			"option": {
				"name": "firebase/ios_config_file",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_FILE,
				"hint_string": "*.plist"
			},
			"default_value": "res://GoogleService-Info.plist"
		})

		# Enable Core
		options.append({
			"option": {
				"name": "firebase/enable_core",
				"type": TYPE_BOOL
			},
			"default_value": true
		})

		# Enable Analytics
		options.append({
			"option": {
				"name": "firebase/enable_analytics",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		# Enable Crashlytics
		options.append({
			"option": {
				"name": "firebase/enable_crashlytics",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		# Enable Messaging
		options.append({
			"option": {
				"name": "firebase/enable_messaging",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		# Enable Remote Config
		options.append({
			"option": {
				"name": "firebase/enable_remote_config",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		return options


	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		if not features.has("ios"):
			return

		# Add iOS config file
		var ios_file = get_option("firebase/ios_config_file")
		if ios_file != "" and FileAccess.file_exists(ios_file):
			print("[Firebase] Adding iOS config: " + ios_file)
			add_apple_embedded_platform_bundle_file(ios_file)




# ============================================================================
# Android Export Plugin
# ============================================================================
class AndroidExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return PLUGIN_NAME


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid


	func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
		var options: Array[Dictionary] = []

		if platform.get_os_name() != "Android":
			return options

		# Android config file
		options.append({
			"option": {
				"name": "firebase/android_config_file",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_FILE,
				"hint_string": "*.json"
			},
			"default_value": "res://google-services.json"
		})

		# Enable Core
		options.append({
			"option": {
				"name": "firebase/enable_core",
				"type": TYPE_BOOL
			},
			"default_value": true
		})

		# Core version
		options.append({
			"option": {
				"name": "firebase/core_version",
				"type": TYPE_STRING
			},
			"default_value": "22.0.1"
		})

		# Enable Analytics
		options.append({
			"option": {
				"name": "firebase/enable_analytics",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		# Analytics version
		options.append({
			"option": {
				"name": "firebase/analytics_version",
				"type": TYPE_STRING
			},
			"default_value": "23.2.0"
		})

		# Enable Crashlytics
		options.append({
			"option": {
				"name": "firebase/enable_crashlytics",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		# Crashlytics version
		options.append({
			"option": {
				"name": "firebase/crashlytics_version",
				"type": TYPE_STRING
			},
			"default_value": "20.0.6"
		})

		# Enable Messaging
		options.append({
			"option": {
				"name": "firebase/enable_messaging",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		# Messaging version
		options.append({
			"option": {
				"name": "firebase/messaging_version",
				"type": TYPE_STRING
			},
			"default_value": "25.0.2"
		})

		# Enable Remote Config
		options.append({
			"option": {
				"name": "firebase/enable_remote_config",
				"type": TYPE_BOOL
			},
			"default_value": false
		})

		# Remote Config version
		options.append({
			"option": {
				"name": "firebase/remote_config_version",
				"type": TYPE_STRING
			},
			"default_value": "22.0.1"
		})

		return options


	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var dependencies: PackedStringArray = []

		# Core
		if get_option("firebase/enable_core"):
			var version = get_option("firebase/core_version")
			dependencies.append("com.google.firebase:firebase-common:" + version)
			print("[Firebase] Adding Core dependency (v%s)" % version)

		# Analytics
		if get_option("firebase/enable_analytics"):
			var version = get_option("firebase/analytics_version")
			dependencies.append("com.google.firebase:firebase-analytics:" + version)
			print("[Firebase] Adding Analytics dependency (v%s)" % version)

		# Crashlytics
		if get_option("firebase/enable_crashlytics"):
			var version = get_option("firebase/crashlytics_version")
			dependencies.append("com.google.firebase:firebase-crashlytics:" + version)
			print("[Firebase] Adding Crashlytics dependency (v%s)" % version)

		# Messaging
		if get_option("firebase/enable_messaging"):
			var version = get_option("firebase/messaging_version")
			dependencies.append("com.google.firebase:firebase-messaging:" + version)
			print("[Firebase] Adding Messaging dependency (v%s)" % version)

		# Remote Config
		if get_option("firebase/enable_remote_config"):
			var version = get_option("firebase/remote_config_version")
			dependencies.append("com.google.firebase:firebase-config-ktx:" + version)
			print("[Firebase] Adding Remote Config dependency (v%s)" % version)

		return dependencies


	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var libraries: PackedStringArray = []
		var build_type: String = "debug" if debug else "release"

		# List of modules to check (in order)
		var modules: Array[String] = []

		if get_option("firebase/enable_core"):
			modules.append("firebase_core")

		if get_option("firebase/enable_analytics"):
			modules.append("firebase_analytics")

		if get_option("firebase/enable_crashlytics"):
			modules.append("firebase_crashlytics")

		if get_option("firebase/enable_messaging"):
			modules.append("firebase_messaging")

		if get_option("firebase/enable_remote_config"):
			modules.append("firebase_remote_config")

		# Search for AARs in each module's directory
		for module in modules:
			var module_path: String = "res://android/" + module + "/"
			var aar_file_name: String = module + "." + build_type + ".aar"
			var aar_full_path: String = module_path + aar_file_name

			if FileAccess.file_exists(aar_full_path):
				# Add relative path from android/ directory
				var rel_path: String = "../android/" + module + "/" + aar_file_name
				libraries.append(rel_path)
				print("[Firebase] Adding Android library (%s): %s" % [build_type, aar_file_name])
			else:
				push_warning("[Firebase] AAR not found: " + aar_full_path)

		if libraries.is_empty():
			push_warning("[Firebase] No Android libraries found")
		else:
			print("[Firebase] Total Android libraries found: " + str(libraries.size()))

		return libraries


	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		if not features.has("android"):
			return

		# Selected file in export options
		var android_file: String = get_option("firebase/android_config_file")
		if android_file == "" or not FileAccess.file_exists(android_file):
			return

		var file := FileAccess.open(android_file, FileAccess.READ)
		if not file:
			push_error("[Firebase] Failed to open Android config file: " + android_file)
			return

		var content: PackedByteArray = file.get_buffer(file.get_length())
		file.close()

		# Destination within the Android template
		var dest_res_path := "res://android/build/google-services.json"
		var dest_dir_res := dest_res_path.get_base_dir()
		var dest_dir_abs := ProjectSettings.globalize_path(dest_dir_res)

		var err := DirAccess.make_dir_recursive_absolute(dest_dir_abs)
		if err != OK and err != ERR_ALREADY_EXISTS:
			push_error("[Firebase] Could not create directory for google-services.json: " + dest_dir_abs)
			return

		var out_file := FileAccess.open(dest_res_path, FileAccess.WRITE)
		if not out_file:
			push_error("[Firebase] Could not write Android config to: " + dest_res_path)
			return

		out_file.store_buffer(content)
		out_file.close()
		print("[Firebase] ✓ Copied google-services.json → " + dest_res_path)

		# Patch Gradle files to declare and apply the Crashlytics Gradle plugin.
		# The plugin is required at build time to inject a build UUID into the APK.
		# Without it the app crashes on launch when Crashlytics is enabled.
		if get_option("firebase/enable_crashlytics"):
			_patch_gradle_file(
				"res://android/build/settings.gradle",
				"id 'com.google.gms.google-services' version '4.4.2'",
				"id 'com.google.gms.google-services' version '4.4.2'\n        id 'com.google.firebase.crashlytics' version '3.0.3'",
				"settings.gradle"
			)
			_patch_gradle_file(
				"res://android/build/build.gradle",
				"id 'com.google.gms.google-services'",
				"id 'com.google.gms.google-services'\n    id 'com.google.firebase.crashlytics'",
				"build.gradle"
			)


	func _patch_gradle_file(res_path: String, needle: String, replacement: String, label: String) -> void:
		if not FileAccess.file_exists(res_path):
			push_warning("[Firebase] %s not found, skipping Crashlytics Gradle plugin injection" % label)
			return
		var f := FileAccess.open(res_path, FileAccess.READ)
		var text := f.get_as_text()
		f.close()
		if "firebase.crashlytics" in text:
			return
		var patched := text.replace(needle, replacement)
		if patched == text:
			push_warning("[Firebase] Could not inject Crashlytics plugin into %s — pattern not found" % label)
			return
		var out := FileAccess.open(res_path, FileAccess.WRITE)
		out.store_string(patched)
		out.close()
		print("[Firebase] ✓ Injected Crashlytics Gradle plugin into %s" % label)

