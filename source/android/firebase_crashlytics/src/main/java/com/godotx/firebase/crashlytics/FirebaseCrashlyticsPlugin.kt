package com.godotx.firebase.crashlytics

import android.util.Log
import com.google.firebase.crashlytics.FirebaseCrashlytics
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class FirebaseCrashlyticsPlugin(godot: Godot) : GodotPlugin(godot) {

    private var crashlytics: FirebaseCrashlytics? = null

    companion object {
        val TAG = FirebaseCrashlyticsPlugin::class.java.simpleName
    }

    init {
        Log.v(TAG, "Firebase Crashlytics plugin loaded")
    }

    override fun getPluginName(): String {
        return "GodotxFirebaseCrashlytics"
    }

    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            SignalInfo("crashlytics_initialized",
                Boolean::class.javaObjectType
            ),
            SignalInfo("crashlytics_non_fatal_logged",
                String::class.java
            ),
            SignalInfo("crashlytics_message_logged",
                String::class.java
            ),
            SignalInfo("crashlytics_value_set",
                String::class.java
            ),
            SignalInfo("crashlytics_user_id_set",
                String::class.java
            ),
            SignalInfo("crashlytics_error",
                String::class.java
            )
        )
    }

    @UsedByGodot
    fun initialize() {
        try {
            crashlytics = FirebaseCrashlytics.getInstance()
            Log.d(TAG, "Firebase Crashlytics initialized")
            emitSignal("crashlytics_initialized", true)
        } catch (e: Exception) {
            Log.e(TAG, "Firebase Crashlytics init failed", e)
            emitSignal("crashlytics_initialized", false)
            emitSignal("crashlytics_error", e.message ?: "init_error")
        }
    }

    @UsedByGodot
    fun crash() {
        Log.d(TAG, "Forcing crash for testing...")
        val crash: String? = null
        crash!!.length
    }

    @UsedByGodot
    fun log_non_fatal(message: String) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            crashlyticsInstance.recordException(Exception(message))
            Log.d(TAG, "Recorded non-fatal exception: $message")
            emitSignal("crashlytics_non_fatal_logged", message)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record non-fatal exception", e)
            emitSignal("crashlytics_error", e.message ?: "non_fatal_log_error")
        }
    }

    @UsedByGodot
    fun log_message(message: String) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            crashlyticsInstance.log(message)
            Log.d(TAG, "Logged message to Crashlytics: $message")
            emitSignal("crashlytics_message_logged", message)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to log message", e)
            emitSignal("crashlytics_error", e.message ?: "log_error")
        }
    }

    @UsedByGodot
    fun set_user_id(user_id: String) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            crashlyticsInstance.setUserId(user_id)
            Log.d(TAG, "Set user ID: $user_id")
            emitSignal("crashlytics_user_id_set", user_id)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set user ID", e)
            emitSignal("crashlytics_error", e.message ?: "set_user_error")
        }
    }

    @UsedByGodot
    fun set_custom_value(key: String, value: String) {
        val c = crashlytics
        if (c == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }
        try {
            c.setCustomKey(key, value)
            Log.d(TAG, "Set custom value: $key = $value")
            emitSignal("crashlytics_value_set", key)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set custom value", e)
            emitSignal("crashlytics_error", e.message ?: "set_custom_value_error")
        }
    }

}

