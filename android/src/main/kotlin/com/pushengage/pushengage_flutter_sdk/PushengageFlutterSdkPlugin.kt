package com.pushengage.pushengage_flutter_sdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.activity.ComponentActivity
import com.pushengage.pushengage.Callbacks.FcmConfigErrorListener
import com.pushengage.pushengage.Callbacks.PushEngagePermissionCallback
import com.pushengage.pushengage.Callbacks.PushEngageResponseCallback
import com.pushengage.pushengage.PushEngage
import com.pushengage.pushengage.helper.PEConstants
import com.pushengage.pushengage.helper.PEPrefs
import com.pushengage.pushengage.model.request.AddDynamicSegmentRequest
import com.pushengage.pushengage.model.request.Goal
import com.pushengage.pushengage.model.request.TrackEvent
import com.pushengage.pushengage.model.request.TriggerAlert
import com.pushengage.pushengage.model.request.TriggerCampaign
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.text.SimpleDateFormat
import java.util.Locale
import org.json.JSONObject

/** PushEngageFlutterSdkPlugin */
class PushEngageFlutterSdkPlugin :
        FlutterPlugin,
        MethodCallHandler,
        ActivityAware,
        PluginRegistry.NewIntentListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    // Cold-boot buffer: deep-link / FCM-error events may fire before Dart has
    // had a chance to subscribe (the Activity's launch intent is processed in
    // onAttachedToActivity, which can run before main() finishes wiring up
    // the streams). Until Dart calls attachListeners we queue events here;
    // on attach we drain in FIFO order.
    private val bufferLock = Any()
    private var listenersAttached = false
    private val pendingDeepLinks = ArrayDeque<Map<String, Any?>>()
    private val pendingFcmErrors = ArrayDeque<Map<String, Any?>>()

    private companion object {
        // Cap the cold-boot buffers: an app that never subscribes to the Dart
        // streams must not accumulate payloads for the process lifetime.
        // Oldest entries are dropped first.
        const val MAX_PENDING_EVENTS = 32
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "PushEngage")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // Auto-register the FCM config-error listener (Android only). It can be
        // set before SDK init. The listener may fire on an arbitrary background
        // thread, so marshal to the main thread before crossing to Dart.
        PushEngage.setFcmConfigErrorListener(
                FcmConfigErrorListener { code, message ->
                    deliverFcmError(mapOf("code" to code, "message" to message))
                }
        )
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val data = intent.data
        if (Intent.ACTION_VIEW == action && data != null) {
            val deepLink = data.toString()
            val additionalData = intent.extras?.get("data")
            deliverDeepLink(mapOf("deepLink" to deepLink, "data" to additionalData))
        }
    }

    private fun deliverDeepLink(payload: Map<String, Any?>) {
        val emitNow = synchronized(bufferLock) {
            if (listenersAttached) {
                true
            } else {
                if (pendingDeepLinks.size >= MAX_PENDING_EVENTS) pendingDeepLinks.removeFirst()
                pendingDeepLinks.addLast(payload)
                false
            }
        }
        if (emitNow) emitOnMain("onDeepLink", payload)
    }

    private fun deliverFcmError(payload: Map<String, Any?>) {
        val emitNow = synchronized(bufferLock) {
            if (listenersAttached) {
                true
            } else {
                if (pendingFcmErrors.size >= MAX_PENDING_EVENTS) pendingFcmErrors.removeFirst()
                pendingFcmErrors.addLast(payload)
                false
            }
        }
        if (emitNow) emitOnMain("onFcmConfigError", payload)
    }

    private fun emitOnMain(method: String, payload: Map<String, Any?>) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            channel.invokeMethod(method, payload)
        } else {
            mainHandler.post { channel.invokeMethod(method, payload) }
        }
    }

    private fun drainBuffersOnAttach() {
        val deepLinks: List<Map<String, Any?>>
        val fcmErrors: List<Map<String, Any?>>
        synchronized(bufferLock) {
            listenersAttached = true
            deepLinks = pendingDeepLinks.toList()
            fcmErrors = pendingFcmErrors.toList()
            pendingDeepLinks.clear()
            pendingFcmErrors.clear()
        }
        deepLinks.forEach { emitOnMain("onDeepLink", it) }
        fcmErrors.forEach { emitOnMain("onFcmConfigError", it) }
    }

    override fun onMethodCall(call: MethodCall, rawResult: Result) {
        // Wrap the Result so every success/error/notImplemented reply is
        // posted to the platform thread. Most PushEngage SDK callbacks fire
        // on background queues; replying on a non-main thread violates
        // Flutter's documented contract for MethodChannel.Result.
        val result: Result = MainThreadResult(rawResult, mainHandler)
        when (call.method) {
            "PushEngage#setAppId" -> {
                val appId = call.argument<String>("appId")
                if (appId.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "setAppId requires a non-empty appId", null)
                    return
                }
                // Persist the version before build() so first-launch
                // telemetry is tagged correctly. The public
                // PushEngage.setWrapperVersion() cannot be used here: it
                // silently no-ops until Builder().build() has run, and build()
                // may fire the first sync request (whose User-Agent reads this
                // pref) immediately. Intentional internal dependency on PEPrefs.
                call.argument<String>("sdkVersion")?.let {
                    PEPrefs(context).setWrapperVersion(it)
                }
                PushEngage.Builder()
                        .addContext(context)
                        .setAppId(appId)
                        .build()
                result.success(null)
            }
            "PushEngage#setEnvironment" -> {
                val env = call.argument<String>("environment")?.uppercase()
                val normalized =
                        if (env == "STAGING" || env == "STG") PEConstants.STG
                        else PEConstants.PROD
                // Intentional internal dependency: the native Android SDK has
                // no public setEnvironment (iOS does), and the value must be
                // persisted before Builder().build() because it selects the
                // RestClient base URL. Revisit once the native SDK exposes a
                // pre-init-safe public API.
                PEPrefs(context).setEnvironment(normalized)
                result.success(null)
            }
            "PushEngage#getSdkVersion" -> {
                result.success(PushEngage.getSdkVersion())
            }
            "PushEngage#setBadgeCount" -> {
                val count = call.argument<Int>("count") ?: 0
                PushEngage.setBadgeCount(count)
                result.success(null)
            }
            "PushEngage#getDeviceTokenHash" -> {
                result.success(PushEngage.getDeviceTokenHash())
            }
            "PushEngage#enableLogging" -> {
                val status = call.argument<Boolean>("status") ?: false
                PushEngage.enableLogging(status)
                result.success(null)
            }
            "PushEngage#automatedNotification" -> {
                val status = call.argument<Boolean>("status") ?: true
                PushEngage.automatedNotification(
                        if (status) PushEngage.TriggerStatusType.enabled
                        else PushEngage.TriggerStatusType.disabled,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success(
                                        "Automated notification " +
                                                (if (status) "enabled" else "disabled") +
                                                " successfully"
                                )
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#sendTriggerEvent" -> {
                val triggerMap = call.arguments<Map<String, Any>>()
                sendTriggerEvent(triggerMap, result)
            }
            "PushEngage#addAlert" -> {
                val map = call.arguments<Map<String, Any>>()
                if (map == null) {
                    result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                    return
                }
                addAlert(map, result)
            }
            "PushEngage#sendGoal" -> {
                val goalMap = call.arguments<Map<String, Any>>()
                if (goalMap == null) {
                    result.error("INVALID_ARGUMENT", "Missing goal payload", null)
                    return
                }
                val goalName = goalMap["name"] as? String
                if (goalName.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "Goal name is required", null)
                    return
                }
                val goalCount = (goalMap["count"] as? Number)?.toInt()
                val value = (goalMap["value"] as? Number)?.toDouble()
                val goal = Goal(goalName, goalCount, value)

                PushEngage.sendGoal(
                        goal,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Goal sent successfully")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#getSubscriberDetails" -> {
                // null = all fields. The native SDK requires a non-null list and
                // joins it into the `fields` query param, so an empty list is sent
                // as `?fields=` — unlike iOS, which omits the param. Until the
                // native SDK omits the param for an empty list, "all fields"
                // behavior on Android depends on the backend accepting `fields=`.
                val subscriberAttributes =
                        call.argument<List<String>>("values") ?: emptyList()

                // First check subscription status
                PushEngage.getSubscriptionStatus(
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                val isSubscribed = responseObject as? Boolean ?: false
                                if (isSubscribed) {
                                    // Only get subscriber details if subscribed
                                    PushEngage.getSubscriberDetails(
                                            subscriberAttributes,
                                            object : PushEngageResponseCallback {
                                                override fun onSuccess(responseObject: Any?) {
                                                    try {
                                                        val map = responseObject as? Map<*, *>
                                                        if (map == null) {
                                                            result.error(
                                                                    "RESPONSE_FORMAT",
                                                                    "Subscriber details response was not a Map (got ${responseObject?.javaClass?.simpleName})",
                                                                    null)
                                                            return
                                                        }
                                                        result.success(JSONObject(map).toString())
                                                    } catch (t: Throwable) {
                                                        result.error("RESPONSE_FORMAT", t.message, null)
                                                    }
                                                }

                                                override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                                    result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                                                }
                                            }
                                    )
                                } else {
                                    // Not subscribed → failure.
                                    result.error("FAILURE", "Failed retrieving subscriber details", null)
                                }
                            }
                            
                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error("SUBSCRIPTION_STATUS_ERROR", errorMessage ?: "Failed to get subscription status", errorCode)
                            }
                        }
                )
            }
            "PushEngage#requestNotificationPermission" -> {
                requestNotificationPermission(result)
            }
            "PushEngage#getNotificationPermissionStatus" -> {
                val status = PushEngage.getNotificationPermissionStatus()
                result.success(status)
            }
            "PushEngage#getSubscriptionStatus" -> {
                PushEngage.getSubscriptionStatus(
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success(responseObject)
                            }
                            
                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error("SUBSCRIPTION_STATUS_ERROR", errorMessage ?: "Failed to get subscription status", errorCode)
                            }
                        }
                )
            }
            "PushEngage#getSubscriptionNotificationStatus" -> {
                PushEngage.getSubscriptionNotificationStatus(
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success(responseObject)
                            }
                            
                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error("SUBSCRIPTION_NOTIFICATION_STATUS_ERROR", errorMessage ?: "Failed to get subscription notification status", errorCode)
                            }
                        }
                )
            }
            "PushEngage#getSubscriberId" -> {
                PushEngage.getSubscriberId(
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success(responseObject)
                            }
                            
                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error("SUBSCRIBER_ID_ERROR", errorMessage ?: "Failed to get subscriber ID", errorCode)
                            }
                        }
                )
            }
            "PushEngage#unsubscribe" -> {
                PushEngage.unsubscribe(
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success(responseObject)
                            }
                            
                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error("UNSUBSCRIBE_ERROR", errorMessage ?: "Failed to unsubscribe", errorCode)
                            }
                        }
                )
            }
            "PushEngage#subscribe" -> {
                subscribe(result)
            }
            "PushEngage#getSubscriberAttributes" -> {
                PushEngage.getSubscriberAttributes(
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                val asMap = responseObject as? Map<*, *>
                                if (asMap != null) {
                                    result.success(asMap)
                                } else if (responseObject == null) {
                                    result.success(mapOf<String, Any>())
                                } else {
                                    result.error(
                                            "RESPONSE_FORMAT",
                                            "Subscriber attributes response was not a Map (got ${responseObject.javaClass.simpleName})",
                                            null)
                                }
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#addSegment" -> {
                val segments = call.argument<List<String>>("segments")
                PushEngage.addSegment(
                        segments,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Subscriber added to segment(s) successfully")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#removeSegment" -> {
                val segments = call.argument<List<String>>("segments")
                PushEngage.removeSegment(
                        segments,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Subscriber removed from segment(s) successfully")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#addDynamicSegment" -> {
                val segmentsList = call.argument<List<Map<String, Any>>>("segments") ?: emptyList()
                val segments: MutableList<AddDynamicSegmentRequest.Segment> = ArrayList()
                for ((index, map) in segmentsList.withIndex()) {
                    val name = map["name"] as? String
                    val duration = (map["duration"] as? Number)?.toLong()
                    if (name.isNullOrEmpty() || duration == null) {
                        result.error(
                                "INVALID_ARGUMENT",
                                "Segment at index $index is missing required 'name' or 'duration'",
                                null)
                        return
                    }
                    val segment = AddDynamicSegmentRequest().Segment()
                    segment.name = name
                    segment.duration = duration
                    segments.add(segment)
                }
                PushEngage.addDynamicSegment(
                        segments,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Subscriber added to dynamic segment successfully")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#addSubscriberAttributes" -> {
                val jsonString = call.argument<String>("attributes")
                try {
                    val jsonObject = JSONObject(jsonString ?: "{}")
                    PushEngage.addSubscriberAttributes(
                            jsonObject,
                            object : PushEngageResponseCallback {
                                override fun onSuccess(responseObject: Any?) {
                                    result.success("Subscriber attribute(s) added successfully")
                                }

                                override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                    result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                                }
                            }
                    )
                } catch (e: Exception) {
                    result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                }
            }
            "PushEngage#deleteSubscriberAttributes" -> {
                val attributes = call.argument<List<String>>("attributes")
                PushEngage.deleteSubscriberAttributes(
                        attributes,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Subscriber attribute(s) deleted successfully")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#addProfileId" -> {
                val profileId = call.argument<String>("profileId")
                PushEngage.addProfileId(
                        profileId,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Profile Id added successfully")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                            }
                        }
                )
            }
            "PushEngage#setSubscriberAttributes" -> {
                val jsonString = call.argument<String>("attributes")
                try {
                    val jsonObject = JSONObject(jsonString ?: "{}")
                    PushEngage.setSubscriberAttributes(
                            jsonObject,
                            object : PushEngageResponseCallback {
                                override fun onSuccess(responseObject: Any?) {
                                    result.success("Subscriber attribute(s) set successfully")
                                }

                                override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                    result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                                }
                            }
                    )
                } catch (e: Exception) {
                    result.error(400.toString(), "Invalid input", null)
                }
            }
            "PushEngage#setSmallIconResource" -> {
                val resourceName = call.argument<String>("resourceName")
                if (resourceName.isNullOrEmpty()) {
                    result.error(
                            "INVALID_ARGUMENT",
                            "setSmallIconResource requires a non-empty resourceName",
                            null)
                    return
                }
                PushEngage.setSmallIconResource(resourceName)
                result.success(null)
            }
            "PushEngage#identify" -> {
                val json = call.argument<String>("fields")
                if (json == null) {
                    result.error("400", "fields cannot be null", null)
                    return
                }
                try {
                    PushEngage.identify(
                            JSONObject(json),
                            object : PushEngageResponseCallback {
                                override fun onSuccess(responseObject: Any?) {
                                    result.success("Identify successful")
                                }

                                override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                    result.error(
                                            errorCode?.toString() ?: "IDENTIFY_ERROR",
                                            errorMessage ?: "Identify failed",
                                            null
                                    )
                                }
                            }
                    )
                } catch (e: Exception) {
                    result.error("400", "Invalid identify payload: ${e.message}", null)
                }
            }
            "PushEngage#trackEvent" -> {
                val eventName =
                        call.argument<String>("eventName")?.takeIf { it.isNotEmpty() }
                if (eventName == null) {
                    result.error("400", "Missing required eventName", null)
                    return
                }
                val data: Map<String, Any>? =
                        call.argument<Map<String, Any?>>("data")
                                ?.entries
                                ?.mapNotNull { (k, v) -> v?.let { k to it } }
                                ?.toMap()
                val profileId = call.argument<String>("profileId")?.takeIf { it.isNotEmpty() }
                val provider = call.argument<String>("provider")?.takeIf { it.isNotEmpty() }
                val eventType = call.argument<String>("eventType")?.takeIf { it.isNotEmpty() }
                val trackEvent = TrackEvent(eventName, data, profileId, provider, eventType)
                PushEngage.trackEvent(
                        trackEvent,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Track event successful")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(
                                        errorCode?.toString() ?: "TRACK_EVENT_ERROR",
                                        errorMessage ?: "Track event failed",
                                        null
                                )
                            }
                        }
                )
            }
            "PushEngage#logout" -> {
                val names = call.argument<List<String>>("fieldNames")
                PushEngage.logout(
                        names,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Logout successful")
                            }

                            override fun onFailure(errorCode: Int?, errorMessage: String?) {
                                result.error(
                                        errorCode?.toString() ?: "LOGOUT_ERROR",
                                        errorMessage ?: "Logout failed",
                                        null
                                )
                            }
                        }
                )
            }
            "PushEngage#runConfigValidation" -> {
                try {
                    // Intentional use of a @RestrictTo(LIBRARY) native API — no
                    // public equivalent exists yet. A native SDK bump can break
                    // this without a compile error; revisit when the native SDK
                    // promotes runConfigValidation to public.
                    @Suppress("RestrictedApi")
                    val mismatch =
                            PushEngage.runConfigValidation(
                                    call.argument<String>("senderId"),
                                    call.argument<String>("projectId")
                            )
                    // Native returns true on mismatch; invert so true == passed.
                    result.success(!mismatch)
                } catch (e: Exception) {
                    result.error(
                            "CONFIG_VALIDATION_ERROR",
                            e.message ?: "Config validation threw",
                            null
                    )
                }
            }
            "PushEngage#getInitialNotification" -> {
                // Android delivers launch notifications via the host activity's
                // deep-link intent (handleIntent -> onDeepLink), not this method.
                result.success(null)
            }
            "PushEngage#attachListeners" -> {
                // Mark Dart as ready to receive events and drain anything that
                // fired before subscription (cold-boot deep links, early FCM
                // config errors emitted during Builder.build()).
                drainBuffersOnAttach()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PushEngage.setFcmConfigErrorListener(null)
        channel.setMethodCallHandler(null)
        synchronized(bufferLock) {
            listenersAttached = false
            pendingDeepLinks.clear()
            pendingFcmErrors.clear()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        handleIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    private fun requestNotificationPermission(result: Result) {
        try {
            val current = activity
            if (current is ComponentActivity) {
                // For Android 13+ (API 33), the SDK will show permission dialog
                // For older versions, permission is automatically granted
                PushEngage.requestNotificationPermission(
                    current,
                    object : PushEngagePermissionCallback {
                        override fun onPermissionResult(granted: Boolean, error: kotlin.Error?) {
                            if (error != null) {
                                result.error("PERMISSION_ERROR", error.toString(), null)
                            } else {
                                result.success(granted)
                            }
                        }
                    }
                )
            } else {
                result.error("INVALID_ACTIVITY", "Activity is not a ComponentActivity: ${current?.let { it::class.java.simpleName } ?: "null"}", null)
            }
        } catch (e: Exception) {
            result.error("PERMISSION_REQUEST_FAILED", e.message ?: "Unknown error", null)
        }
    }

    private fun subscribe(result: Result) {
        try {
            val current = activity
            if (current is ComponentActivity) {
                PushEngage.subscribe(
                    current,
                    object : PushEngageResponseCallback {
                        override fun onSuccess(responseObject: Any?) {
                            result.success(responseObject)
                        }

                        override fun onFailure(errorCode: Int?, errorMessage: String?) {
                            result.error("SUBSCRIBE_ERROR", errorMessage ?: "Failed to subscribe", errorCode)
                        }
                    }
                )
            } else {
                result.error("INVALID_ACTIVITY", "Activity is not a ComponentActivity: ${current?.let { it::class.java.simpleName } ?: "null"}", null)
            }
        } catch (e: Exception) {
            result.error("SUBSCRIBE_ERROR", "Failed to subscribe: ${e.message}", null)
        }
    }

    private fun addAlert(map: Map<String, Any>, result: Result) {
        val typeString = map["type"] as? String
        val productId = map["productId"] as? String
        val link = map["link"] as? String
        val price = (map["price"] as? Number)?.toDouble()
        if (typeString == null || productId == null || link == null || price == null) {
            result.error(
                    "INVALID_ARGUMENT",
                    "addAlert requires non-null type, productId, link, and price",
                    null)
            return
        }

        val expiryTimestampDate: java.util.Date? =
                try {
                    (map["expiryTimestamp"] as? String)?.let { ts ->
                        SimpleDateFormat(
                                        "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
                                        Locale.US
                                )
                                .apply { isLenient = false }
                                .parse(ts)
                    }
                } catch (e: java.text.ParseException) {
                    result.error(
                            "INVALID_ARGUMENT",
                            "expiryTimestamp must be ISO-8601 with millisecond precision: ${e.message}",
                            null)
                    return
                }

        val availability: PushEngage.TriggerAlertAvailabilityType? =
                try {
                    (map["availability"] as? String)?.let {
                        PushEngage.TriggerAlertAvailabilityType.valueOf(it)
                    }
                } catch (e: IllegalArgumentException) {
                    result.error(
                            "INVALID_ARGUMENT",
                            "Unknown availability value: ${e.message}",
                            null)
                    return
                }

        val alert =
                TriggerAlert(
                        type = getAlertType(typeString),
                        productId = productId,
                        link = link,
                        price = price,
                        variantId = map["variantId"] as? String,
                        expiryTimestamp = expiryTimestampDate,
                        alertPrice = (map["alertPrice"] as? Number)?.toDouble(),
                        availability = availability,
                        profileId = map["profileId"] as? String,
                        mrp = (map["mrp"] as? Number)?.toDouble(),
                        data = map["data"] as? Map<String, String>
                )

        PushEngage.addAlert(
                alert,
                object : PushEngageResponseCallback {
                    override fun onSuccess(responseObject: Any?) {
                        result.success("Alert added successfully")
                    }

                    override fun onFailure(errorCode: Int?, errorMessage: String?) {
                        result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                    }
                }
        )
    }

    private fun getAlertType(type: String): PushEngage.TriggerAlertType {
        if (type == "priceDrop") {
            return PushEngage.TriggerAlertType.priceDrop
        } else {
            return PushEngage.TriggerAlertType.inventory
        }
    }

    private fun sendTriggerEvent(triggerMap: Map<String, Any>?, result: Result) {
        if (triggerMap == null) {
            result.error("INVALID_ARGUMENT", "Missing trigger payload", null)
            return
        }
        val campaignName = triggerMap["campaignName"] as? String
        val eventName = triggerMap["eventName"] as? String
        if (campaignName.isNullOrEmpty() || eventName.isNullOrEmpty()) {
            result.error(
                    "INVALID_ARGUMENT",
                    "sendTriggerEvent requires non-empty campaignName and eventName",
                    null)
            return
        }
        val triggerCampaign =
                TriggerCampaign(
                        campaignName = campaignName,
                        eventName = eventName,
                        referenceId = triggerMap["referenceId"] as? String,
                        profileId = triggerMap["profileId"] as? String,
                        data = triggerMap["data"] as? Map<String, String>
                )
        PushEngage.sendTriggerEvent(
                triggerCampaign,
                object : PushEngageResponseCallback {
                    override fun onSuccess(responseObject: Any?) {
                        result.success("Trigger sent successfully")
                    }

                    override fun onFailure(errorCode: Int?, errorMessage: String?) {
                        result.error(errorCode?.toString() ?: "FAILURE", errorMessage ?: "Request failed", null)
                    }
                }
        )
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(intent)
        return false
    }

    /**
     * Result wrapper that marshals every reply to the platform (main) thread.
     * Native SDK callbacks (PushEngageResponseCallback, PushEngagePermissionCallback)
     * may fire on background queues; calling MethodChannel.Result methods off
     * the platform thread is undefined per the Flutter contract.
     */
    private class MainThreadResult(
            private val inner: Result,
            private val handler: Handler,
    ) : Result {
        override fun success(value: Any?) {
            if (Looper.myLooper() == Looper.getMainLooper()) inner.success(value)
            else handler.post { inner.success(value) }
        }

        override fun error(code: String, message: String?, details: Any?) {
            if (Looper.myLooper() == Looper.getMainLooper()) inner.error(code, message, details)
            else handler.post { inner.error(code, message, details) }
        }

        override fun notImplemented() {
            if (Looper.myLooper() == Looper.getMainLooper()) inner.notImplemented()
            else handler.post { inner.notImplemented() }
        }
    }
}


