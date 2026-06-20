package com.godotx.firebase.analytics

import android.os.Bundle
import android.util.Log
import com.google.firebase.analytics.FirebaseAnalytics
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject
import org.godotengine.godot.Dictionary

class FirebaseAnalyticsPlugin(godot: Godot) : GodotPlugin(godot) {

    private var firebaseAnalytics: FirebaseAnalytics? = null

    companion object {
        val TAG = FirebaseAnalyticsPlugin::class.java.simpleName
    }

    init {
        Log.v(TAG, "Firebase Analytics plugin loaded")
    }

    override fun getPluginName(): String {
        return "GodotxFirebaseAnalytics"
    }

    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            SignalInfo(
                "analytics_initialized",
                Boolean::class.javaObjectType
            ),
            SignalInfo(
                "analytics_event_logged",
                String::class.java
            ),
            SignalInfo(
                "analytics_screen_logged",
                String::class.java
            ),
            SignalInfo(
                "analytics_property_set",
                String::class.java
            ),
            SignalInfo(
                "analytics_user_id_set",
                String::class.java
            ),
            SignalInfo(
                "analytics_default_params_set"
            ),
            SignalInfo(
                "analytics_collection_enabled_set",
                Boolean::class.javaObjectType
            ),
            SignalInfo(
                "analytics_data_reset"
            ),
            SignalInfo(
                "analytics_consent_set"
            ),
            SignalInfo(
                "analytics_error",
                String::class.java
            )
        )
    }

    @UsedByGodot
    fun initialize() {
        try {
            val ctx = activity
            if (ctx == null) {
                Log.e(TAG, "Activity is null")
                emitSignal("analytics_initialized", false)
                emitSignal("analytics_error", "activity_null")
                return
            }
            firebaseAnalytics = FirebaseAnalytics.getInstance(ctx)
            Log.d(TAG, "Firebase Analytics initialized")
            emitSignal("analytics_initialized", true)
        } catch (e: Exception) {
            Log.e(TAG, "Firebase Analytics init failed", e)
            emitSignal("analytics_initialized", false)
            emitSignal("analytics_error", e.message ?: "init_error")
        }
    }

    private fun dictionaryToBundle(params: Dictionary): Bundle {
        val bundle = Bundle()
        for (key in params.keys) {
            val value = params[key]

            // firebase parameter names must be strings
            if (key !is String || value == null) {
                continue
            }

            when (value) {
                is Int -> bundle.putInt(key, value)
                is Long -> bundle.putLong(key, value)
                is Float -> bundle.putDouble(key, value.toDouble())
                is Double -> bundle.putDouble(key, value)
                is Boolean -> {
                    // firebase analytics does NOT support boolean
                    bundle.putInt(key, if (value) 1 else 0)
                }
                is String -> bundle.putString(key, value)
                else -> {
                    // unsupported types are silently ignored
                    Log.w(TAG, "Unsupported param type for key=$key (${value::class.java})")
                }
            }
        }
        return bundle
    }

    @UsedByGodot
    fun log_event(event_name: String, params: Dictionary) {
        val analytics = firebaseAnalytics
        if (analytics == null) {
            Log.e(TAG, "Firebase Analytics not initialized")
            emitSignal("analytics_error", "analytics_not_initialized")
            return
        }

        try {
            val bundle = dictionaryToBundle(params)
            analytics.logEvent(event_name, bundle)
            Log.d(TAG, "Event logged: $event_name")
            emitSignal("analytics_event_logged", event_name)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to log event", e)
            emitSignal("analytics_error", e.message ?: "event_log_error")
        }
    }

    @UsedByGodot
    fun set_user_id(user_id: String?) {
        val analytics = firebaseAnalytics ?: return
        try {
            analytics.setUserId(user_id)
            Log.d(TAG, "User ID set")
            emitSignal("analytics_user_id_set", user_id ?: "")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set User ID", e)
            emitSignal("analytics_error", e.message ?: "user_id_error")
        }
    }

    @UsedByGodot
    fun set_user_property(name: String, value: String?) {
        val analytics = firebaseAnalytics ?: return
        try {
            analytics.setUserProperty(name, value)
            Log.d(TAG, "User property set: $name = $value")
            emitSignal("analytics_property_set", name)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set user property", e)
            emitSignal("analytics_error", e.message ?: "user_property_error")
        }
    }

    @UsedByGodot
    fun log_screen_view(screen_name: String, screen_class: String) {
        val analytics = firebaseAnalytics ?: return
        try {
            val bundle = Bundle()
            bundle.putString(FirebaseAnalytics.Param.SCREEN_NAME, screen_name)
            bundle.putString(FirebaseAnalytics.Param.SCREEN_CLASS, screen_class)
            analytics.logEvent(FirebaseAnalytics.Event.SCREEN_VIEW, bundle)
            Log.d(TAG, "Screen view logged: $screen_name ($screen_class)")
            emitSignal("analytics_screen_logged", screen_name)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to log screen view", e)
            emitSignal("analytics_error", e.message ?: "screen_view_error")
        }
    }

    @UsedByGodot
    fun set_default_event_parameters(params: Dictionary) {
        val analytics = firebaseAnalytics ?: return
        try {
            val bundle = dictionaryToBundle(params)
            analytics.setDefaultEventParameters(bundle)
            Log.d(TAG, "Default event parameters set")
            emitSignal("analytics_default_params_set")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set default event parameters", e)
            emitSignal("analytics_error", e.message ?: "default_params_error")
        }
    }

    @UsedByGodot
    fun set_collection_enabled(enabled: Boolean) {
        val analytics = firebaseAnalytics ?: return
        try {
            analytics.setAnalyticsCollectionEnabled(enabled)
            Log.d(TAG, "Analytics collection enabled: $enabled")
            emitSignal("analytics_collection_enabled_set", enabled)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set collection enabled", e)
            emitSignal("analytics_error", e.message ?: "collection_enabled_error")
        }
    }

    @UsedByGodot
    fun reset_analytics_data() {
        val analytics = firebaseAnalytics ?: return
        try {
            analytics.resetAnalyticsData()
            Log.d(TAG, "Analytics data reset")
            emitSignal("analytics_data_reset")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to reset analytics data", e)
            emitSignal("analytics_error", e.message ?: "reset_data_error")
        }
    }

    @UsedByGodot
    fun set_consent(consent_data: Dictionary) {
        val analytics = firebaseAnalytics ?: return
        try {
            val consentMap = java.util.EnumMap<FirebaseAnalytics.ConsentType, FirebaseAnalytics.ConsentStatus>(FirebaseAnalytics.ConsentType::class.java)

            val adStorage = consent_data["ad_storage"]
            if (adStorage is Boolean) {
                consentMap[FirebaseAnalytics.ConsentType.AD_STORAGE] = if (adStorage) FirebaseAnalytics.ConsentStatus.GRANTED else FirebaseAnalytics.ConsentStatus.DENIED
            }

            val analyticsStorage = consent_data["analytics_storage"]
            if (analyticsStorage is Boolean) {
                consentMap[FirebaseAnalytics.ConsentType.ANALYTICS_STORAGE] = if (analyticsStorage) FirebaseAnalytics.ConsentStatus.GRANTED else FirebaseAnalytics.ConsentStatus.DENIED
            }

            val adUserData = consent_data["ad_user_data"]
            if (adUserData is Boolean) {
                consentMap[FirebaseAnalytics.ConsentType.AD_USER_DATA] = if (adUserData) FirebaseAnalytics.ConsentStatus.GRANTED else FirebaseAnalytics.ConsentStatus.DENIED
            }

            val adPersonalization = consent_data["ad_personalization"]
            if (adPersonalization is Boolean) {
                consentMap[FirebaseAnalytics.ConsentType.AD_PERSONALIZATION] = if (adPersonalization) FirebaseAnalytics.ConsentStatus.GRANTED else FirebaseAnalytics.ConsentStatus.DENIED
            }

            analytics.setConsent(consentMap)
            Log.d(TAG, "Analytics consent set: $consentMap")
            emitSignal("analytics_consent_set")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set consent", e)
            emitSignal("analytics_error", e.message ?: "consent_error")
        }
    }

    @UsedByGodot
    fun log_level_start(level_name: String) {
        val params = Dictionary()
        params[FirebaseAnalytics.Param.LEVEL_NAME] = level_name
        log_event(FirebaseAnalytics.Event.LEVEL_START, params)
    }

    @UsedByGodot
    fun log_level_end(level_name: String, success: Boolean) {
        val params = Dictionary()
        params[FirebaseAnalytics.Param.LEVEL_NAME] = level_name
        params[FirebaseAnalytics.Param.SUCCESS] = if (success) 1 else 0
        log_event(FirebaseAnalytics.Event.LEVEL_END, params)
    }

    @UsedByGodot
    fun log_earn_currency(currency_name: String, value: Float) {
        val params = Dictionary()
        params[FirebaseAnalytics.Param.VIRTUAL_CURRENCY_NAME] = currency_name
        params[FirebaseAnalytics.Param.VALUE] = value
        log_event(FirebaseAnalytics.Event.EARN_VIRTUAL_CURRENCY, params)
    }

    @UsedByGodot
    fun log_spend_currency(currency_name: String, value: Float, item_name: String) {
        val params = Dictionary()
        params[FirebaseAnalytics.Param.VIRTUAL_CURRENCY_NAME] = currency_name
        params[FirebaseAnalytics.Param.VALUE] = value
        params[FirebaseAnalytics.Param.ITEM_NAME] = item_name
        log_event(FirebaseAnalytics.Event.SPEND_VIRTUAL_CURRENCY, params)
    }

    @UsedByGodot
    fun log_tutorial_begin() {
        log_event(FirebaseAnalytics.Event.TUTORIAL_BEGIN, Dictionary())
    }

    @UsedByGodot
    fun log_tutorial_complete() {
        log_event(FirebaseAnalytics.Event.TUTORIAL_COMPLETE, Dictionary())
    }

    @UsedByGodot
    fun log_post_score(score: Long, board: String, character: String) {
        val params = Dictionary()
        params[FirebaseAnalytics.Param.SCORE] = score
        if (board.isNotEmpty()) {
            params[FirebaseAnalytics.Param.LEVEL_NAME] = board
        }
        if (character.isNotEmpty()) {
            params[FirebaseAnalytics.Param.CHARACTER] = character
        }
        log_event(FirebaseAnalytics.Event.POST_SCORE, params)
    }

    @UsedByGodot
    fun log_unlock_achievement(id: String) {
        val params = Dictionary()
        params[FirebaseAnalytics.Param.ACHIEVEMENT_ID] = id
        log_event(FirebaseAnalytics.Event.UNLOCK_ACHIEVEMENT, params)
    }
}

