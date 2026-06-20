extends Control


# Dashboard button paths (used by flash_status / update_btn_status)
const ActionRegistry = preload("res://scripts/ActionRegistry.gd")
const INIT_PATH := "VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/InitializeButton"
const ANALYTICS_PATH := "VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/AnalyticsButton"
const CRASHLYTICS_PATH := "VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/CrashlyticsButton"
const MESSAGING_PATH := "VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/MessagingButton"
const REMOTE_CONFIG_PATH := "VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/RemoteConfigButton"

# Firebase Singletons (Public)
var core: Object = null
var analytics: Object = null
var crashlytics: Object = null
var messaging: Object = null
var remote_config: Object = null

# Internal State (Private)
var _pending_call: Dictionary = {
	"Analytics": "",
	"Crashlytics": "",
	"Messaging": "",
	"RemoteConfig": "",
}
var _fcm_token: String = ""
var _messaging_permission_granted: bool = false
var _apns_ready: bool = false

# Navigation Elements
@onready var back_button: Button = $VBoxContainer/HeaderGroup/MarginContainer/HBoxContainer/BackButton
@onready var view_title: Label = $VBoxContainer/HeaderGroup/MarginContainer/HBoxContainer/ViewTitle

# Views
@onready var dashboard_view: ScrollContainer = $VBoxContainer/ContextGroup/Dashboard
@onready var module_container: Control = $VBoxContainer/ContextGroup/ModuleContainer

# Dashboard Buttons
@onready var init_btn: Button = $VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/InitializeButton
@onready var analytics_btn: Button = $VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/AnalyticsButton
@onready var crashlytics_btn: Button = $VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/CrashlyticsButton
@onready var messaging_btn: Button = $VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/MessagingButton
@onready var remote_config_btn: Button = $VBoxContainer/ContextGroup/Dashboard/MarginContainer/List/RemoteConfigButton

# Log Elements
@onready var log_output: TextEdit = $VBoxContainer/LogGroup/MarginContainer/VBoxContainer/LogOutput

@onready var _actions: Dictionary = ActionRegistry.get_actions()


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	log_message("=== Firebase Test Harness ===")
	show_dashboard()
	enable_service_buttons(false)
	initialize_firebase_plugins()

