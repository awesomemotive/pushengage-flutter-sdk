import Flutter
import PushEngage
import UIKit

public class PushEngageFlutterSdkPlugin: NSObject,
    FlutterPlugin,
    FlutterApplicationLifeCycleDelegate, UNUserNotificationCenterDelegate
{
    static var channel: FlutterMethodChannel?
    // Cold-boot replay buffer — see MessageBuffer.swift.
    let buffer = MessageBuffer()
    public static func register(with registrar: FlutterPluginRegistrar) {
        self.channel = FlutterMethodChannel(
            name: "PushEngage", binaryMessenger: registrar.messenger())
        let instance = PushEngageFlutterSdkPlugin()
        guard let channel = PushEngageFlutterSdkPlugin.channel else { return }
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)

    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
    ) -> Bool {

        PushEngage.setInitialInfo(for: application, with: [:])

        // Tag the subscriber as a Flutter client. The version is set in setAppId.
        PushEngage.setPlatform(PEPlatform.flutterIOS)

        PushEngage.setNotificationOpenHandler { [weak self] (result) in
            let additionalData: [String: String]? = result.notification.additionalData
            //Deeplink - trigger
            let deeplink = result.notificationAction.actionID
            let arguments: [String: Any] = [
                "deepLink": deeplink as Any, "data": additionalData as Any,
            ]
            // Route through the buffer: cold-boot taps land in the initial slot
            // (drained by getInitialNotification); runtime taps fire onDeepLink.
            self?.buffer.deliver(arguments)
        }

        return true
    }

    //this is very important for background notifications - otherwise subscription happens everytime
    public func application(
        _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) -> Bool {
        completionHandler(.newData)
        return true
    }

    public func handle(_ call: FlutterMethodCall, result rawResult: @escaping FlutterResult) {
        // Most PushEngage iOS SDK completion handlers fire on the SDK's own
        // network queue. Calling FlutterResult off the main thread is
        // undefined per Flutter's contract. Wrap once here so every reply
        // path is automatically marshaled.
        let result: FlutterResult = { value in
            if Thread.isMainThread {
                rawResult(value)
            } else {
                DispatchQueue.main.async { rawResult(value) }
            }
        }
        switch call.method {
        case "PushEngage#setAppId":
            if let args = call.arguments as? [String: Any],
                let appId = args["appId"] as? String
            {
                // Set the version before setAppID so first-launch telemetry
                // is tagged correctly.
                if let sdkVersion = args["sdkVersion"] as? String {
                    PushEngage.setWrapperVersion(sdkVersion)
                }
                PushEngage.setAppID(id: appId)
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
            }

        case "PushEngage#setEnvironment":
            let env = (call.arguments as? [String: Any])?["environment"] as? String
            let pe: PEEnvironment =
                (env?.uppercased() == "STAGING" || env?.uppercased() == "STG")
                ? .staging : .production
            PushEngage.setEnvironment(environment: pe)
            result(nil)

        case "PushEngage#setBadgeCount":
            let count = (call.arguments as? [String: Any])?["count"] as? Int ?? 0
            PushEngage.setBadgeCount(count: count)
            result(nil)

        case "PushEngage#getDeviceTokenHash":
            result(nil)

        case "PushEngage#subscribe":
            PushEngage.subscribe { success, error in
                if let error = error {
                    result(
                        FlutterError(
                            code: "SUBSCRIBE_ERROR",
                            message: "Failed to subscribe",
                            details: error.localizedDescription))
                } else {
                    result(success)
                }
            }

        case "PushEngage#enableLogging":
            if let status = (call.arguments as? [String: Any])?["status"] as? Bool {
                PushEngage.enableLogging = status
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
            }
        case "PushEngage#automatedNotification":
            if let status = (call.arguments as? [String: Any])?["status"] as? Bool {
                PushEngage.automatedNotification(status: status ? .enabled : .disabled) {
                    response, error in
                    if response {
                        result(
                            "Automated notification " + (status ? "enabled" : "disabled")
                                + " successfully")
                    } else {
                        result(
                            FlutterError(
                                code: "FAILURE",
                                message: "Automated notification "
                                    + (status ? "enable" : "disable") + " failed",
                                details: nil))
                    }
                }
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
            }
        case "PushEngage#sendTriggerEvent":
            if let triggerMap = call.arguments as? [String: Any] {
                handleSendTriggerEvent(args: triggerMap, result: result)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
            }
        case "PushEngage#sendGoal":
            if let args = call.arguments as? [String: Any] {
                self.handleSendGoal(args: args, result: result)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
            }
        case "PushEngage#addAlert":
            if let alertMap = call.arguments as? [String: Any] {
                handleAddAlert(args: alertMap, result: result)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
            }
        case "PushEngage#getSubscriberDetails":
            guard let args = call.arguments as? [String: Any] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }
            // A null/missing list requests the complete record.
            let values = args["values"] as? [String]
            self.getSubscriberDetails(values: values, result: result)
        case "PushEngage#requestNotificationPermission":
            requestNotificationPermission(result: result)
        case "PushEngage#getNotificationPermissionStatus":
            let status = PushEngage.getNotificationPermissionStatus()
            result(status)
        case "PushEngage#getSubscriptionStatus":
            PushEngage.getSubscriptionStatus { isSubscribed, error in
                if let error = error {
                    result(
                        FlutterError(
                            code: "SUBSCRIPTION_STATUS_ERROR",
                            message: "Failed to get subscription status",
                            details: error.localizedDescription))
                } else {
                    result(isSubscribed)
                }
            }
        case "PushEngage#getSubscriptionNotificationStatus":
            PushEngage.getSubscriptionNotificationStatus { canReceiveNotifications, error in
                if let error = error {
                    result(
                        FlutterError(
                            code: "SUBSCRIPTION_NOTIFICATION_STATUS_ERROR",
                            message: "Failed to get subscription notification status",
                            details: error.localizedDescription))
                } else {
                    result(canReceiveNotifications)
                }
            }
        case "PushEngage#unsubscribe":
            PushEngage.unsubscribe { success, error in
                if let error = error {
                    result(
                        FlutterError(
                            code: "UNSUBSCRIBE_ERROR",
                            message: "Failed to unsubscribe",
                            details: error.localizedDescription))
                } else {
                    result(success)
                }
            }
        case "PushEngage#getSubscriberId":
            PushEngage.getSubscriberId { subscriberId in
                result(subscriberId)
            }
        case "PushEngage#getSubscriberAttributes":
            PushEngage.getSubscriberAttributes { info, error in
                if let info {
                    result(info)
                } else if error == nil {
                    // No attributes on the subscriber — mirror Android's
                    // empty-map success instead of failing.
                    result([String: Any]())
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed to retrieve subscriber attributes",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#addSegment":
            guard let args = call.arguments as? [String: Any],
                let segments = args["segments"] as? [String]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }
            PushEngage.addSegments(segments) { response, error in
                if response {
                    result("Subscriber added to segment(s) successfully")
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed to add subscriber to segment",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#removeSegment":
            guard let args = call.arguments as? [String: Any],
                let segments = args["segments"] as? [String]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }
            PushEngage.removeSegments(segments) { response, error in
                if response {
                    result("Subscriber removed from segment(s) successfully")
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed to remove subscriber from segment(s)",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#addDynamicSegment":
            guard let args = call.arguments as? [String: Any],
                let segments = args["segments"] as? [[String: Any]]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }
            PushEngage.addDynamicSegments(segments) { response, error in
                if response {
                    result("Subscriber added to dynamic segment successfully")
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE",
                            message: "Failed to add subscriber to dynamic segment(s)",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#addSubscriberAttributes":
            guard let args = call.arguments as? [String: Any],
                let attributesJsonString = args["attributes"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }
            PushEngage.add(attributes: jsonStringToDictionary(attributesJsonString) ?? [:]) {
                response, error in
                if response {
                    result("Subscriber attribute(s) added successfully")
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed to add subscriber attribute(s)",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#deleteSubscriberAttributes":
            guard let args = call.arguments as? [String: Any],
                let attributes = args["attributes"] as? [String]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }
            PushEngage.deleteSubscriberAttributes(for: attributes) { response, error in
                if response {
                    result("Subscriber attribute(s) deleted successfully")
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed to delete subscriber attribute(s)",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#addProfileId":
            guard let args = call.arguments as? [String: Any],
                let profileId = args["profileId"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }

            PushEngage.addProfile(for: profileId) { response, error in
                if response {
                    result("Profile Id added successfully")
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed to add profile Id",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#setSubscriberAttributes":
            guard let args = call.arguments as? [String: Any],
                let attributesJsonString = args["attributes"] as? String,
                let attributesDictionary = self.jsonStringToDictionary(attributesJsonString)
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing required arguments",
                        details: nil))
                return
            }

            PushEngage.set(attributes: attributesDictionary) { response, error in
                if response {
                    result("Subscriber attribute(s) set successfully")
                } else {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed to set subscriber attribute(s)",
                            details: error?.localizedDescription))
                }
            }
        case "PushEngage#identify":
            guard let json = (call.arguments as? [String: Any])?["fields"] as? String,
                let fields = jsonStringToDictionary(json)
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing fields", details: nil))
                return
            }
            PushEngage.identify(fields: fields) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(
                            FlutterError(
                                code: "IDENTIFY_ERROR", message: error.localizedDescription,
                                details: nil))
                    } else if success {
                        result("Identify successful")
                    } else {
                        result(
                            FlutterError(
                                code: "IDENTIFY_FAILED", message: "Identify failed",
                                details: nil))
                    }
                }
            }

        case "PushEngage#trackEvent":
            guard let event = call.arguments as? [String: Any],
                let eventName = event["eventName"] as? String, !eventName.isEmpty
            else {
                result(
                    FlutterError(
                        code: "MISSING_ARGUMENTS", message: "Missing required eventName",
                        details: nil))
                return
            }
            let properties = event["data"] as? [String: Any]
            let profileId = event["profileId"] as? String
            let provider = event["provider"] as? String
            let eventType = event["eventType"] as? String
            PushEngage.trackEvent(
                name: eventName, properties: properties, profileId: profileId,
                provider: provider, eventType: eventType
            ) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(
                            FlutterError(
                                code: "TRACK_EVENT_ERROR", message: error.localizedDescription,
                                details: nil))
                    } else if success {
                        result("Track event successful")
                    } else {
                        result(
                            FlutterError(
                                code: "TRACK_EVENT_FAILED", message: "Track event failed",
                                details: nil))
                    }
                }
            }

        case "PushEngage#logout":
            let names = (call.arguments as? [String: Any])?["fieldNames"] as? [String]
            PushEngage.logout(fieldNames: names) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(
                            FlutterError(
                                code: "LOGOUT_ERROR", message: error.localizedDescription,
                                details: nil))
                    } else if success {
                        result("Logout successful")
                    } else {
                        result(
                            FlutterError(
                                code: "LOGOUT_FAILED", message: "Logout failed", details: nil))
                    }
                }
            }

        case "PushEngage#runConfigValidation":
            // iOS has no FCM config surface; resolve true so shared Dart code
            // can call this without a platform guard.
            result(true)

        case "PushEngage#getInitialNotification":
            result(buffer.consumeInitialNotification())
        case "PushEngage#attachListeners":
            // Dart is ready: route runtime taps through onDeepLink and flush
            // any queued pre-readiness deliveries. The cold-boot slot is left
            // untouched (drained separately via getInitialNotification).
            buffer.setCallback { args in
                DispatchQueue.main.async {
                    PushEngageFlutterSdkPlugin.channel?.invokeMethod(
                        "onDeepLink", arguments: args)
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func jsonStringToDictionary(_ jsonString: String) -> [String: Any]? {
        if let data = jsonString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: [])
                    as? [String: Any]
                {
                    return json
                }
            } catch {
                if PushEngage.enableLogging {
                    print(
                        "Error converting JSON string to dictionary: \(error.localizedDescription)")
                }
            }
        }
        return nil
    }

    private func getSubscriberDetails(values: [String]?, result: @escaping FlutterResult) {
        // A nil response means the user is not subscribed; surface as a failure.
        PushEngage.getSubscriberDetails(for: values) { response, error in
            if let value = response {
                // PushEngage iOS SDK 1.0.0: SubscriberDetailsData exposes the
                // server fields via `rawFields` ([String: Any], snake_case keys)
                // and is no longer Encodable — serialize the dictionary directly.
                do {
                    let jsonData = try JSONSerialization.data(
                        withJSONObject: value.rawFields, options: [])
                    result(String(data: jsonData, encoding: .utf8))
                } catch {
                    result(
                        FlutterError(
                            code: "FAILURE", message: "Failed decoding subscriber details",
                            details: nil))
                }
            } else {
                result(
                    FlutterError(
                        code: "FAILURE", message: "Failed retrieving subscriber details",
                        details: error?.localizedDescription))
            }
        }
    }

    private func handleSendTriggerEvent(args: [String: Any], result: @escaping FlutterResult) {
        guard let campaignName = args["campaignName"] as? String,
            let eventName = args["eventName"] as? String
        else {
            result(
                FlutterError(
                    code: "MISSING_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }

        let referenceId = args["referenceId"] as? String
        let profileId = args["profileId"] as? String
        let data = args["data"] as? [String: String]

        let trigger = TriggerCampaign(
            campaignName: campaignName,
            eventName: eventName,
            referenceId: referenceId,
            profileId: profileId,
            data: data)

        PushEngage.sendTriggerEvent(triggerCampaign: trigger) { response, error in
            if response {
                result("Trigger sent successfully")
            } else {
                result(
                    FlutterError(code: "FAILURE", message: "Trigger sending failed", details: nil))
            }
        }
    }

    private func handleSendGoal(args: [String: Any], result: @escaping FlutterResult) {
        guard let name = args["name"] as? String else {
            result(
                FlutterError(
                    code: "MISSING_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }

        let count = args["count"] as? Int
        let value = args["value"] as? Double

        let goal = Goal(name: name, count: count, value: value)

        PushEngage.sendGoal(goal: goal) { response, error in
            if response {
                result("Goal sent successfully")
            } else {
                result(FlutterError(code: "FAILURE", message: "Goal sending failed", details: nil))
            }
        }
    }

    private func handleAddAlert(args: [String: Any], result: @escaping FlutterResult) {

        guard let typeString = args["type"] as? String,
            let productId = args["productId"] as? String,
            let link = args["link"] as? String,
            let price = (args["price"] as? Double) ?? (args["price"] as? Int).map(Double.init)
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENT",
                    message: "Missing or invalid required arguments for addAlert",
                    details: nil))
            return
        }
        var expiryTimestampDate: Date?
        if let expiryTimestamp = args["expiryTimestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            expiryTimestampDate = formatter.date(from: expiryTimestamp)
        }
        var availability: TriggerAlertAvailabilityType?
        if let availabilityString = args["availability"] as? String {
            if availabilityString == "inStock" {
                availability = .inStock
            } else if availabilityString == "outOfStock" {
                availability = .outOfStock
            }
        }

        let triggerAlert = TriggerAlert(
            type: (typeString == "priceDrop")
                ? TriggerAlertType.priceDrop : TriggerAlertType.inventory,
            productId: productId,
            link: link,
            price: price,
            variantId: args["variantId"] as? String,
            expiryTimestamp: expiryTimestampDate,
            alertPrice: args["alertPrice"] as? Double,
            availability: availability,
            profileId: args["profileId"] as? String,
            mrp: args["mrp"] as? Double,
            data: args["data"] as? [String: String])

        PushEngage.addAlert(triggerAlert: triggerAlert) { response, error in
            if response {
                result("Alert added successfully")
            } else {
                result(
                    FlutterError(
                        code: "FAILURE", message: "Alert sending failed",
                        details: error?.localizedDescription))
            }
        }
    }

    private func requestNotificationPermission(result: @escaping FlutterResult) {
        PushEngage.requestNotificationPermission { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(
                        FlutterError(
                            code: "PERMISSION_ERROR",
                            message: "Failed to request notification permission",
                            details: error.localizedDescription))
                } else {
                    result(granted)
                }
            }
        }
    }
}
