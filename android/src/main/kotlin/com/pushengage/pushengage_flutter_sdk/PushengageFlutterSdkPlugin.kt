package com.pushengage.pushengage_flutter_sdk

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.pushengage.pushengage.Callbacks.PushEngageResponseCallback
import com.pushengage.pushengage.PushEngage
import com.pushengage.pushengage.model.request.AddDynamicSegmentRequest
import com.pushengage.pushengage.model.request.Goal
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
        PluginRegistry.RequestPermissionsResultListener,
        PluginRegistry.NewIntentListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activity: Activity
    private var permissionResult: Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "PushEngage")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val data = intent.data
        if (Intent.ACTION_VIEW == action && data != null) {
            val deepLink = data.toString()
            val additionalData = intent.extras?.get("data")
            channel.invokeMethod(
                    "onDeepLink",
                    mapOf("deepLink" to deepLink, "data" to additionalData)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "PushEngage#setAppId" -> {
                PushEngage.Builder()
                        .addContext(context)
                        .setAppId(call.argument<String>("appId").toString())
                        .build()

                result.success(null)
            }
            "PushEngage#getSdkVersion" -> {
                result.success(PushEngage.getSdkVersion())
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
                            override fun onSuccess(responseObject: Any) {
                                result.success(
                                        "Automated notification " +
                                                (if (status) "enabled" else "disabled") +
                                                " successfully"
                                )
                            }

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
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
                call.arguments<Map<String, Any>>()?.let { goalMap ->
                    val goalName = goalMap["name"] as? String
                    val goalCount = goalMap["count"] as? Int
                    val value = goalMap["value"] as? Double
                    val goal = Goal(goalName ?: "", goalCount, value)

                    PushEngage.sendGoal(
                            goal,
                            object : PushEngageResponseCallback {
                                override fun onSuccess(responseObject: Any) {
                                    result.success("Goal sent successfully")
                                }

                                override fun onFailure(errorCode: Int, errorMessage: String) {
                                    result.error(errorCode.toString(), errorMessage, null)
                                }
                            }
                    )
                }
            }
            "PushEngage#getSubscriberDetails" -> {
                val subscriberAttributes = call.argument<List<String>>("values")
                PushEngage.getSubscriberDetails(
                        subscriberAttributes,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                val jsonResponse =
                                        JSONObject(responseObject as Map<*, *>).toString()
                                result.success(jsonResponse)
                            }

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
                            }
                        }
                )
            }
            "PushEngage#requestNotificationPermission" -> {
                requestNotificationPermission(result)
            }
            "PushEngage#getSubscriberAttributes" -> {
                PushEngage.getSubscriberAttributes(
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                if (responseObject != null) {
                                    val jsonResponse = responseObject as Map<*, *>
                                    result.success(jsonResponse)
                                } else {
                                    result.success(mapOf<String, Any>())
                                }
                            }

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
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

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
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

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
                            }
                        }
                )
            }
            "PushEngage#addDynamicSegment" -> {
                val segmentsList = call.argument<List<Map<String, Any>>>("segments") ?: emptyList()
                val segments: MutableList<AddDynamicSegmentRequest.Segment> = ArrayList()
                segmentsList.forEach { map ->
                    val segment = AddDynamicSegmentRequest().Segment()
                    segment.name = map["name"] as String
                    segment.duration = (map["duration"] as Number).toLong()
                    segments.add(segment)
                }
                PushEngage.addDynamicSegment(
                        segments,
                        object : PushEngageResponseCallback {
                            override fun onSuccess(responseObject: Any?) {
                                result.success("Subscriber added to dynamic segment successfully")
                            }

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
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

                                override fun onFailure(errorCode: Int, errorMessage: String) {
                                    result.error(errorCode.toString(), errorMessage, null)
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

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
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

                            override fun onFailure(errorCode: Int, errorMessage: String) {
                                result.error(errorCode.toString(), errorMessage, null)
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

                                override fun onFailure(errorCode: Int, errorMessage: String) {
                                    result.error(errorCode.toString(), errorMessage, null)
                                }
                            }
                    )
                } catch (e: Exception) {
                    result.error(400.toString(), "Invalid input", null)
                }
            }
            "PushEngage#setSmallIconResource" -> {
                val resourceName = call.argument<String>("resourceName").toString()
                PushEngage.setSmallIconResource(resourceName)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
        handleIntent(activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {}

    private fun requestNotificationPermission(result: Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                            activity,
                            Manifest.permission.POST_NOTIFICATIONS
                    ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissionResult = result
                ActivityCompat.requestPermissions(
                        activity,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        100
                )
            } else {
                // Permission already granted
                result.success(true)
            }
        } else {
            // For versions below Android 13, notification permission is granted at install time.
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ): Boolean {
        when (requestCode) {
            100 -> { // The request code used in requestPermissions
                val isGranted =
                        grantResults.isNotEmpty() &&
                                grantResults[0] == PackageManager.PERMISSION_GRANTED
                permissionResult?.success(isGranted)
                PushEngage.subscribe()
                return true
            }
        }
        return false
    }

    private fun addAlert(map: Map<String, Any>, result: Result) {
        val alert =
                TriggerAlert(
                        type = getAlertType(map["type"] as String),
                        productId = map["productId"] as String,
                        link = map["link"] as String,
                        price = map["price"] as Double,
                        variantId = map["variantId"] as String?,
                        expiryTimestamp =
                                map["expiryTimestamp"]?.let {
                                    SimpleDateFormat(
                                                    "yyyy-MM-dd'T'HH:mm:ss.SSS",
                                                    Locale.getDefault()
                                            )
                                            .parse(it as String)
                                },
                        alertPrice = map["alertPrice"] as? Double,
                        availability =
                                (map["availability"] as? String)?.let {
                                    PushEngage.TriggerAlertAvailabilityType.valueOf(it)
                                },
                        profileId = map["profileId"] as? String,
                        mrp = map["mrp"] as? Double,
                        data = map["data"] as? Map<String, String>
                )

        PushEngage.addAlert(
                alert,
                object : PushEngageResponseCallback {
                    override fun onSuccess(responseObject: Any) {
                        result.success("Alert added successfully")
                    }

                    override fun onFailure(errorCode: Int, errorMessage: String) {
                        result.error(errorCode.toString(), errorMessage, null)
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
        val triggerCampaign =
                (triggerMap?.get("campaignName") as? String)?.let { campaignName ->
                    (triggerMap["eventName"] as? String)?.let { eventName ->
                        TriggerCampaign(
                                campaignName = campaignName,
                                eventName = eventName,
                                referenceId = triggerMap["referenceId"] as? String,
                                profileId = triggerMap["profileId"] as? String,
                                data = triggerMap["data"] as? Map<String, String>
                        )
                    }
                }
        PushEngage.sendTriggerEvent(
                triggerCampaign,
                object : PushEngageResponseCallback {
                    override fun onSuccess(responseObject: Any) {
                        result.success("Trigger sent successfully")
                    }

                    override fun onFailure(errorCode: Int, errorMessage: String) {
                        result.error(errorCode.toString(), errorMessage, null)
                    }
                }
        )
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(intent)
        return false
    }
}
