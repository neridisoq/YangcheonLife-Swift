//AppDelegate.swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Check for app updates
        AppUpdateService.shared.checkForUpdates()
        
        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Permission granted: \(granted)")
            
            if granted {
                // 권한이 허용되면 로컬 알림 설정
                DispatchQueue.main.async {
                    if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
                        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
                        
                        // 시간표 데이터 가져오기 및 알림 설정
                        LocalNotificationManager.shared.fetchAndSaveSchedule(grade: grade, classNumber: classNumber)
                    }
                }
            }
        }
        
        return true
    }

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle background and closed app notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        completionHandler()
    }
    
    // Check for updates when app enters foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        AppUpdateService.shared.checkForUpdates()
    }
}