func initialize_firebase_plugins() -> void:
	# Core
	if Engine.has_singleton("GodotxFirebaseCore"):
		core = Engine.get_singleton("GodotxFirebaseCore")
		core.core_initialized.connect(_on_core_initialized)
		core.core_error.connect(_on_error.bind("Core"))
		log_message("✓ Firebase Core plugin found")
	else:
		log_message("✗ Firebase Core plugin not found")

	# Analytics
	if Engine.has_singleton("GodotxFirebaseAnalytics"):
		analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
		analytics.analytics_initialized.connect(_on_module_init_done.bind("Analytics"))

		# Connect all async signals to generic success handler with validation
		analytics.analytics_event_logged.connect(func(event_name: String):
			var success: bool = not event_name.is_empty()
			if success: log_message("[Analytics] ✓ Event logged: " + event_name)
			else: log_message("[Analytics] ✗ Event log returned empty name")
			_clear_pending("Analytics", success))

		analytics.analytics_screen_logged.connect(func(screen_name: String):
			var success: bool = not screen_name.is_empty()
			if success: log_message("[Analytics] ✓ Screen logged: " + screen_name)
			else: log_message("[Analytics] ✗ Screen log returned empty name")
			_clear_pending("Analytics", success))

		analytics.analytics_property_set.connect(func(prop_name: String):
			var success: bool = not prop_name.is_empty()
			if success: log_message("[Analytics] ✓ Property set: " + prop_name)
			else: log_message("[Analytics] ✗ Property set returned empty name")
			_clear_pending("Analytics", success))

		analytics.analytics_user_id_set.connect(func(id: String):
			# Note: User ID could intentionally be empty if resetting
			log_message("[Analytics] ✓ User ID set: " + id); _clear_pending("Analytics", true))

		analytics.analytics_default_params_set.connect(func(): log_message("[Analytics] ✓ Default params set"); _clear_pending("Analytics"))
		analytics.analytics_collection_enabled_set.connect(func(enabled: bool): log_message("[Analytics] ✓ Collection enabled: " + str(enabled)); _clear_pending("Analytics"))
		analytics.analytics_data_reset.connect(func(): log_message("[Analytics] ✓ Analytics data reset"); _clear_pending("Analytics"))
		analytics.analytics_consent_set.connect(func(): log_message("[Analytics] ✓ Consent updated"); _clear_pending("Analytics"))

		analytics.analytics_error.connect(_on_module_error.bind("Analytics"))
		log_message("✓ Firebase Analytics plugin found")
	else:
		log_message("✗ Firebase Analytics plugin not found")

	# Crashlytics
	if Engine.has_singleton("GodotxFirebaseCrashlytics"):
		crashlytics = Engine.get_singleton("GodotxFirebaseCrashlytics")
		crashlytics.crashlytics_initialized.connect(_on_module_init_done.bind("Crashlytics"))

		# Connect async signals
		crashlytics.crashlytics_non_fatal_logged.connect(func(msg: String): log_message("[Crashlytics] ✓ Non-fatal logged: " + msg); _clear_pending("Crashlytics"))
		crashlytics.crashlytics_message_logged.connect(func(msg: String): log_message("[Crashlytics] ✓ Message logged: " + msg); _clear_pending("Crashlytics"))
		crashlytics.crashlytics_value_set.connect(func(key: String): log_message("[Crashlytics] ✓ Value set for: " + key); _clear_pending("Crashlytics"))
		crashlytics.crashlytics_user_id_set.connect(func(uid: String): log_message("[Crashlytics] ✓ User ID set: " + uid); _clear_pending("Crashlytics"))

		crashlytics.crashlytics_error.connect(_on_module_error.bind("Crashlytics"))
		log_message("✓ Firebase Crashlytics plugin found")
	else:
		log_message("✗ Firebase Crashlytics plugin not found")

	# Messaging
	if Engine.has_singleton("GodotxFirebaseMessaging"):
		messaging = Engine.get_singleton("GodotxFirebaseMessaging")
		messaging.messaging_initialized.connect(_on_module_init_done.bind("Messaging"))
		messaging.messaging_permission_granted.connect(_on_messaging_permission_granted)
		messaging.messaging_permission_denied.connect(_on_messaging_permission_denied)
		messaging.messaging_token_received.connect(_on_messaging_token_received)
		if OS.get_name() == "iOS":
			messaging.messaging_apn_token_received.connect(_on_messaging_apn_token_received)
		messaging.messaging_message_received.connect(_on_messaging_message_received)
		messaging.messaging_topic_subscribed.connect(_on_messaging_topic_subscribed)
		messaging.messaging_topic_unsubscribed.connect(_on_messaging_topic_unsubscribed)
		messaging.messaging_error.connect(_on_module_error.bind("Messaging"))
		log_message("✓ Firebase Messaging plugin found")
	else:
		log_message("✗ Firebase Messaging plugin not found")

	# Remote Config
	if Engine.has_singleton("GodotxFirebaseRemoteConfig"):
		remote_config = Engine.get_singleton("GodotxFirebaseRemoteConfig")
		remote_config.remote_config_initialized.connect(_on_module_init_done.bind("RemoteConfig"))

		# Connect async signals (with validation where needed)
		remote_config.remote_config_fetch_completed.connect(func(status: int):
			var status_map: Dictionary = {0: "SUCCESS", 1: "CACHED", 2: "FAILURE", 3: "THROTTLED"}
			log_message("[Remote Config] Fetch result: " + status_map.get(status, "UNKNOWN"))
			_clear_pending("RemoteConfig", status == 0 or status == 1)
		)
		remote_config.remote_config_defaults_set.connect(func(): _clear_pending("RemoteConfig"))
		remote_config.remote_config_settings_updated.connect(func(): _clear_pending("RemoteConfig"))
		remote_config.remote_config_listener_registered.connect(func(): _clear_pending("RemoteConfig"))
		remote_config.remote_config_updated.connect(_on_config_updated)

		remote_config.remote_config_error.connect(_on_module_error.bind("RemoteConfig"))
		log_message("✓ Firebase Remote Config plugin found")
	else:
		log_message("✗ Firebase Remote Config plugin not found")

