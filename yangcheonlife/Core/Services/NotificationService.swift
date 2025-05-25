import Foundation
import UserNotifications
import SwiftUI

// MARK: - 알림 서비스
/// 모든 알림 관리를 담당하는 서비스
class NotificationService: NSObject, ObservableObject {
    
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    
    private override init() {
        super.init()
        setupNotificationCategories()
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// 알림 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                isAuthorized = granted
                authorizationStatus = granted ? .authorized : .denied
            }
            
            return granted
        } catch {
            print("❌ 알림 권한 요청 실패: \(error)")
            return false
        }
    }
    
    /// 체육 수업 알림 스케줄링
    func schedulePhysicalEducationAlerts() async {
        guard userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertEnabled),
              userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) else {
            await removePhysicalEducationAlerts()
            return
        }
        
        // 기존 체육 알림 제거
        await removePhysicalEducationAlerts()
        
        // 알림 시간 가져오기
        let alertTimeString = userDefaults.string(forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertTime) ?? "07:00"
        let timeComponents = alertTimeString.components(separatedBy: ":")
        
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            print("❌ 잘못된 체육 알림 시간 형식")
            return
        }
        
        // 시간표 데이터에서 체육 수업이 있는 요일 찾기
        guard let scheduleData = ScheduleService.shared.currentScheduleData else {
            print("❌ 시간표 데이터가 없어 체육 알림을 설정할 수 없습니다")
            return
        }
        
        for (weekdayIndex, dailySchedule) in scheduleData.weeklySchedule.enumerated() {
            let weekday = weekdayIndex + 2 // 월요일: 2
            
            // 해당 요일에 체육 수업이 있는지 확인
            let hasPhysicalEducation = dailySchedule.contains { schedule in
                schedule.subject.contains("체육") || schedule.subject.contains("PE")
            }
            
            if hasPhysicalEducation {
                let identifier = AppConstants.Notification.physicalEducationIdentifier(weekday: weekday)
                let content = createPhysicalEducationNotificationContent()
                
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                do {
                    try await notificationCenter.add(request)
                    print("✅ 체육 알림 설정 완료: \(weekday)요일 \(hour):\(minute)")
                } catch {
                    print("❌ 체육 알림 설정 실패: \(error)")
                }
            }
        }
    }
    
    /// 모든 알림 제거
    func removeAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        print("✅ 모든 알림이 제거되었습니다")
    }
    
    /// 체육 알림만 제거
    func removePhysicalEducationAlerts() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let peIdentifiers = pendingRequests
            .filter { $0.identifier.hasPrefix("pe-alert-") }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: peIdentifiers)
        print("✅ 체육 알림이 제거되었습니다")
    }
    
    /// 권한 상태 확인
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
                isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// 알림 테스트
    func sendTestNotification() async {
        guard isAuthorized else {
            print("❌ 알림 권한이 없습니다")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "테스트 알림"
        content.body = "양천고 라이프 알림이 정상적으로 작동합니다!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ 테스트 알림이 전송되었습니다")
        } catch {
            print("❌ 테스트 알림 전송 실패: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    /// 알림 카테고리 설정
    private func setupNotificationCategories() {
        let scheduleCategory = UNNotificationCategory(
            identifier: AppConstants.Notification.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([scheduleCategory])
    }
    
    /// 체육 알림 콘텐츠 생성
    private func createPhysicalEducationNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "체육 수업 준비 알림"
        content.body = "오늘은 체육 수업이 있습니다! 체육복을 준비해주세요. 🏃‍♂️"
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notification.categoryIdentifier
        
        return content
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    /// 포그라운드에서 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    /// 알림 응답 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 알림 응답에 따른 추가 처리 가능
        print("📱 알림 응답 받음: \(response.notification.request.identifier)")
        completionHandler()
    }
}