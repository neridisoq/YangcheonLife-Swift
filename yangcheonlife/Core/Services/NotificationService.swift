import Foundation
import UserNotifications
import SwiftUI
import Combine

// MARK: - 알림 서비스
/// 모든 알림 관리를 담당하는 서비스 (LocalNotificationManager + PhysicalEducationAlertManager 통합)
class NotificationService: NSObject, ObservableObject {
    
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var schedules: [[ScheduleItem]] = []
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private let peAlertIdentifierPrefix = "physical-education-alert-"
    private let peKeywords = ["체육", "운건"]
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
        loadScheduleData()
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
    
    /// 시간표 데이터 로드 (LocalNotificationManager 기능)
    private func loadScheduleData() {
        if let savedData = ScheduleService.shared.currentScheduleData {
            schedules = savedData.weeklySchedule
        }
    }
    
    /// 시간표 가져오기 및 저장 (LocalNotificationManager 기능)
    func fetchAndSaveSchedule(grade: Int, classNumber: Int) {
        Task {
            await ScheduleService.shared.loadSchedule(grade: grade, classNumber: classNumber)
            
            // 저장소에서 최신 데이터 로드하여 UI 갱신
            if let savedData = ScheduleService.shared.currentScheduleData {
                await MainActor.run {
                    self.schedules = savedData.weeklySchedule
                }
            }
        }
    }
    
    /// 로컬 시간표 로드 (LocalNotificationManager 기능)
    func loadLocalSchedule() -> [[ScheduleItem]]? {
        if let savedData = ScheduleService.shared.currentScheduleData {
            return savedData.weeklySchedule
        }
        return nil
    }
    
    /// 체육 수업 알림 스케줄링 (PhysicalEducationAlertManager 기능 통합)
    func schedulePhysicalEducationAlerts() async {
        // 기존 체육 알림 제거
        await removePhysicalEducationAlerts()
        
        // 알림 활성화 확인
        guard userDefaults.bool(forKey: "physicalEducationAlertEnabled"),
              userDefaults.bool(forKey: "notificationsEnabled") else {
            print("⏭️ 체육 알림이 비활성화되어 있습니다")
            return
        }
        
        // 현재 학년, 반 정보 가져오기
        let grade = userDefaults.integer(forKey: "defaultGrade")
        let classNumber = userDefaults.integer(forKey: "defaultClass")
        
        // 시간표 데이터 가져오기
        guard let scheduleData = ScheduleService.shared.currentScheduleData,
              scheduleData.grade == grade && scheduleData.classNumber == classNumber else {
            print("❌ 시간표 데이터가 없어 체육 알림을 설정할 수 없습니다")
            return
        }
        
        // 체육 수업이 있는 요일 확인
        let peWeekdays = findPhysicalEducationWeekdays(schedules: scheduleData.weeklySchedule)
        
        // 각 요일에 대해 알림 설정
        for weekday in peWeekdays {
            // 시스템의 요일 형식으로 변환 (월요일: 2, 화요일: 3, ...)
            let systemWeekday = weekday + 2
            await schedulePhysicalEducationAlert(weekday: systemWeekday)
        }
    }
    
    /// 체육 수업이 있는 요일 찾기 (월요일: 0, 화요일: 1, ...)
    private func findPhysicalEducationWeekdays(schedules: [[ScheduleItem]]) -> [Int] {
        var peWeekdays: [Int] = []
        
        // 시간표의 각 요일 검사
        for (weekdayIndex, daySchedule) in schedules.enumerated() {
            // 요일의 모든 수업을 검사하여 체육/운건 키워드가 있는지 확인
            let hasPE = daySchedule.contains { item in
                return peKeywords.contains { keyword in
                    return item.subject.contains(keyword)
                }
            }
            
            if hasPE {
                peWeekdays.append(weekdayIndex)
                print("🏃‍♂️ 체육 수업 발견: \(weekdayIndex)번째 요일")
            }
        }
        
        return peWeekdays
    }
    
