import UIKit
import Firebase
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Permission granted: \(granted)")
        }
        application.registerForRemoteNotifications()
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
    }

    func subscribeToTopic(grade: Int, classNumber: Int) {
        let topic = "\(grade)-\(classNumber)"
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Failed to subscribe to topic \(topic): \(error)")
            } else {
                print("Subscribed to topic \(topic)")
            }
        }
    }

    func unsubscribeFromTopic(grade: Int, classNumber: Int) {
        let topic = "\(grade)-\(classNumber)"
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Failed to unsubscribe from topic \(topic): \(error)")
            } else {
                print("Unsubscribed from topic \(topic)")
            }
        }
    }

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle background and closed app notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}
