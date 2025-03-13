import UIKit
import UserNotifications
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Check for app updates
        AppUpdateService.shared.checkForUpdates()
        
        // 위젯과 데이터 공유를 위한 UserDefaults 동기화
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        
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
                        
                        // ScheduleManager를 통한 시간표 데이터 가져오기 및 알림 설정
                        ScheduleManager.shared.fetchAndUpdateSchedule(grade: grade, classNumber: classNumber) { _ in
                            // 알림 설정 완료 후 처리 (필요시 구현)
                            
                            // 체육 수업 알림 설정
                            if UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled") {
                                PhysicalEducationAlertManager.shared.scheduleAlerts()
                            }
                            
                            // 위젯 타임라인 갱신
                            WidgetCenter.shared.reloadAllTimelines()
                        }
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
    
    // 앱 활성화 시 위젯 데이터 동기화
    // 위젯과 데이터 공유를 위한 UserDefaults 동기화
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 위젯 데이터 동기화
        print("🔄 앱 활성화: 위젯 데이터 동기화 시작")
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        SharedUserDefaults.shared.printAllValues()
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ 위젯 타임라인 리로드 요청 완료")
    }
}
