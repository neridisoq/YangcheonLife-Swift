// YangcheonLifeApp.swift - 양천고 라이프 메인 앱
import SwiftUI
import UserNotifications

#if canImport(ActivityKit) && swift(>=5.9)
import ActivityKit
#endif

@main
struct YangcheonLifeApp: App {
    
    // MARK: - Properties
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var scheduleService = ScheduleService.shared
    @StateObject private var wifiService = WiFiService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    // Firebase는 lazy로 초기화하여 AppDelegate에서 Firebase.configure() 호출 후에 생성되도록 함
    private var firebaseService: FirebaseService {
        FirebaseService.shared
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scheduleService)
                .environmentObject(wifiService)
                .environmentObject(notificationService)
                .environmentObject(firebaseService)
                .environmentObject(liveActivityManager)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    print("📱 [SwiftUI] willEnterForegroundNotification 수신")
                    // 즉시 실행하지 않고 약간의 지연 후 실행
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        print("📱 [SwiftUI] 지연 후 대기 Live Activity 처리 실행")
                        appDelegate.handlePendingLiveActivityStartFromSwiftUI()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("📱 [SwiftUI] didBecomeActiveNotification 수신")
                    // 즉시 실행하지 않고 약간의 지연 후 실행
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        print("📱 [SwiftUI] 지연 후 대기 Live Activity 처리 실행")
                        appDelegate.handlePendingLiveActivityStartFromSwiftUI()
                    }
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// 앱 초기 설정
    private func setupApp() {
        // 알림 서비스 델리게이트 설정
        UNUserNotificationCenter.current().delegate = notificationService
        
        print("🚀 양천고 라이프 v\(AppConstants.App.version) 시작")
        
        // 앱 시작 시 필요한 초기화 작업
        Task {
            // iCloud 설정 동기화 (앱 시작시)
            iCloudSyncService.shared.syncFromiCloud()
            
            // 알림 권한 상태 확인
            await notificationService.checkAuthorizationStatus()
            
            // 기본 설정값이 있으면 시간표 로드
            let grade = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
            let classNumber = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
            
            if grade > 0 && classNumber > 0 {
                await scheduleService.loadSchedule(grade: grade, classNumber: classNumber)
            }
        }
    }
}
