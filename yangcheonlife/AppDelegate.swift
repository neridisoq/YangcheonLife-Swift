import UIKit
import UserNotifications
import WidgetKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Check for app updates
        AppUpdateService.shared.checkForUpdates()
        
        // Firebase 초기화
        FirebaseService.shared.initialize()
        
        // 알림 센터 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 위젯과 데이터 공유를 위한 UserDefaults 동기화
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        
        // 알림 권한 요청 및 설정
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            print("📱 알림 권한: \(granted)")
            
            if granted {
                // 원격 알림 등록 (Live Activity 푸시를 위해 필요)
                await MainActor.run {
                    application.registerForRemoteNotifications()
                    print("📡 [APNs] 원격 알림 등록 요청")
                }
                
                // 권한이 허용되면 알림 설정
                if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                    let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
                    let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
                    
                    // ScheduleService를 통한 시간표 데이터 가져오기 및 알림 설정
                    await ScheduleService.shared.loadSchedule(grade: grade, classNumber: classNumber)
                    
                    // 체육 수업 알림 설정
                    if UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled") {
                        await NotificationService.shared.schedulePhysicalEducationAlerts()
                    }
                    
                    // 위젯 타임라인 갱신
                    WidgetCenter.shared.reloadAllTimelines()
                    
                }
            }
        }
        
        // 백그라운드 작업 등록
        registerBackgroundTasks()
        
        return true
    }
    
    // MARK: - App Lifecycle for Live Activity
    
    
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
            
            // 10분마다 강제 Live Activity 업데이트
            if #available(iOS 18.0, *) {
                await performBackgroundLiveActivityUpdate()
            }
            
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
    
    // MARK: - iOS 18+ Live Activity Push Notification 처리
    
    /// iOS 18+ Live Activity APNs 원격 알림 수신 처리
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("📡 [APNs] iOS 18+ Live Activity notification received: \(userInfo)")
        
        // iOS 18+ Live Activity 전용 처리
        if #available(iOS 18.0, *) {
            handleLiveActivityPushNotification(userInfo: userInfo) {
                completionHandler(.newData)
            }
        } else {
            print("❌ [APNs] iOS 18.0+ required for Live Activity push notifications")
            completionHandler(.noData)
        }
    }
    
    /// iOS 18+ Live Activity Push 알림 처리 (포그라운드 전용)
    @available(iOS 18.0, *)
    private func handleLiveActivityPushNotification(userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        Task {
            // APNs 페이로드에서 애플 공식 event 확인
            let apsDict = userInfo["aps"] as? [String: Any]
            let event = apsDict?["event"] as? String
            
            print("📡 [LiveActivityPush] Apple standard event: \(event ?? "unknown")")
            print("📡 [LiveActivityPush] 🔄 포그라운드 상태 - 기존 로직으로 처리")
            
            guard #available(iOS 18.0, *) else {
                print("📡 [LiveActivityPush] iOS 18.0 이상이 필요합니다.")
                completion()
                return
            }
            
            let manager = LiveActivityManager.shared
            
            switch event {
            case "start":
                // 포그라운드: 기존 로직으로 시작
                print("🚀 [LiveActivityPush] Foreground start - using existing logic")
                let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
                let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
                if grade > 0 && classNumber > 0 {
                    await MainActor.run {
                        manager.startLiveActivity(grade: grade, classNumber: classNumber)
                    }
                }
                
            case "update":
                // 포그라운드: 기존 로직으로 새로고침 (Extension에서 이미 백그라운드 업데이트 완료)
                print("🔄 [LiveActivityPush] Foreground update - using existing logic refresh")
                await MainActor.run {
                    manager.updateLiveActivity()
                }
                
            case "end":
                // 포그라운드: 기존 로직으로 종료
                print("🛑 [LiveActivityPush] Foreground end - using existing logic")
                await MainActor.run {
                    manager.stopLiveActivity()
                }
                
            default:
                print("📡 [LiveActivityPush] Foreground unknown event - using existing logic refresh")
                // 기존 로직으로 새로고침
                if TimeUtility.shouldLiveActivityBeRunning() {
                    await MainActor.run {
                        manager.updateLiveActivity()
                    }
                }
            }
            
            completion()
        }
    }
    
    /// 백그라운드에서 강제 Live Activity 업데이트 (10분마다)
    @available(iOS 18.0, *)
    private func performBackgroundLiveActivityUpdate() async {
        let startTime = Date()
        print("🔄 [Background] Live Activity 강제 업데이트 시작: \(startTime)")
        
        let manager = LiveActivityManager.shared
        let isRunning = manager.isActivityRunning
        
        print("🔄 [Background] Live Activity 상태:")
        print("   - Currently running: \(isRunning)")
        print("   - App state: \(UIApplication.shared.applicationState.rawValue)")
        
        if isRunning {
            // 실행 중인 Live Activity가 있으면 백그라운드 전용 강제 업데이트 (재시도 포함)
            print("🔄 [Background] Live Activity 백그라운드 강제 업데이트 실행")
            manager.updateLiveActivityInBackground()
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [Background] Live Activity 백그라운드 업데이트 요청 완료 (\(String(format: "%.2f", duration))s)")
        } else {
            print("⚠️ [Background] Live Activity 실행 중이 아님 - 업데이트 스킵")
        }
    }
    
    /// APNs 토큰 등록 성공 (iOS 18+ Live Activity 전용)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📡 [APNs] Device token registered for iOS 18+ Live Activity")
        
        // 디바이스 토큰 로깅
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📡 [APNs] Device token: \(tokenString)")
        
        // APNs 환경 확인
        #if DEBUG
        print("📡 [APNs] Environment: Development (DEBUG)")
        #else
        print("📡 [APNs] Environment: Production (RELEASE)")
        #endif
        
        // iOS 18+ Live Activity 전용 토큰 처리
        if #available(iOS 18.0, *) {
            // 서버에 APNs 토큰 등록 (필요시)
            Task {
                await registerAPNsTokenToServer(tokenString)
            }
        }
    }
    
    /// APNs 토큰 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [APNs] Failed to register for remote notifications: \(error)")
    }
    
    /// APNs 토큰 서버 등록 (Push-to-Start 토큰으로 등록)
    @available(iOS 18.0, *)
    private func registerAPNsTokenToServer(_ token: String) async {
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        
        let payload: [String: Any] = [
            "type": "push_to_start",
            "token": token,
            "grade": grade,
            "classNumber": classNumber,
            "bundleId": Bundle.main.bundleIdentifier ?? "",
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            guard let url = URL(string: "https://liveactivity.helgisnw.com/api/live-activity/push-to-start") else {
                print("❌ [APNs] Invalid server URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Bundle-ID")
            request.httpBody = jsonData
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ [APNs] Push-to-Start token registered successfully")
                } else {
                    print("❌ [APNs] Push-to-Start token registration failed: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ [APNs] Error response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ [APNs] Failed to register Push-to-Start token: \(error)")
        }
    }
    
    /// Apple 정책 준수: 백그라운드 Live Activity 처리 완전 제거
    /// Live Activity는 APNs Push 또는 포그라운드에서 교시 변화시에만 업데이트
    private func performLiveActivityBackgroundUpdate() async {
        // 제거됨 - Apple 가이드라인 준수
        // 백그라운드에서 Live Activity 처리 금지
        // APNs Push 기반 새로고침으로 대체
    }
    
    // 백그라운드 위젯 및 Live Activity 업데이트 작업 스케줄링 (10분 고정)
    func scheduleWidgetRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.helgisnw.yangcheonlife.widgetrefresh")
        
        // 강제로 10분마다 실행 (Live Activity 업데이트 포함)
        let interval: TimeInterval = 600  // 10분 고정
        
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            let nextTime = Date(timeIntervalSinceNow: interval)
            print("📆 [Schedule] 다음 백그라운드 작업 예약됨: \(nextTime) (10분 간격 - Live Activity 강제 업데이트 포함)")
        } catch {
            print("❌ 백그라운드 작업 예약 실패: \(error)")
            
            // 실패시 재시도 (1분 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                self?.scheduleWidgetRefresh()
            }
        }
    }

    // 백그라운드 앱 갱신 처리 (Live Activity 강제 업데이트 포함)
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔄 [Background Fetch] 백그라운드 앱 갱신 시작: \(Date())")
        
        Task {
            // 위젯 데이터 동기화
            SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
            
            // 10분마다 강제 Live Activity 업데이트
            if #available(iOS 18.0, *) {
                await performBackgroundLiveActivityUpdate()
            }
            
            // 위젯 타임라인 갱신
            WidgetCenter.shared.reloadAllTimelines()
            
            print("✅ [Background Fetch] 위젯 및 Live Activity 업데이트 완료")
            completionHandler(.newData)
            
            // 다음 백그라운드 작업 스케줄링
            scheduleWidgetRefresh()
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    
    /// 포그라운드에서 알림을 받았을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 [Foreground] Notification received: \(notification.request.content.userInfo)")
        
        // 포그라운드에서도 알림 표시
        completionHandler([.banner, .sound, .badge])
    }
    
    /// 알림을 탭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 [Tapped] Notification tapped: \(response.notification.request.content.userInfo)")
        
        // 알림 탭 처리
        handleRemoteLiveActivityControl(userInfo: response.notification.request.content.userInfo)
        
        completionHandler()
    }
    
    // MARK: - Remote Notifications (Firebase & Live Activity)
    
    /// Live Activity 원격 제어 처리 (통합된 버전)
    
    /// Live Activity 원격 제어 처리 (애플 공식 + 사용자 정의 혼합)
    private func handleRemoteLiveActivityControl(userInfo: [AnyHashable: Any]) {
        print("📡 [RemoteControl] Processing remote Live Activity control: \(userInfo)")
        
        
        // 사용자 정의 data 필드에서 메시지 타입 확인 (하위 호환성)
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
        
        print("📡 [RemoteControl] Custom message type: \(type)")
        
        switch type {
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
    
    /// FCM 깨우기로 수행할 작업들 (수동 시작된 경우만 업데이트)
    private func performFCMWakeActions() async {
        print("⏰ [FCM Wake] Live Activity 상태 체크 및 업데이트 시작")
        
        guard #available(iOS 18.0, *) else {
            print("⏰ [FCM Wake] iOS 18.0 이상이 필요합니다.")
            return
        }
        
        let manager = LiveActivityManager.shared
        let isRunning = manager.isActivityRunning
        
        print("⏰ [FCM Wake] 상태 확인:")
        print("   - Currently running: \(isRunning)")
        print("   - App state: \(UIApplication.shared.applicationState.rawValue)")
        
        // 이미 실행 중인 Live Activity만 업데이트 (자동 시작 안함)
        if isRunning {
            manager.updateLiveActivity()
            print("⏰ [FCM Wake] Live Activity 업데이트 완료")
        } else {
            print("⏰ [FCM Wake] Live Activity 실행 중이 아님 - 자동 시작 안함")
        }
        
        // 위젯도 함께 업데이트
        WidgetCenter.shared.reloadAllTimelines()
        print("⏰ [FCM Wake] 모든 작업 완료")
    }
    
    // Check for updates when app enters foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 [AppDelegate] ✅ applicationWillEnterForeground 호출됨")
        AppUpdateService.shared.checkForUpdates()
        
        // Extension에서 보낸 대기 중인 Live Activity 이벤트 처리
        checkAndHandlePendingLiveActivityEvents()
        
        
        // 원격 알림 재등록 (포그라운드 진입 시)
        application.registerForRemoteNotifications()
        
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
        
        // Extension에서 보낸 대기 중인 Live Activity 이벤트 처리
        checkAndHandlePendingLiveActivityEvents()
        
        print("✅ 위젯 타임라인 리로드 및 라이브 액티비티 업데이트 요청 완료")
        
        // 다음 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }
    
    // MARK: - Pending Live Activity 처리
    
    /// Extension에서 보낸 대기 중인 Live Activity 이벤트 처리 (기존 로직 기반)
    private func checkAndHandlePendingLiveActivityEvents() {
        let groupDefaults = UserDefaults(suiteName: "group.com.helgisnw.yangcheonlife")
        groupDefaults?.synchronize()
        
        guard let event = groupDefaults?.string(forKey: "pendingLiveActivityEvent") else {
            return
        }
        
        let timestamp = groupDefaults?.double(forKey: "lastLiveActivityEventTimestamp") ?? 0
        let eventAge = Date().timeIntervalSince1970 - timestamp
        
        // 5분 이상 오래된 이벤트는 무시
        guard eventAge <= 300 else {
            print("📡 [AppDelegate] Live Activity event too old (\(Int(eventAge))s), ignoring")
            groupDefaults?.removeObject(forKey: "pendingLiveActivityEvent")
            groupDefaults?.removeObject(forKey: "lastLiveActivityEventTimestamp")
            groupDefaults?.synchronize()
            return
        }
        
        print("📡 [AppDelegate] Processing pending Live Activity event: \(event)")
        
        if #available(iOS 18.0, *) {
            let manager = LiveActivityManager.shared
            let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
            let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
            
            switch event {
            case "start":
                print("🚀 [AppDelegate] Extension triggered start - using existing logic")
                if grade > 0 && classNumber > 0 {
                    manager.startLiveActivity(grade: grade, classNumber: classNumber)
                }
                
            case "update":
                print("🔄 [AppDelegate] Extension triggered update - using existing logic")
                manager.updateLiveActivity()
                
            case "end":
                print("🛑 [AppDelegate] Extension triggered end - using existing logic")
                manager.stopLiveActivity()
                
            default:
                print("⚠️ [AppDelegate] Unknown event: \(event)")
            }
        }
        
        // 이벤트 처리 완료 후 정리
        groupDefaults?.removeObject(forKey: "pendingLiveActivityEvent")
        groupDefaults?.removeObject(forKey: "lastLiveActivityEventTimestamp")
        groupDefaults?.synchronize()
    }
    
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
                if #available(iOS 18.0, *) {
                    LiveActivityManager.shared.startLiveActivity(grade: grade, classNumber: classNumber)
                    print("📱 [AppDelegate] ✅ Extension 요청으로 Live Activity 시작 완료: \(grade)학년 \(classNumber)반")
                } else {
                    print("📱 [AppDelegate] ❌ iOS 18.0 이상이 필요합니다.")
                }
            }
        } else {
            print("📱 [AppDelegate] ❌ 유효하지 않은 학년/반 정보: \(grade)학년 \(classNumber)반")
        }
    }
    
    /// Extension에서 보낸 Live Activity 새로고침 신호 처리
    private func checkAndHandlePendingLiveActivityRefresh() {
        let groupDefaults = UserDefaults(suiteName: "group.com.helgisnw.yangcheonlife")
        
        // 새로고침 신호 확인
        let hasPendingRefresh = groupDefaults?.bool(forKey: "pendingLiveActivityRefresh") ?? false
        let refreshTimestamp = groupDefaults?.double(forKey: "pendingLiveActivityRefreshTimestamp") ?? 0
        
        guard hasPendingRefresh else { 
            return 
        }
        
        print("📡 [AppDelegate] Pending Live Activity refresh signal found")
        print("📡 [AppDelegate] Refresh timestamp: \(Date(timeIntervalSince1970: refreshTimestamp))")
        
        // 신호가 너무 오래된 것은 무시 (5분 이상)
        let signalAge = Date().timeIntervalSince1970 - refreshTimestamp
        guard signalAge <= 300 else {
            print("📡 [AppDelegate] Refresh signal too old (\(Int(signalAge))s), ignoring")
            // 오래된 신호 제거
            groupDefaults?.removeObject(forKey: "pendingLiveActivityRefresh")
            groupDefaults?.removeObject(forKey: "pendingLiveActivityRefreshTimestamp")
            groupDefaults?.synchronize()
            return
        }
        
        print("📡 [AppDelegate] Processing Live Activity refresh from Extension signal")
        
        // Live Activity 새로고침 실행
        if #available(iOS 18.0, *) {
            LiveActivityManager.shared.updateLiveActivity()
        }
        
        // 처리 완료 후 신호 제거
        groupDefaults?.removeObject(forKey: "pendingLiveActivityRefresh")
        groupDefaults?.removeObject(forKey: "pendingLiveActivityRefreshTimestamp") 
        groupDefaults?.removeObject(forKey: "lastRefreshPushType")
        groupDefaults?.synchronize()
        
        print("📡 [AppDelegate] Live Activity refresh signal processed and cleared")
    }
    
    // 앱이 백그라운드로 이동할 때 호출
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 [AppDelegate] 앱이 백그라운드로 이동: \(Date())")
        
        // Live Activity 상태 보존 및 업데이트
        guard #available(iOS 18.0, *) else { return }
        let manager = LiveActivityManager.shared
        let isRunning = manager.isActivityRunning
        let shouldBeRunning = TimeUtility.shouldLiveActivityBeRunning()
        
        print("📱 [Background Entry] Live Activity status:")
        print("   - Currently running: \(isRunning)")
        print("   - Should be running: \(shouldBeRunning)")
        
        // iOS 18+ Live Activity 백그라운드 상태 업데이트 (수동 시작된 경우만)
        if #available(iOS 18.0, *) {
            if isRunning {
                manager.updateLiveActivity()
                print("📱 [Background Entry] Live Activity updated before background")
            } else {
                print("📱 [Background Entry] Live Activity not running - no auto start")
            }
        }
        
        // 백그라운드 작업 스케줄링
        scheduleWidgetRefresh()
    }
}
