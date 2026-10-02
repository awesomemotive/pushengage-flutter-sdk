import Flutter
import UIKit
import PushEngage

// The app uses the UIScene life cycle (required for apps built with the
// iOS 27 SDK): Info.plist's UIApplicationSceneManifest hands the window to
// Flutter's FlutterSceneDelegate, which loads Main.storyboard. The
// FlutterViewController therefore doesn't exist yet in didFinishLaunching,
// so plugins are registered through `pluginRegistrant` when the storyboard
// instantiates it. `pluginRegistrant` and FlutterSceneDelegate need Flutter
// 3.35 or later.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {

    override init() {
        super.init()
        PushEngage.swizzleInjection(isEnabled: true)
    }

    func register(with registry: FlutterPluginRegistry) {
        GeneratedPluginRegistrant.register(with: registry)
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOSApplicationExtension 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        pluginRegistrant = self
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
