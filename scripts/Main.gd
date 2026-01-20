extends Control

# Firebase Singletons
var core: Object = null
var analytics: Object = null
var crashlytics: Object = null
var messaging: Object = null

# UI Elements
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var log_output: TextEdit = $VBoxContainer/ScrollContainer/ContentContainer/LogOutput

func _ready() -> void:
	log_message("=== Firebase Plugin Test ===")
	initialize_firebase_plugins()

func initialize_firebase_plugins() -> void:
	# Firebase Core
	if Engine.has_singleton("GodotxFirebaseCore"):
		core = Engine.get_singleton("GodotxFirebaseCore")
		core.core_initialized.connect(_on_core_initialized)
		core.core_error.connect(_on_error.bind("Core"))
		log_message("✓ Firebase Core plugin found")
	else:
		log_message("✗ Firebase Core plugin not found")

	# Firebase Analytics
	if Engine.has_singleton("GodotxFirebaseAnalytics"):
		analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
		analytics.analytics_initialized.connect(_on_analytics_initialized)
		analytics.analytics_event_logged.connect(_on_event_logged)
		analytics.analytics_error.connect(_on_error.bind("Analytics"))
		log_message("✓ Firebase Analytics plugin found")
	else:
		log_message("✗ Firebase Analytics plugin not found")

	# Firebase Crashlytics
	if Engine.has_singleton("GodotxFirebaseCrashlytics"):
		crashlytics = Engine.get_singleton("GodotxFirebaseCrashlytics")
		crashlytics.crashlytics_initialized.connect(_on_crashlytics_initialized)
		crashlytics.crashlytics_error.connect(_on_error.bind("Crashlytics"))
		log_message("✓ Firebase Crashlytics plugin found")
	else:
		log_message("✗ Firebase Crashlytics plugin not found")

	# Firebase Messaging
	if Engine.has_singleton("GodotxFirebaseMessaging"):
		messaging = Engine.get_singleton("GodotxFirebaseMessaging")
		messaging.messaging_permission_granted.connect(_on_permission_granted)
		messaging.messaging_permission_denied.connect(_on_permission_denied)
		messaging.messaging_token_received.connect(_on_token_received)
		messaging.messaging_apn_token_received.connect(_on_apn_token_received)
		messaging.messaging_message_received.connect(_on_message_received)
		messaging.messaging_error.connect(_on_error.bind("Messaging"))
		log_message("✓ Firebase Messaging plugin found")
	else:
		log_message("✗ Firebase Messaging plugin not found")

func log_message(message: String) -> void:
	print(message)
	if log_output:
		log_output.text += message + "\n"
		log_output.scroll_vertical = log_output.get_line_count()

func update_status(text: String, color: Color = Color.WHITE) -> void:
	if status_label:
		status_label.text = text
		status_label.modulate = color

# ============== CORE ==============
func _on_initialize_pressed() -> void:
	if core:
		log_message("\n[Core] Initializing Firebase...")
		update_status("Initializing...", Color.YELLOW)
		core.initialize()
	else:
		log_message("[Core] Plugin not available")

func _on_core_initialized(success: bool) -> void:
	if success:
		log_message("[Core] ✓ Firebase initialized successfully!")

		# Initialize dependent modules
		if crashlytics:
			log_message("[Crashlytics] Initializing...")
			crashlytics.initialize()
		if analytics:
			log_message("[Analytics] Initializing...")
			analytics.initialize()
		if messaging:
			log_message("[Messaging] Initializing...")
			messaging.initialize()
	else:
		log_message("[Core] ✗ Firebase initialization failed")
		update_status("Initialization Failed", Color.RED)

func _on_crashlytics_initialized(success: bool) -> void:
	if success:
		log_message("[Crashlytics] ✓ Initialized")
	else:
		log_message("[Crashlytics] ✗ Initialization failed")

func _on_analytics_initialized(success: bool) -> void:
	if success:
		log_message("[Analytics] ✓ Initialized")
		update_status("Firebase Ready", Color.GREEN)
	else:
		log_message("[Analytics] ✗ Initialization failed")

# ============== ANALYTICS ==============
func _on_log_event_pressed() -> void:
	if analytics:
		var event_name = "test_button_clicked"
		var params = {
			"timestamp": str(Time.get_unix_time_from_system()),
			"screen": "main",
			"test_value": "42"
		}
		log_message("\n[Analytics] Logging event: " + event_name)
		log_message("  Params: " + str(params))
		analytics.log_event(event_name, params)
	else:
		log_message("[Analytics] Plugin not available")