# ============== NAVIGATION ==============

func show_dashboard() -> void:
	view_title.text = "Firebase Harness"
	back_button.visible = false
	dashboard_view.visible = true
	module_container.visible = false
	for module in module_container.get_children():
		module.visible = false

func show_module(module_name: String) -> void:
	dashboard_view.visible = false
	module_container.visible = true
	back_button.visible = true
	view_title.text = "Firebase " + module_name

	for child: Node in module_container.get_children():
		child.queue_free()

	var node_name: String = module_name.replace(" ", "") + "View"
	var scene_path: String = "res://scenes/view_stack/" + node_name + ".tscn"

	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		var instance: Node = scene.instantiate()
		module_container.add_child(instance)
		instance.name = node_name
		_connect_module_buttons(module_name, instance)
	else:
		log_message("[System] Module view '" + node_name + "' not implemented")

# ============== HELPERS ==============

func log_message(message: String) -> void:
	print(message)
	if log_output:
		log_output.text += message + "\n"
		log_output.scroll_vertical = log_output.get_line_count()

func update_btn_status(path: String, status: int) -> void:
	var btn: Node = get_node_or_null(path)
	if btn and btn.has_method("update_status"):
		btn.update_status(status)

func flash_status(path: String, status: int) -> void:
	update_btn_status(path, status)

func enable_service_buttons(enabled: bool) -> void:
	analytics_btn.disabled = !enabled
	crashlytics_btn.disabled = !enabled
	messaging_btn.disabled = !enabled
	remote_config_btn.disabled = !enabled

func _module_btn_path(module_name: String, btn_name: String) -> String:
	var base_path: String = "VBoxContainer/ContextGroup/ModuleContainer/" + module_name.replace(" ", "") + "View/"

	if module_name in ["Remote Config", "RemoteConfig"]:
		return base_path + "List/MarginContainer/ButtonList/" + btn_name

	# Analytics, Messaging ve Crashlytics artık aynı Scroll/Margin yapısını kullanıyor
	return base_path + "ScrollContainer/MarginContainer/List/" + btn_name

func _connect_module_buttons(module_name: String, instance: Node) -> void:
	if module_name == "Analytics":
		var list: Node = instance.get_node("ScrollContainer/MarginContainer/List")
		for btn_name in _actions["Analytics"].keys():
			_connect_btn(list, btn_name, _run_action.bind("Analytics", btn_name))
	elif module_name == "Messaging":
		var list: Node = instance.get_node("ScrollContainer/MarginContainer/List")
		for btn_name in _actions["Messaging"].keys():
			_connect_btn(list, btn_name, _run_action.bind("Messaging", btn_name))
		_update_messaging_view_state(instance)
	elif module_name == "Crashlytics":
		var list: Node = instance.get_node("ScrollContainer/MarginContainer/List")
		for btn_name in _actions["Crashlytics"].keys():
			_connect_btn(list, btn_name, _run_action.bind("Crashlytics", btn_name))
	elif module_name == "Remote Config":
		var list: Node = instance.get_node("List/MarginContainer/ButtonList")
		for btn_name in _actions["RemoteConfig"].keys():
			_connect_btn(list, btn_name, _run_action.bind("RemoteConfig", btn_name))

func _connect_btn(instance: Node, btn_name: String, method: Callable) -> void:
	var btn: Button = instance.get_node_or_null(btn_name) as Button
	if btn: btn.pressed.connect(method)

# ============== ACTION RUNNER ==============

