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
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set user ID", e)
            emitSignal("crashlytics_error", e.message ?: "set_user_error")
        }
    }

    @UsedByGodot
    fun set_custom_value_string(key: String, value: String) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            crashlyticsInstance.setCustomKey(key, value)
            Log.d(TAG, "Set custom value: $key = $value")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set custom value", e)
            emitSignal("crashlytics_error", e.message ?: "set_custom_value_error")
        }
    }

    @UsedByGodot
    fun set_custom_value_int(key: String, value: Int) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            crashlyticsInstance.setCustomKey(key, value.toLong())
            Log.d(TAG, "Set custom value: $key = $value")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set custom value", e)
            emitSignal("crashlytics_error", e.message ?: "set_custom_value_error")
        }
    }

    @UsedByGodot
    fun set_custom_value_bool(key: String, value: Boolean) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            crashlyticsInstance.setCustomKey(key, value)
            Log.d(TAG, "Set custom value: $key = $value")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set custom value", e)
            emitSignal("crashlytics_error", e.message ?: "set_custom_value_error")
        }
    }

    @UsedByGodot
    fun set_custom_value_float(key: String, value: Float) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            crashlyticsInstance.setCustomKey(key, value.toDouble())
            Log.d(TAG, "Set custom value: $key = $value")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set custom value", e)
            emitSignal("crashlytics_error", e.message ?: "set_custom_value_error")
        }
    }

    /**
     * Records a non-fatal error, such as a script error the engine survived.
     * Each frame is "function<TAB>file<TAB>line", innermost first.
     */
    @UsedByGodot
    fun record_error(name: String, message: String, frames: Array<String>) {
        val crashlyticsInstance = crashlytics
        if (crashlyticsInstance == null) {
            Log.e(TAG, "Firebase Crashlytics not initialized")
            emitSignal("crashlytics_error", "crashlytics_not_initialized")
            return
        }

        try {
            val error = GodotError(name, message)
            error.stackTrace = frames.map { frame ->
                val parts = frame.split("\t")
                StackTraceElement(name, parts.getOrElse(0) { "" }, parts.getOrNull(1), parts.getOrNull(2)?.toIntOrNull() ?: -1)
            }.toTypedArray()
            crashlyticsInstance.recordException(error)
            Log.d(TAG, "Recorded error: $name: $message")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record error", e)
            emitSignal("crashlytics_error", e.message ?: "record_error_error")
        }
    }

    @UsedByGodot
    fun set_crashlytics_collection_enabled(enabled: Boolean) {
        FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(enabled)
    }

    /** Crashlytics groups issues by type, so the type is named after `name`. */
    private class GodotError(val name: String, message: String) : Exception(message) {
        override fun toString(): String = "$name: $message"
    }
}