func _on_log_screen_pressed() -> void:
	if analytics:
		var params = {
			"screen_name": "main_screen",
			"screen_class": "MainScene"
		}
		log_message("\n[Analytics] Logging screen view")
		log_message("  Params: " + str(params))
		analytics.log_event("screen_view", params)
	else:
		log_message("[Analytics] Plugin not available")

func _on_event_logged(event_name: String) -> void:
	log_message("[Analytics] ✓ Event logged: " + event_name)

# ============== CRASHLYTICS ==============
func _on_log_crashlytics_pressed() -> void:
	if crashlytics:
		var message = "Test log message from Godot - " + str(Time.get_datetime_string_from_system())
		log_message("\n[Crashlytics] Logging message: " + message)
		crashlytics.log_message(message)
		log_message("[Crashlytics] ✓ Message logged")
	else:
		log_message("[Crashlytics] Plugin not available")

func _on_set_user_id_pressed() -> void:
	if crashlytics:
		var user_id = "test_user_" + str(randi() % 10000)
		log_message("\n[Crashlytics] Setting user ID: " + user_id)
		crashlytics.set_user_id(user_id)
		log_message("[Crashlytics] ✓ User ID set")
	else:
		log_message("[Crashlytics] Plugin not available")

func _on_force_crash_pressed() -> void:
	if crashlytics:
		log_message("\n[Crashlytics] ⚠ FORCING CRASH - App will close!")
		update_status("Crashing...", Color.RED)
		await get_tree().create_timer(0.5).timeout
		crashlytics.crash()
	else:
		log_message("[Crashlytics] Plugin not available")

# ============== MESSAGING ==============
func _on_request_permission_pressed() -> void:
	if messaging:
		log_message("\n[Messaging] Requesting notification permission...")
		messaging.request_permission()
		log_message("[Messaging] Permission request sent")
	else:
		log_message("[Messaging] Plugin not available")

func _on_get_token_pressed() -> void:
	if messaging:
		log_message("\n[Messaging] Requesting FCM token...")
		update_status("Getting Token...", Color.YELLOW)
		messaging.get_token()

		# Also request APNs token (iOS only)
		if OS.get_name() == "iOS":
			messaging.get_apns_token()
	else:
		log_message("[Messaging] Plugin not available")

func _on_subscribe_topic_pressed() -> void:
	if messaging:
		var topic = "test_topic"
		log_message("\n[Messaging] Subscribing to topic: " + topic)
		messaging.subscribe_to_topic(topic)
		log_message("[Messaging] Subscribe request sent")
	else:
		log_message("[Messaging] Plugin not available")

func _on_unsubscribe_topic_pressed() -> void:
	if messaging:
		var topic = "test_topic"
		log_message("\n[Messaging] Unsubscribing from topic: " + topic)
		messaging.unsubscribe_from_topic(topic)
		log_message("[Messaging] Unsubscribe request sent")
	else:
		log_message("[Messaging] Plugin not available")

func _on_permission_granted() -> void:
	log_message("[Messaging] ✓ Notification permission granted")
	update_status("Permission Granted", Color.GREEN)

func _on_permission_denied() -> void:
	log_message("[Messaging] ⓘ Notification permission denied")
	log_message("  User declined or disabled notifications in system settings")
	update_status("Permission Denied", Color.ORANGE)

func _on_token_received(token: String) -> void:
	log_message("[Messaging] ✓ FCM Token received:")
	log_message("  " + token)
	update_status("Token Received", Color.GREEN)

func _on_apn_token_received(token: String) -> void:
	log_message("[Messaging] ✓ APN Device Token received:")
	log_message("  " + token)
	update_status("APN Token Received", Color.GREEN)

func _on_message_received(title: String, body: String) -> void:
	log_message("[Messaging] ✓ Message received:")
	log_message("  Title: " + title)
	log_message("  Body: " + body)

# ============== GENERAL ==============
func _on_error(message: String, module: String) -> void:
	log_message("[" + module + "] ✗ Error: " + message)
	update_status("Error: " + message, Color.RED)

func _on_clear_log_pressed() -> void:
	if log_output:
		log_output.text = ""
		log_message("=== Log Cleared ===")
		update_status("Ready", Color.WHITE)
