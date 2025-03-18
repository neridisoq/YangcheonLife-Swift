import UIKit
import UserNotifications
import WidgetKit
import BackgroundTasks
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase 토픽 구독 해제 처리를 별도의 큐에서 실행
        let firebaseQueue = DispatchQueue(label: "com.helgisnw.yangcheonlife.firebaseQueue", qos: .utility)
        firebaseQueue.async {
            // 별도의 큐에서 실행하여 메인 스레드 블로킹 방지
            self.handleFirebaseUnsubscribe()
        }
        
        // Check for app updates
        AppUpdateService.shared.checkForUpdates()
        
        // 위젯과 데이터 공유를 위한 UserDefaults 동기화
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        
        // 백그라운드 앱 갱신 활성화
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
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
        
        // 백그라운드 작업 등록
        registerBackgroundTasks()
        
        return true
    }
    
    // Firebase 토픽 구독 해제 처리 - 별도의 메서드로 분리
    private func handleFirebaseUnsubscribe() {
        // 세마포어를 사용하여 완료될 때까지 대기 (별도 큐에서 실행 중이므로 안전)
        let semaphore = DispatchSemaphore(value: 0)
        
        print("🔄 Firebase 토픽 구독 해제 시작")
        FirebaseManager.shared.unsubscribeFromAllTopics {
            print("✅ Firebase 토픽 구독 해제 완료됨")
            semaphore.signal()
        }
        
        // 최대 10초 대기 (타임아웃 설정)
        _ = semaphore.wait(timeout: .now() + 10)
    }
    
    // 백그라운드 작업 등록
    private func registerBackgroundTasks() {
        // 백그라운드 위젯 업데이트 작업 등록
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.helgisnw.yangcheonlife.widgetrefresh", using: nil) { task in
            self.handleWidgetRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    // 백그라운드 위젯 업데이트 작업 처리
    private func handleWidgetRefresh(task: BGAppRefreshTask) {
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
        
        // 위젯 데이터 업데이트 및 타임라인 갱신
        let updateTask = Task {
            // 위젯 데이터 동기화
            SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
            // 위젯 타임라인 갱신
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ 백그라운드에서 위젯 타임라인 리로드 완료: \(Date())")
        }
        
        // 작업 완료 또는 제한 시간 도달 시 처리
        task.expirationHandler = {
            updateTask.cancel()
        }
        
        // 작업 완료 시 호출
        Task {
            await updateTask.value
            task.setTaskCompleted(success: true)
        }
    }
    
    // 백그라운드 위젯 업데이트 작업 스케줄링
    func scheduleWidgetRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.helgisnw.yangcheonlife.widgetrefresh")
        // 60초 후에 실행 (최소 시간임, 실제로는 iOS가 적절한 시점에 실행)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📆 다음 백그라운드 위젯 업데이트 작업 예약됨")
        } catch {
            print("❌ 백그라운드 작업 예약 실패: \(error)")
        }
    }

    // 백그라운드 앱 갱신 처리
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔄 백그라운드 앱 갱신 시작: \(Date())")
        
        // 위젯 데이터 동기화
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        // 위젯 타임라인 갱신
        WidgetCenter.shared.reloadAllTimelines()
        
        print("✅ 백그라운드 앱 갱신에서 위젯 타임라인 리로드 완료")
        completionHandler(.newData)
        
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
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
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }
    
    // 앱 활성화 시 위젯 데이터 동기화
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 위젯 데이터 동기화
        print("🔄 앱 활성화: 위젯 데이터 동기화 시작")
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        SharedUserDefaults.shared.printAllValues()
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ 위젯 타임라인 리로드 요청 완료")
        
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }
    
    // 앱이 백그라운드로 이동할 때 호출
    func applicationDidEnterBackground(_ application: UIApplication) {
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }
}
