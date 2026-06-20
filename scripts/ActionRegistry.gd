static func get_actions() -> Dictionary:
	return {
		"Analytics": {
			"LogEventButton": {
				"method": "log_event", "args": ["test_event", {"p1": "v1", "p2": 123}],
				"signal": "analytics_event_logged", "desc": "Logging event: test_event"
			},
			"LogScreenButton": {
				"method": "log_screen_view", "args": ["MainScene", "GodotSampleActivity"],
				"signal": "analytics_screen_logged", "desc": "Logging screen: MainScene"
			},
			"UserPropsButton": {
				"method": "set_user_property", "args": ["test_prop", "test_value"],
				"signal": "analytics_property_set", "desc": "Setting user property: test_prop = test_value"
			},
			"SetUserIdButton": {
				"method": "set_user_id", "args": ["player_123"],
				"signal": "analytics_user_id_set", "desc": "Setting User ID: player_123"
			},
			"SetDefaultParamsButton": {
				"method": "set_default_event_parameters", "args": [ {"app_version": "1.0.0"}],
				"signal": "analytics_default_params_set", "desc": "Setting default params: app_version=1.0.0"
			},
			"SetConsentButton": {
				"method": "set_consent", "args": [ {"analytics_storage": false}],
				"signal": "analytics_consent_set", "desc": "Setting Consent: analytics_storage=false"
			},
			"SetCollectionEnabledButton": {
				"method": "set_collection_enabled", "args": [false],
				"signal": "analytics_collection_enabled_set", "desc": "Toggling Collection Enabled: false"
			},
			"ResetDataButton": {
				"method": "reset_analytics_data", "args": [],
				"signal": "analytics_data_reset", "desc": "Resetting Analytics Data"
			},
			"LogLevelStartButton": {
				"method": "log_level_start", "args": ["level_1"],
				"signal": "analytics_event_logged", "desc": "Logging level_start: level_1"
			},
			"LogLevelEndButton": {
				"method": "log_level_end", "args": ["level_1", true],
				"signal": "analytics_event_logged", "desc": "Logging level_end: level_1 (Success)"
			},
			"LogEarnButton": {
				"method": "log_earn_currency", "args": ["gold", 100.0],
				"signal": "analytics_event_logged", "desc": "Logging earn_currency: 100 gold"
			},
			"LogSpendButton": {
				"method": "log_spend_currency", "args": ["gold", 50.0, "sword"],
				"signal": "analytics_event_logged", "desc": "Logging spend_currency: 50 gold for sword"
			},
			"LogTutorialBeginButton": {
				"method": "log_tutorial_begin", "args": [],
				"signal": "analytics_event_logged", "desc": "Logging tutorial_begin"
			},
			"LogTutorialCompleteButton": {
				"method": "log_tutorial_complete", "args": [],
				"signal": "analytics_event_logged", "desc": "Logging tutorial_complete"
			},
			"LogPostScoreButton": {
				"method": "log_post_score", "args": [5000, "hall_of_fame", "ninja"],
				"signal": "analytics_event_logged", "desc": "Logging post_score: 5000"
			},
			"LogUnlockAchievementButton": {
				"method": "log_unlock_achievement", "args": ["master_of_gemini"],
				"signal": "analytics_event_logged", "desc": "Logging unlock_achievement: master_of_gemini"
			}
		},
		"Crashlytics": {
			"FatalButton": {"method": "crash", "args": [], "mode": "manual", "desc": "!!! FORCING FATAL CRASH !!!"},
			"NonFatalButton": {
				"method": "log_non_fatal", "args": ["This is a test non-fatal error"],
				"signal": "crashlytics_non_fatal_logged", "desc": "Logging non-fatal error"
			},
			"LogMsgButton": {
				"method": "log_message", "args": ["This is a custom log message"],
				"signal": "crashlytics_message_logged", "desc": "Logging custom message"
			},
			"SetUserIdButton": {
				"method": "set_user_id", "args": ["player_crash_123"],
				"signal": "crashlytics_user_id_set", "desc": "Setting User ID for crashes"
			},
			"CustomValueButton": {
				"method": "set_custom_value", "args": ["test_key", "test_value"],
				"signal": "crashlytics_value_set", "desc": "Setting custom value: test_key = test_value (String)"
			}
		},
		"RemoteConfig": {
			"FetchButton": {"method": "fetch_and_activate", "args": [], "signal": "remote_config_fetch_completed", "desc": "Fetching and Activating..."},
			"GetStringButton": {
				"method": "get_string",
				"args": ["welcome_message", "DEFAULT"],
				"mode": "getter",
				"desc": "Getting 'welcome_message'",
				"validator": func(res: Variant): return typeof(res) == TYPE_STRING,
				"failure_log": "Expected String, but received invalid type"
			},
			"GetIntButton": {
				"method": "get_int",
				"args": ["min_version", -1],
				"mode": "getter",
				"desc": "Getting 'min_version'",
				"validator": func(res: Variant): return typeof(res) == TYPE_INT,
				"failure_log": "Expected Int, but received invalid type"
			},
			"GetFloatButton": {
				"method": "get_float",
				"args": ["drop_rate", 0.0],
				"mode": "getter",
				"desc": "Getting 'drop_rate'",
				"validator": func(res: Variant): return typeof(res) == TYPE_FLOAT,
				"failure_log": "Expected Float, but received invalid type"
			},
			"GetDoubleButton": {
				"method": "get_double",
				"args": ["drop_rate_v2", 0.0],
				"mode": "getter",
				"desc": "Getting 'drop_rate_v2' (double)",
				"validator": func(res: Variant): return typeof(res) == TYPE_FLOAT,
				"failure_log": "Expected Float/Double, but received invalid type"
			},
			"GetBoolButton": {
				"method": "get_bool",
				"args": ["feature_enabled", false],
				"mode": "getter",
				"desc": "Getting 'feature_enabled'",
				"validator": func(res: Variant): return typeof(res) == TYPE_INT and (res == 0 or res == 1),
				"failure_log": "Expected Int (1 or 0), but received invalid type"
			},
			"GetDictButton": {
				"method": "get_dictionary",
				"args": ["game_config"],
				"mode": "getter",
				"desc": "Getting 'game_config'",
				"validator": func(res: Variant): return typeof(res) == TYPE_DICTIONARY,
				"failure_log": "Expected Dictionary, but received invalid type"
			},
			"SetDefaultsButton": {
				"method": "set_defaults",
				"args": [ {"welcome_message": "Hello from Defaults!", "min_version": 10, "drop_rate": 0.05, "feature_enabled": true}],
				"signal": "remote_config_defaults_set", "desc": "Setting local defaults"
			},
			"SetIntervalButton": {"method": "set_minimum_fetch_interval", "args": [0.0], "signal": "remote_config_settings_updated", "desc": "Setting fetch interval to 0s (Dev Mode)"},
			"ListenerButton": {
				"method": "setup_realtime_updates",
				"args": [],
				"signal": "remote_config_listener_registered",
				"desc": "Enabling Real-time updates listener"
			},
			"RemoveListenerButton": {
				"method": "remove_config_update_listener",
				"args": [],
				"desc": "Removing Real-time updates listener"
			}
		},
		"Messaging": {
			"GetTokenButton": {"method": "get_token", "args": [], "signal": "messaging_token_received", "desc": "Requesting FCM token..."},
			"GetAPNSTokenButton": {"method": "get_apns_token", "args": [], "signal": "messaging_apn_token_received", "desc": "Requesting APNs token (iOS)..."},
			"PermissionButton": {"method": "request_permission", "args": [], "signal": "messaging_permission_granted", "desc": "Requesting permissions..."},
			"SubscribeButton": {"method": "subscribe_to_topic", "args": ["test_topic"], "signal": "messaging_topic_subscribed", "desc": "Subscribing to: test_topic"},
			"UnsubscribeButton": {"method": "unsubscribe_from_topic", "args": ["test_topic"], "signal": "messaging_topic_unsubscribed", "desc": "Unsubscribing from: test_topic"},
			"GetLastNotificationButton": {
				"method": "get_last_notification",
				"args": [],
				"mode": "getter",
				"desc": "Getting last notification...",
				"validator": func(res: Variant): return typeof(res) == TYPE_DICTIONARY and not res.is_empty(),
				"failure_log": "No previous notification data found"
			}
		}
	}