func _run_action(module_name: String, action_id: String) -> void:
	var log_name: String = "Remote Config" if module_name == "RemoteConfig" else module_name
	var config: Dictionary = _actions.get(module_name, {}).get(action_id, {})
	if config.is_empty():
		log_message("[System] Error: No config for %s:%s" % [module_name, action_id])
		return

	var plugin: Object = null
	match module_name:
		"Analytics": plugin = analytics
		"Crashlytics": plugin = crashlytics
		"Messaging": plugin = messaging
		"RemoteConfig": plugin = remote_config

	var btn_path: String = _module_btn_path(module_name, action_id)
	if not plugin:
		log_message("[%s] Plugin not available" % log_name)
		flash_status(btn_path, TestButton.Status.FAILURE)
		return

	log_message("\n[%s] %s" % [log_name, config.get("desc", "Running...")])
	flash_status(btn_path, TestButton.Status.PENDING)

	# Mark as pending for async signals
	if config.get("signal", "") != "":
		_pending_call[module_name] = btn_path

	# Execute the call
	var method: String = config["method"]
	var args: Array = config.get("args", [])
	var result: Variant = plugin.callv(method, args)

	# If it's a getter, log the result and validate
	if config.get("mode", "") == "getter":
		var key_prefix: String = "'%s' = " % args[0] if args.size() > 0 and typeof(args[0]) == TYPE_STRING else ""
		log_message("[%s] %s%s" % [log_name, key_prefix, str(result)])
		var is_valid: bool = true
		if config.has("validator"):
			is_valid = config["validator"].call(result)
		if not is_valid and config.has("failure_log"):
			log_message("[%s] ✗ %s" % [log_name, config["failure_log"]])
		flash_status(btn_path, TestButton.Status.SUCCESS if is_valid else TestButton.Status.FAILURE)

	# If it's a sync call (no signal and not manual mode), set success immediately
	if config.get("signal", "") == "" and config.get("mode", "") != "manual" and config.get("mode", "") != "getter":
		flash_status(btn_path, TestButton.Status.SUCCESS)

# ============== CORE ==============

func _on_initialize_pressed() -> void:
	if not core:
		log_message("[Core] Plugin not available")
		flash_status(INIT_PATH, TestButton.Status.FAILURE)
		return
	log_message("\n[Core] Initializing Firebase...")
	flash_status(INIT_PATH, TestButton.Status.PENDING)
	init_btn.disabled = true
	core.initialize()

func _on_core_initialized(success: bool) -> void:
	init_btn.disabled = false
	if not success:
		log_message("[Core] ✗ Firebase initialization failed")
		flash_status(INIT_PATH, TestButton.Status.FAILURE)
		enable_service_buttons(false)
		return

	log_message("[Core] ✓ Firebase initialized successfully!")
	flash_status(INIT_PATH, TestButton.Status.SUCCESS)
	_start_module_init_cascade()

func _start_module_init_cascade() -> void:
	if analytics:
		log_message("[Analytics] Initializing...")
		analytics.initialize()
	if crashlytics:
		log_message("[Crashlytics] Initializing...")
		crashlytics.initialize()
	if messaging:
		log_message("[Messaging] Initializing...")
		messaging.initialize()
	if remote_config:
		log_message("[Remote Config] Initializing...")
		remote_config.initialize()

func _on_module_init_done(success: bool, module_name: String) -> void:
	var module_btn: Button = null
	match module_name:
		"Analytics":
			module_btn = analytics_btn
		"Crashlytics":
			module_btn = crashlytics_btn
		"Messaging":
			module_btn = messaging_btn
		"RemoteConfig":
			module_btn = remote_config_btn

	if success:
		log_message("[%s] ✓ Initialized" % module_name)
		if module_btn: module_btn.disabled = false
	else:
		log_message("[%s] ✗ Initialization failed" % module_name)
		if module_btn: module_btn.disabled = true

# (Analytics Handlers removed - now using _run_action)

# (Messaging pressed handlers removed - now using _run_action)

func _on_messaging_permission_granted() -> void:
	log_message("[Messaging] ✓ Permission granted")
	_messaging_permission_granted = true
	_clear_pending("Messaging")

	var view = module_container.get_node_or_null("MessagingView")
	if view:
		_update_messaging_view_state(view)

func _on_messaging_permission_denied() -> void:
	log_message("[Messaging] ✗ Permission denied")
	var path: String = _pending_call.get("Messaging", "")
	if path != "":
		flash_status(path, TestButton.Status.FAILURE)
		_pending_call["Messaging"] = ""

func _on_messaging_topic_subscribed(topic: String) -> void:
	log_message("[Messaging] ✓ Subscribed to: " + topic)
	_clear_pending("Messaging")

