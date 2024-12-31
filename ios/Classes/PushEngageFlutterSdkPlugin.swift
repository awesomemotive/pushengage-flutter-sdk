import Flutter
import UIKit
import PushEngage

public class PushEngageFlutterSdkPlugin: NSObject,
                                         FlutterPlugin,
                                         FlutterApplicationLifeCycleDelegate, UNUserNotificationCenterDelegate {
    static var channel: FlutterMethodChannel?
    public static func register(with registrar: FlutterPluginRegistrar) {
        self.channel = FlutterMethodChannel(name: "PushEngage", binaryMessenger: registrar.messenger())
        let instance = PushEngageFlutterSdkPlugin()
        guard let channel = PushEngageFlutterSdkPlugin.channel else { return }
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        
        PushEngage.setInitialInfo(for: application, with: [:])
        
        PushEngage.setNotificationOpenHandler { (result) in
            let additionalData: [String: String]? = result.notification.additionalData
            //Deeplink - trigger
            let deeplink = result.notificationAction.actionID
            let arguments: [String: Any] = ["deepLink": deeplink as Any, "data": additionalData as Any]
            PushEngageFlutterSdkPlugin.channel?.invokeMethod("onDeepLink", arguments: arguments)
        }
        
        return true
    }
    
    //this is very important for background notifications - otherwise subscription happens everytime
    public func application( _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
      fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool
    {
        completionHandler(.newData)
        return true
     }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "PushEngage#setAppId":
            if let args = call.arguments as? [String: Any],
               let appId = args["appId"] as? String {
                PushEngage.setAppID(id: appId)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
            }
            
        case "PushEngage#getDeviceTokenHash":
            result(nil)
            
        case "PushEngage#subscribe":
            result(nil)
            
        case "PushEngage#enableLogging":
            if let status = (call.arguments as? [String: Any])?["status"] as? Bool {
                PushEngage.enableLogging = status
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
            }
        case "PushEngage#automatedNotification":
            if let status = (call.arguments as? [String: Any])?["status"] as? Bool {
                PushEngage.automatedNotification(status: status ? .enabled : .disabled) { response, error in
                    if response {
                        result("Automated notification " + (status ? "enabled" : "disabled") + " successfully")
                    } else {
                        result(FlutterError(code: "FAILURE", message: "Trigger enabled failed", details: nil))
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
            }
        case "PushEngage#sendTriggerEvent":
            if let triggerMap = call.arguments as? [String: Any] {
                handleSendTriggerEvent(args: triggerMap, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
            }
        case "PushEngage#sendGoal":
            if let args = call.arguments as? [String: Any] {
                self.handleSendGoal(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
            }
        case "PushEngage#addAlert":
            if let alertMap = call.arguments as? [String: Any] {
                handleAddAlert(args: alertMap, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
            }
        case "PushEngage#getSubscriberDetails":
            guard let args = call.arguments as? [String: Any],
                  let values = args["values"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
                return
            }
            self.getSubscriberDetails(values: values, result: result)
        case "PushEngage#requestNotificationPermission":
            PushEngage.requestNotificationPermission()
            result(nil)
        case "PushEngage#getSubscriberAttributes":
            PushEngage.getSubscriberAttributes { info, error in
                if let info {
                    result(info)
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to retrieve subscriber attributes", details: error?.localizedDescription))
                }
            }
        case "PushEngage#addSegment":
            guard let args = call.arguments as? [String: Any],
                  let segments = args["segments"] as? [String] else {
              result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
              return
            }
            PushEngage.addSegments(segments) { response, error in
                if response {
                    result("Subscriber added to segment(s) successfully")
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to add subscriber to segment", details: error?.localizedDescription))
                }
            }
        case "PushEngage#removeSegment":
            guard let args = call.arguments as? [String: Any],
                  let segments = args["segments"] as? [String] else {
              result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
              return
            }
            PushEngage.removeSegments(segments) { response, error in
                if response {
                    result("Subscriber removed from segment(s) successfully")
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to remove subscriber from segment(s)", details: error?.localizedDescription))
                }
            }
        case "PushEngage#addDynamicSegment":
            guard let args = call.arguments as? [String: Any],
                  let segments = args["segments"] as? [[String: Any]] else {
              result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
              return
            }
            PushEngage.addDynamicSegments(segments) { response, error in
                if response {
                    result("Subscriber added to dynamic segment successfully")
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to add subscriber to dynamic segment(s)", details: error?.localizedDescription))
                }
            }
        case "PushEngage#addSubscriberAttributes":
            guard let args = call.arguments as? [String: Any],
                  let attributesJsonString = args["attributes"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
                return
            }
            PushEngage.add(attributes: jsonStringToDictionary(attributesJsonString) ?? [:]) { response, error in
                if response {
                    result("Subscriber attribute(s) added successfully")
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to add subscriber attribute(s)", details: error?.localizedDescription))
                }
            }
        case "PushEngage#deleteSubscriberAttributes":
            guard let args = call.arguments as? [String: Any],
                  let attributes = args["attributes"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
                return
            }
            PushEngage.deleteSubscriberAttributes(for: attributes) { response, error in
                if response {
                    result("Subscriber attribute(s) deleted successfully")
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to delete subscriber attribute(s)", details: error?.localizedDescription))
                }
            }
        case "PushEngage#addProfileId":
            guard let args = call.arguments as? [String: Any],
                  let profileId = args["profileId"] as? String else {
              result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
              return
            }
            
            PushEngage.addProfile(for: profileId) { response, error in
                if response {
                    result("Profile Id added successfully")
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to add profile Id", details: error?.localizedDescription))
                }
            }
        case "PushEngage#setSubscriberAttributes":
            guard let args = call.arguments as? [String: Any],
                  let attributesJsonString = args["attributes"] as? String,
                  let attributesDictionary = self.jsonStringToDictionary(attributesJsonString) else {
                      result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
                      return
                    }
            
            PushEngage.set(attributes: attributesDictionary) { response, error in
                if response {
                    result("Subscriber attribute(s) set successfully")
                } else {
                    result(FlutterError(code: "FAILURE", message: "Failed to set subscriber attribute(s)", details: error?.localizedDescription))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func jsonStringToDictionary(_ jsonString: String) -> [String: Any]? {
        if let data = jsonString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    return json
                }
            } catch {
                print("Error converting JSON string to dictionary: \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    private func getSubscriberDetails(values: [String], result: @escaping FlutterResult) {
        PushEngage.getSubscriberDetails(for: values) { response, error in
            if let value = response {

                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                do {
                    let jsonData = try encoder.encode(value)
                    result(String(data: jsonData, encoding: .utf8))
                } catch {
                    result(FlutterError(code: "FAILURE", message: "Failed decoding subscriber details", details: nil))
                }
            } else {
                result(FlutterError(code: "FAILURE", message: "Failed retrieving subscriber details", details: error?.localizedDescription))
            }
        }
    }
    
    private func handleSendTriggerEvent(args: [String: Any], result: @escaping FlutterResult) {
        guard let campaignName = args["campaignName"] as? String,
              let eventName = args["eventName"] as? String else {
            result(FlutterError(code: "MISSING_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }
        
        let referenceId = args["referenceId"] as? String
        let profileId = args["profileId"] as? String
        let data = args["data"] as? [String: String]
        
        let trigger = TriggerCampaign(campaignName: campaignName,
                                      eventName: eventName,
                                      referenceId: referenceId,
                                      profileId: profileId,
                                      data: data)
        
        PushEngage.sendTriggerEvent(triggerCampaign: trigger) { response, error in
            if response {
                result("Trigger sent successfully")
            } else {
                result(FlutterError(code: "FAILURE", message: "Trigger sending failed", details: nil))
            }
        }
    }
    
    private func handleSendGoal(args: [String: Any], result: @escaping FlutterResult) {
        guard let name = args["name"] as? String else {
            result(FlutterError(code: "MISSING_ARGUMENTS", message: "Missing required arguments", details: nil))
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
              let price = args["price"] as? Double else {
            return
        }
        var expiryTimestampDate: Date?
        if let expiryTimestamp = args["expiryTimestamp"] as? String {
            expiryTimestampDate = ISO8601DateFormatter().date(from: expiryTimestamp)
        }
        var availability: TriggerAlertAvailabilityType?
        if let availabilityString = args["availability"] as? String {
            if availabilityString == "inStock" {
                availability = .inStock
            } else if availabilityString == "outOfStock" {
                availability = .outOfStock
            }
        }
        
        let triggerAlert = TriggerAlert(type: (typeString == "priceDrop") ? TriggerAlertType.priceDrop : TriggerAlertType.inventory,
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
                result(FlutterError(code: "FAILURE", message: "Alert sending failed", details: error?.localizedDescription))
            }
        }
    }
}