    /// 특정 요일에 체육 알림 예약
    private func schedulePhysicalEducationAlert(weekday: Int) async {
        // 알림 ID 생성 (요일별로 다른 ID)
        let identifier = "\(peAlertIdentifierPrefix)\(weekday)"
        
        // 알림 내용 설정
        let content = UNMutableNotificationContent()
        content.title = "체육 수업 알림"
        
        // 요일 표시 문자열 생성
        let weekdayString = getWeekdayString(weekday)
        content.body = "오늘 체육 수업이 있습니다. 체육복을 준비하세요!"
        content.sound = UNNotificationSound.default
        
        // 알림 트리거 생성 (설정된 시간 기준)
        let trigger = createNotificationTrigger(weekday: weekday)
        
        // 알림 요청 생성 및 등록
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("✅ 체육 알림 설정 완료 (요일: \(weekdayString))")
        } catch {
            print("❌ 체육 알림 설정 실패: \(error)")
        }
    }
    
    /// 요일 번호를 문자열로 변환
    private func getWeekdayString(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "일요일"
        case 2: return "월요일"
        case 3: return "화요일"
        case 4: return "수요일"
        case 5: return "목요일"
        case 6: return "금요일"
        case 7: return "토요일"
        default: return "알 수 없음"
        }
    }
    
    /// 알림 트리거 생성
    private func createNotificationTrigger(weekday: Int) -> UNCalendarNotificationTrigger {
        // UserDefaults에서 알림 시간 가져오기
        let timeString = userDefaults.string(forKey: "physicalEducationAlertTime") ?? "07:00"
        let components = timeString.components(separatedBy: ":")
        
        // 시간과 분 추출
        let hour = Int(components[0]) ?? 7
        let minute = Int(components[1]) ?? 0
        
        // 알림 트리거용 날짜 구성요소 생성
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = weekday // 일요일: 1, 월요일: 2, ..., 토요일: 7
        
        print("⏰ 체육 알림 설정: \(weekday)요일 \(hour):\(minute)")
        
        // 주간 반복 알림 트리거 생성
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }
    
    /// 시간표 업데이트 시 체육 알림 재설정
    func refreshAlertsAfterScheduleUpdate() {
        Task {
            if userDefaults.bool(forKey: "physicalEducationAlertEnabled") {
                await schedulePhysicalEducationAlerts()
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
            .filter { $0.identifier.hasPrefix(peAlertIdentifierPrefix) }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: peIdentifiers)
        print("✅ 체육 알림 \(peIdentifiers.count)개가 제거되었습니다")
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
            identifier: "yangcheonlife-notification",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([scheduleCategory])
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
        let userInfo = notification.request.content.userInfo
        print("📩 Firebase 알림 수신 (포그라운드): \(userInfo)")
        print("📩 전체 userInfo 구조 (포그라운드):")
        for (key, value) in userInfo {
            print("   \(key): \(value)")
        }
        
        // Firebase 메시지인지 확인하고 Live Activity 원격 제어 처리
        handleFirebaseMessage(userInfo: userInfo)
        
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
        
        let userInfo = response.notification.request.content.userInfo
        print("📩 Firebase 알림 탭됨: \(userInfo)")
        
        // Firebase 메시지 처리
        handleFirebaseMessage(userInfo: userInfo)
        
        completionHandler()
    }
    
    // MARK: - Firebase 메시지 처리
    
    /// Firebase 메시지 처리 공통 메서드
    private func handleFirebaseMessage(userInfo: [AnyHashable: Any]) {
        // data 필드에서 메시지 타입 확인
        var messageType: String?
        if let data = userInfo["data"] as? [String: Any] {
            messageType = data["type"] as? String
        } else {
            messageType = userInfo["type"] as? String
        }
        
        guard let type = messageType else {
            print("⚠️ Firebase 메시지 타입을 찾을 수 없음: \(userInfo)")
            return
        }
        
        print("📩 Firebase 메시지 타입: \(type)")
        
        switch type {
        case "start_live_activity":
            FirebaseService.shared.handleRemoteLiveActivityStart(userInfo: userInfo)
        case "stop_live_activity":
            FirebaseService.shared.handleRemoteLiveActivityStop(userInfo: userInfo)
        default:
            print("⚠️ 알 수 없는 Firebase 메시지 타입: \(type)")
        }
    }
}