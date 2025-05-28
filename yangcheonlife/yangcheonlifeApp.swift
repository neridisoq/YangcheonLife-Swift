// YangcheonLifeApp.swift - 양천고 라이프 메인 앱
import SwiftUI
import UserNotifications
import ActivityKit

@main
struct YangcheonLifeApp: App {
    
    // MARK: - Properties
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var scheduleService = ScheduleService.shared
    @StateObject private var wifiService = WiFiService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
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
