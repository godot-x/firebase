package com.godotx.firebase.messaging

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.RemoteMessage
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class FirebaseMessagingPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        val TAG = FirebaseMessagingPlugin::class.java.simpleName
        const val PERMISSION_REQUEST_CODE = 1001
        private var _instance: java.lang.ref.WeakReference<FirebaseMessagingPlugin>? = null
        val instance: FirebaseMessagingPlugin? get() = _instance?.get()
    }

    init {
        _instance = java.lang.ref.WeakReference(this)
        Log.v(TAG, "Firebase Messaging plugin loaded")
    }

    private val handledMessageIds = mutableSetOf<String>()
    private var coldStartIntent: Intent? = null
    private var isInitialized = false

    override fun getPluginName(): String {
        return "GodotxFirebaseMessaging"
    }

    // Note: When the app is in the background, FCM displays the notification in the system tray
    // and does NOT deliver the notification payload to onMessageReceived. In that case,
    // remoteMessage.notification will be null and title/body will be empty strings.
    // See: https://firebase.google.com/docs/cloud-messaging/android/receive-messages
    fun notifyMessageReceived(remoteMessage: RemoteMessage) {
        val title = remoteMessage.notification?.title ?: ""
        val body = remoteMessage.notification?.body ?: ""
        emitSignal("messaging_message_received", title, body)
    }

    private fun handleIntentMessage(intent: Intent) {
        val extras = intent.extras ?: return
        val remoteMessage = RemoteMessage(extras)

        // Validate it's actually a FCM message (same check as Firebase C++ SDK)
        // see. https://github.com/firebase/firebase-cpp-sdk/blob/main/messaging/src/android/java/com/google/firebase/messaging/MessageForwardingService.java
        if (remoteMessage.from == null || remoteMessage.messageId == null) {
            Log.d(TAG, "Message is not a FCM message")
            return
        }

        if (!handledMessageIds.add(remoteMessage.messageId!!)) {
            // Already emitted for this message ID
            Log.d(TAG, "Message ID ${remoteMessage.messageId} already handled")
            return
        }

        notifyMessageReceived(remoteMessage)
    }

    // Called when app resumes from background
    // If initialize() has not been called yet, defer processing until it is.
    override fun onMainResume() {
        val intent = activity?.intent ?: return
        if (!isInitialized) {
            coldStartIntent = intent
            return
        }
        handleIntentMessage(intent)
    }

    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            SignalInfo("messaging_permission_granted"),
            SignalInfo("messaging_permission_denied"),
            SignalInfo("messaging_token_received",
                String::class.java
            ),
            SignalInfo("messaging_message_received",
                String::class.java,
                String::class.java
            ),
            SignalInfo("messaging_error",
                String::class.java
            )
        )
    }

    override fun onMainRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>?,
        grantResults: IntArray?
    ) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults != null && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Notification permission granted")
                emitSignal("messaging_permission_granted")
            } else {
                Log.d(TAG, "Notification permission denied")
                emitSignal("messaging_permission_denied")
            }
        }
    }

    @UsedByGodot
    fun initialize() {
        val ctx = activity

        if (ctx == null) {
            Log.e(TAG, "initialize: activity is null")
            emitSignal("messaging_error", "activity_null")
            return
        }

        try {
            val apps = com.google.firebase.FirebaseApp.getApps(ctx)

            if (apps.isEmpty()) {
                Log.e(TAG, "Firebase is NOT initialized")
                emitSignal("messaging_error", "firebase_not_initialized")
                return
            }

            Log.d(TAG, "Firebase Messaging initialized (${apps.size} Firebase app(s) found)")

            isInitialized = true

            // Emit any notification that was received before initialization (cold start or early resume)
            coldStartIntent?.let { handleIntentMessage(it) }
            coldStartIntent = null
        } catch (e: Exception) {
            Log.e(TAG, "Firebase initialization check failed", e)
            emitSignal("messaging_error", e.message ?: "firebase_check_failed")
        }
    }

    @UsedByGodot
    fun request_permission() {
        val ctx = activity
        if (ctx == null) {
            Log.e(TAG, "Activity is null")
            emitSignal("messaging_error", "activity_null")
            return
        }

        // For Android 13 (API 33) and above, need to request POST_NOTIFICATIONS permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    ctx,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    PERMISSION_REQUEST_CODE
                )
            } else {
                // Permission already granted
                Log.d(TAG, "Notification permission already granted")
                emitSignal("messaging_permission_granted")
            }
        } else {
            // For Android < 13, permission not required
            Log.d(TAG, "Notification permission not required (Android < 13)")
            emitSignal("messaging_permission_granted")
        }
    }

    @UsedByGodot
    fun get_token() {
        try {
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                if (!task.isSuccessful) {
                    Log.e(TAG, "Failed to get FCM token", task.exception)
                    emitSignal("messaging_error", task.exception?.message ?: "token_fetch_failed")
                    return@addOnCompleteListener
                }

                val token = task.result
                Log.d(TAG, "FCM token: $token")
                emitSignal("messaging_token_received", token)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting token", e)
            emitSignal("messaging_error", e.message ?: "token_error")
        }
    }

    @UsedByGodot
    fun subscribe_to_topic(topic: String) {
        try {
            FirebaseMessaging.getInstance().subscribeToTopic(topic)
                .addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        Log.d(TAG, "Subscribed to topic: $topic")
                    } else {
                        Log.e(TAG, "Failed to subscribe to topic", task.exception)
                        emitSignal("messaging_error", task.exception?.message ?: "subscribe_failed")
                    }
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error subscribing to topic", e)
            emitSignal("messaging_error", e.message ?: "subscribe_error")
        }
    }

    @UsedByGodot
    fun unsubscribe_from_topic(topic: String) {
        try {
            FirebaseMessaging.getInstance().unsubscribeFromTopic(topic)
                .addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        Log.d(TAG, "Unsubscribed from topic: $topic")
                    } else {
                        Log.e(TAG, "Failed to unsubscribe from topic", task.exception)
                        emitSignal("messaging_error", task.exception?.message ?: "unsubscribe_failed")
                    }
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error unsubscribing from topic", e)
            emitSignal("messaging_error", e.message ?: "unsubscribe_error")
        }
    }
}

