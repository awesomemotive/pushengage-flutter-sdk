import Flutter
import UIKit
import PushEngage

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override init() {
        super.init()
        PushEngage.swizzleInjection(isEnabled: true)
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOSApplicationExtension 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        GeneratedPluginRegistrant.register(with: self)
        PushEngage.setBadgeCount(count: 0)
        PushEngage.setNotificationWillShowInForegroundHandler { notification, completion in
            if notification.contentAvailable == 1 {
                // in case developer failed to set completion handler. After 25 sec handler will call.
                completion(nil)
            } else {
                completion(notification)
            }
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("HOST didRegisterForRemoteNotificationsWithDeviceToken is implemented device Token: -, \(deviceToken.description)")
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Token: \(token)")
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
//      Uncomment below line if swizzling is not used
//        PushEngage.registerDeviceToServer(with: deviceToken)
    }
    
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification callllllled")
//      Uncomment below line if swizzling is not used
//        PushEngage.receivedRemoteNotification(application: application, userInfo: userInfo, completionHandler: completionHandler)
    }
    
//    @available(iOSApplicationExtension 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("HOST implemented the notification didRecive notification.")
//      Uncomment below line if swizzling is not used
//        PushEngage.didReceiveRemoteNotification(with: response)
        completionHandler()
    }
    
}
