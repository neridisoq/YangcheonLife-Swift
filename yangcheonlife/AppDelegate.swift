import UIKit
import UserNotifications
import WidgetKit
import BackgroundTasks
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase 초기화 및 설정 (최우선으로 실행)
        print("🔥 AppDelegate에서 Firebase 초기화 시작")
        FirebaseService.shared.initialize()
        
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
        
        // 알림 권한 요청 및 설정 (NotificationService에서 이미 delegate 설정됨)
        // UNUserNotificationCenter.current().delegate = self
        _Concurrency.Task {
            let granted = await NotificationService.shared.requestAuthorization()
            print("📱 알림 권한: \(granted)")
            
            if granted {
                // 권한이 허용되면 알림 설정
                if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                    let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
                    let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
                    
                    // ScheduleService를 통한 시간표 데이터 가져오기 및 알림 설정
                    await ScheduleService.shared.loadSchedule(grade: grade, classNumber: classNumber)
                    
                    // Firebase 토픽 구독
                    if grade > 0 && classNumber > 0 {
                        FirebaseService.shared.subscribeToTopic(grade: grade, classNumber: classNumber)
                    }
                    
                    // Live Activity Wake 토픽 구독 (항상 구독)
                    FirebaseService.shared.subscribeToLiveActivityTopic { success in
                        if success {
                            print("✅ Live Activity 및 Wake 토픽 구독 완료")
                        } else {
                            print("❌ Live Activity 또는 Wake 토픽 구독 실패")
                        }
                    }
                    
                    // 체육 수업 알림 설정
                    if UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled") {
                        await NotificationService.shared.schedulePhysicalEducationAlerts()
                    }
                    
                    // 위젯 타임라인 갱신
                    WidgetCenter.shared.reloadAllTimelines()
                    
                    // Live Activity 상태 모니터링 시작
                    LiveActivityManager.shared.startActivityStateMonitoring()
                }
            }
        }
        
        // APNS 등록
        application.registerForRemoteNotifications()
        
        // 백그라운드 작업 등록
        registerBackgroundTasks()
        
        return true
    }
    
    // MARK: - App Lifecycle for Live Activity
    
    // Firebase 토픽 구독 해제 처리 - 별도의 메서드로 분리
    private func handleFirebaseUnsubscribe() {
        // 세마포어를 사용하여 완료될 때까지 대기 (별도 큐에서 실행 중이므로 안전)
        let semaphore = DispatchSemaphore(value: 0)
        
        print("🔄 Firebase 토픽 구독 해제 시작")
        FirebaseService.shared.unsubscribeFromAllTopics {
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
        let startTime = Date()
        print("🔄 [Background] Widget refresh task started at \(startTime)")
        print("🔄 [Background] App state: \(UIApplication.shared.applicationState.rawValue)")
        
        // 다음 백그라운드 작업 스케줄링 (먼저 예약)
        scheduleWidgetRefresh()
        
        // 작업 완료 플래그
        var isTaskCompleted = false
        
        // 위젯 데이터 업데이트 및 타임라인 갱신
        let updateTask = _Concurrency.Task {
            // 위젯 데이터 동기화
            SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
            print("🔄 [Background] UserDefaults synchronized")
            
            // Apple 정책 준수: 백그라운드에서 Live Activity 처리 제거
            // Live Activity는 앱이 포그라운드에서 교시 변화시에만 업데이트
            
            // 위젯 타임라인 갱신
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 [Background] Widget timelines reloaded")
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [Background] All tasks completed in \(String(format: "%.2f", duration))s")
            
            if !isTaskCompleted {
                isTaskCompleted = true
                task.setTaskCompleted(success: true)
            }
        }
        
        // 작업 완료 또는 제한 시간 도달 시 처리
        task.expirationHandler = {
            let duration = Date().timeIntervalSince(startTime)
            print("⚠️ [Background] Task expired after \(String(format: "%.2f", duration))s")
            updateTask.cancel()
            
            if !isTaskCompleted {
                isTaskCompleted = true
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    /// Apple 정책 준수: 백그라운드 Live Activity 처리 완전 제거
    /// Live Activity는 앱이 포그라운드에서 교시 변화시에만 업데이트
    private func performLiveActivityBackgroundUpdate() async {
        // 제거됨 - Apple 가이드라인 준수
        // 백그라운드에서 Live Activity 처리 금지
    }
    
    // 백그라운드 위젯 업데이트 작업 스케줄링
    func scheduleWidgetRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.helgisnw.yangcheonlife.widgetrefresh")
        
        // 학교 시간에 따른 스케줄링 간격 조정
        let isSchoolTime = TimeUtility.shouldLiveActivityBeRunning()
        let interval: TimeInterval = isSchoolTime ? 180 : 600  // 학교시간: 3분, 그외: 10분
        
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            let nextTime = Date(timeIntervalSinceNow: interval)
            print("📆 다음 백그라운드 작업 예약됨: \(nextTime) (간격: \(Int(interval/60))분)")
        } catch {
            print("❌ 백그라운드 작업 예약 실패: \(error)")
            
            // 실패시 재시도 (1분 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                self?.scheduleWidgetRefresh()
            }
        }
    }

    // 백그라운드 앱 갱신 처리
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔄 백그라운드 앱 갱신 시작: \(Date())")
        
        // 위젯 데이터 동기화
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        // 위젯 타임라인 갱신
        WidgetCenter.shared.reloadAllTimelines()
        // Apple 정책 준수: 백그라운드에서 Live Activity 업데이트 제거
        
        print("✅ 백그라운드 앱 갱신에서 위젯 타임라인 리로드 및 라이브 액티비티 업데이트 완료")
        completionHandler(.newData)
        
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }

    // MARK: - Remote Notifications (Firebase)
    
    /// APNS 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 APNS 등록 성공")
        print("📱 Device Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        
        // APNs 환경 확인
        #if DEBUG
        print("📱 APNs 환경: Development (DEBUG)")
        #else
        print("📱 APNs 환경: Production (RELEASE)")
        #endif
        
        Messaging.messaging().apnsToken = deviceToken
    }
    
    /// APNS 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNS 등록 실패: \(error)")
    }
    
    /// Firebase 원격 알림 수신 (백그라운드/종료 상태)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📩 Firebase 원격 알림 수신 (백그라운드/종료): \(userInfo)")
        print("📩 전체 userInfo 구조:")
        for (key, value) in userInfo {
            print("   \(key): \(value)")
        }
        
        // Firebase가 메시지를 처리하도록 함
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Live Activity 원격 제어 처리
        handleRemoteLiveActivityControl(userInfo: userInfo)
        
        // 라이브 액티비티 업데이트 (원격 알림으로 인한 업데이트)
        LiveActivityManager.shared.updateLiveActivity()
        
        completionHandler(.newData)
    }
    
    /// Live Activity 원격 제어 처리
    private func handleRemoteLiveActivityControl(userInfo: [AnyHashable: Any]) {
        // data 필드에서 메시지 타입 확인
        var messageType: String?
        if let data = userInfo["data"] as? [String: Any] {
            messageType = data["type"] as? String
        } else {
            messageType = userInfo["type"] as? String
        }
        
        guard let type = messageType else { 
            print("⚠️ 메시지 타입을 찾을 수 없음: \(userInfo)")
            return 
        }
        
        switch type {
        case "start_live_activity":
            FirebaseService.shared.handleRemoteLiveActivityStart(userInfo: userInfo)
        case "stop_live_activity":
            FirebaseService.shared.handleRemoteLiveActivityStop(userInfo: userInfo)
        case "wake_live_activity":
            handleWakeLiveActivity(userInfo: userInfo)
        default:
            print("⚠️ 알 수 없는 메시지 타입: \(type)")
        }
    }
    
    /// FCM으로 Live Activity 깨우기 처리
    private func handleWakeLiveActivity(userInfo: [AnyHashable: Any]) {
        let timestamp = Date()
        print("⏰ [FCM Wake] Live Activity 깨우기 신호 수신: \(timestamp)")
        
        // 백그라운드 상태에서도 동작하도록 비동기 처리
        _Concurrency.Task {
            await performFCMWakeActions()
        }
    }
    
    /// FCM 깨우기로 수행할 작업들
    private func performFCMWakeActions() async {
        print("⏰ [FCM Wake] Live Activity 상태 체크 및 업데이트 시작")
        
        let manager = LiveActivityManager.shared
        let isRunning = manager.isActivityRunning
        let shouldBeRunning = TimeUtility.shouldLiveActivityBeRunning()
        let hasValidSettings = UserDefaults.standard.integer(forKey: "defaultGrade") > 0
        
        print("⏰ [FCM Wake] 상태 확인:")
        print("   - Currently running: \(isRunning)")
        print("   - Should be running: \(shouldBeRunning)")
        print("   - Valid settings: \(hasValidSettings)")
        print("   - App state: \(UIApplication.shared.applicationState.rawValue)")
        
        if shouldBeRunning && hasValidSettings {
            if isRunning {
                // 실행 중이면 업데이트
                manager.updateLiveActivity()
                print("⏰ [FCM Wake] Live Activity 업데이트 완료")
            } else {
                // 실행 중이 아니면 시작
                let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
                let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
                print("⏰ [FCM Wake] Live Activity 시작 (Grade: \(grade), Class: \(classNumber))")
                manager.startLiveActivity(grade: grade, classNumber: classNumber)
                
                // 시작 후 상태 모니터링 활성화
                manager.startActivityStateMonitoring()
            }
        } else if isRunning && !shouldBeRunning {
            // 학교 시간이 아닌데 실행 중이면 종료
            print("⏰ [FCM Wake] Live Activity 종료 (학교 시간 외)")
            manager.stopLiveActivity()
        } else {
            print("⏰ [FCM Wake] 조건 불충족 - 작업 없음")
        }
        
        // Apple 정책 준수: Live Activity는 이벤트 기반으로만 업데이트
        
        // 위젯도 함께 업데이트
        WidgetCenter.shared.reloadAllTimelines()
        print("⏰ [FCM Wake] 모든 작업 완료")
    }
    
    // Check for updates when app enters foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 [AppDelegate] ✅ applicationWillEnterForeground 호출됨")
        AppUpdateService.shared.checkForUpdates()
        
        // Extension에서 저장한 대기 중인 Live Activity 시작 처리
        handlePendingLiveActivityStart()
        
        // Apple 정책 준수: 포그라운드에서만 Live Activity 상태 체크
        LiveActivityManager.shared.checkLiveActivityOnForeground()
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }
    
    // 앱 활성화 시 위젯 데이터 동기화
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 위젯 데이터 동기화
        print("📱 [AppDelegate] ✅ applicationDidBecomeActive 호출됨")
        print("🔄 앱 활성화: 위젯 데이터 동기화 시작")
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        SharedUserDefaults.shared.printAllValues()
        WidgetCenter.shared.reloadAllTimelines()
        
        // Extension에서 저장한 대기 중인 Live Activity 시작 처리
        handlePendingLiveActivityStart()
        
        // Apple 정책 준수: 포그라운드에서만 Live Activity 상태 체크
        LiveActivityManager.shared.checkLiveActivityOnForeground()
        print("✅ 위젯 타임라인 리로드 및 라이브 액티비티 업데이트 요청 완료")
        
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }
    
    // MARK: - Pending Live Activity 처리
    
    /// SwiftUI에서 호출하는 대기 중인 Live Activity 처리 (public)
    func handlePendingLiveActivityStartFromSwiftUI() {
        print("📱 [AppDelegate] SwiftUI에서 대기 중인 Live Activity 처리 요청")
        handlePendingLiveActivityStart()
    }
    
    /// Extension에서 저장한 대기 중인 Live Activity 시작 처리
    private func handlePendingLiveActivityStart() {
        print("📱 [AppDelegate] 대기 중인 Live Activity 확인 시작")
        
        let groupDefaults = UserDefaults(suiteName: "group.com.helgisnw.yangcheonlife")
        
        // App Group UserDefaults 강제 동기화
        groupDefaults?.synchronize()
        
        // App Group UserDefaults 전체 상태 확인
        print("📱 [AppDelegate] App Group UserDefaults 상태:")
        print("   - pendingLiveActivityStart: \(groupDefaults?.bool(forKey: "pendingLiveActivityStart") ?? false)")
        print("   - pendingLiveActivityGrade: \(groupDefaults?.integer(forKey: "pendingLiveActivityGrade") ?? -1)")
        print("   - pendingLiveActivityClass: \(groupDefaults?.integer(forKey: "pendingLiveActivityClass") ?? -1)")
        
        // 타임스탬프도 확인
        let timestamp = groupDefaults?.double(forKey: "pendingLiveActivityTimestamp") ?? 0
        if timestamp > 0 {
            print("   - pendingLiveActivityTimestamp: \(Date(timeIntervalSince1970: timestamp))")
        }
        
        let isPending = groupDefaults?.bool(forKey: "pendingLiveActivityStart") ?? false
        
        guard isPending else {
            print("📱 [AppDelegate] ❌ 대기 중인 Live Activity 없음")
            
            // Extension에서 저장했는데도 없다면 App Group 설정 문제일 수 있음
            print("📱 [AppDelegate] App Group 설정 확인:")
            print("   - App Group Suite Name: group.com.helgisnw.yangcheonlife")
            print("   - UserDefaults 객체: \(groupDefaults != nil ? "생성됨" : "nil")")
            
            // 혹시 다른 키들이 있는지 확인
            if let allKeys = groupDefaults?.dictionaryRepresentation().keys {
                print("   - 사용 가능한 모든 키: \(Array(allKeys))")
            }
            return
        }
        
        let grade = groupDefaults?.integer(forKey: "pendingLiveActivityGrade") ?? 0
        let classNumber = groupDefaults?.integer(forKey: "pendingLiveActivityClass") ?? 0
        
        print("📱 [AppDelegate] ✅ 대기 중인 Live Activity 발견!")
        print("📱 [AppDelegate] Extension에서 요청한 Live Activity 시작 처리: \(grade)학년 \(classNumber)반")
        print("📱 [AppDelegate] 요청 시간: \(Date(timeIntervalSince1970: timestamp))")
        
        // 플래그 초기화 (사용 전에 먼저 초기화)
        groupDefaults?.set(false, forKey: "pendingLiveActivityStart")
        groupDefaults?.removeObject(forKey: "pendingLiveActivityGrade")
        groupDefaults?.removeObject(forKey: "pendingLiveActivityClass")
        groupDefaults?.removeObject(forKey: "pendingLiveActivityTimestamp")
        groupDefaults?.synchronize()
        
        print("📱 [AppDelegate] 대기 플래그 초기화 완료")
        
        // Live Activity 시작 (약간의 지연 후 실행)
        if grade > 0 && classNumber > 0 {
            print("📱 [AppDelegate] Live Activity 시작 시도: \(grade)학년 \(classNumber)반")
            
            // 앱이 완전히 활성화될 때까지 0.3초 대기 후 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("📱 [AppDelegate] 지연 후 Live Activity 시작 실행")
                LiveActivityManager.shared.startLiveActivity(grade: grade, classNumber: classNumber)
                print("📱 [AppDelegate] ✅ Extension 요청으로 Live Activity 시작 완료: \(grade)학년 \(classNumber)반")
            }
        } else {
            print("📱 [AppDelegate] ❌ 유효하지 않은 학년/반 정보: \(grade)학년 \(classNumber)반")
        }
    }
    
    // 앱이 백그라운드로 이동할 때 호출
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 [AppDelegate] 앱이 백그라운드로 이동: \(Date())")
        
        // Live Activity 상태 보존 및 업데이트
        let manager = LiveActivityManager.shared
        let isRunning = manager.isActivityRunning
        let shouldBeRunning = TimeUtility.shouldLiveActivityBeRunning()
        
        print("📱 [Background Entry] Live Activity status:")
        print("   - Currently running: \(isRunning)")
        print("   - Should be running: \(shouldBeRunning)")
        
        if shouldBeRunning {
            if isRunning {
                // 백그라운드 진입 전 마지막 업데이트
                manager.updateLiveActivity()
                print("📱 [Background Entry] Live Activity updated before background")
            } else {
                // 학교 시간인데 Live Activity가 없으면 시작
                let hasValidSettings = UserDefaults.standard.integer(forKey: "defaultGrade") > 0
                if hasValidSettings {
                    let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
                    let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
                    print("📱 [Background Entry] Starting Live Activity before background")
                    manager.startLiveActivity(grade: grade, classNumber: classNumber)
                }
            }
        }
        
        // 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
        
        // 상태 모니터링 확인
        manager.startActivityStateMonitoring()
    }
}