func _on_messaging_topic_unsubscribed(topic: String) -> void:
	log_message("[Messaging] ✓ Unsubscribed from: " + topic)
	_clear_pending("Messaging")

func _on_messaging_token_received(token: String) -> void:
	if token.is_empty():
		log_message("[Messaging] ✗ Token received but it is EMPTY")
		_clear_pending("Messaging", false)
		return

	_fcm_token = token
	log_message("[Messaging] Token received: " + token)
	_clear_pending("Messaging", true)

	var view = module_container.get_node_or_null("MessagingView")
	if view:
		_update_messaging_view_state(view)

func _on_messaging_apn_token_received(_token: String) -> void:
	_apns_ready = true
	log_message("[Messaging] APNs Token received (Ready for FCM)")

func _update_messaging_view_state(view: Node) -> void:
	var has_token = !_fcm_token.is_empty()
	var permission_ok = _messaging_permission_granted

	var list_path := "ScrollContainer/MarginContainer/List/"
	var perm_btn = view.get_node_or_null(list_path + "PermissionButton")
	var token_btn = view.get_node_or_null(list_path + "GetTokenButton")
	var sub_btn = view.get_node_or_null(list_path + "SubscribeButton")
	var unsub_btn = view.get_node_or_null(list_path + "UnsubscribeButton")
	var last_notification_btn = view.get_node_or_null(list_path + "GetLastNotificationButton")

	# Step 1: Permission button is always enabled
	if perm_btn: perm_btn.disabled = false

	# Step 2: Get Token only enabled after permission is granted
	if token_btn: token_btn.disabled = !permission_ok

	# Step 3: Topic operations and Get Last Notification only enabled after both permission and token are obtained
	if sub_btn: sub_btn.disabled = !(permission_ok and has_token)
	if unsub_btn: unsub_btn.disabled = !(permission_ok and has_token)
	if last_notification_btn: last_notification_btn.disabled = !(permission_ok and has_token)

func _on_messaging_message_received(title: String, body: String, data: Dictionary = {}) -> void:
	log_message("[Messaging] Message received: " + title + " — " + body)
	if not data.is_empty():
		log_message("[Messaging] Data payload: " + str(data))

# (Crashlytics Handlers removed - now using _run_action)

# ============== INTERNAL / PRIVATE ==============

func _apply_safe_area() -> void:
	var os_name: String = OS.get_name()
	if os_name != "iOS" and os_name != "Android":
		return
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if safe_area.size != Vector2i.ZERO and safe_area.size != window_size:
		var top_margin: int = safe_area.position.y
		var bottom_margin: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		var left_margin: int = safe_area.position.x
		var right_margin: int = window_size.x - (safe_area.position.x + safe_area.size.x)

		if has_node("VBoxContainer"):
			var vbox: Control = $VBoxContainer as Control
			vbox.offset_top = top_margin
			vbox.offset_bottom = - bottom_margin
			vbox.offset_left = left_margin
			vbox.offset_right = - right_margin

# ============== ERRORS ==============

func _on_error(message: String, module: String) -> void:
	log_message("[" + module + "] ✗ Error: " + message)

func _on_module_error(message: String, module_name: String) -> void:
	log_message("[%s] ✗ Error: %s" % [module_name, message])
	var path: String = _pending_call.get(module_name, "")
	if path != "":
		flash_status(path, TestButton.Status.FAILURE)
		_pending_call[module_name] = ""

func _clear_pending(module_name: String, success: bool = true) -> void:
	var path: String = _pending_call.get(module_name, "")
	if path != "":
		flash_status(path, TestButton.Status.SUCCESS if success else TestButton.Status.FAILURE)
		_pending_call[module_name] = ""

# ============== LOG CONTROLS ==============

func _on_clear_log_pressed() -> void:
	if log_output: log_output.text = ""
	log_message("=== Log Cleared ===")

func _on_copy_log_pressed() -> void:
	if log_output:
		DisplayServer.clipboard_set(log_output.text)
		log_message("[System] Log copied to clipboard")


# (Remote Config Handlers removed - now using _run_action)

func _on_config_updated(keys: Array) -> void:
	log_message("[Remote Config] 📡 Config updated: " + str(keys))
