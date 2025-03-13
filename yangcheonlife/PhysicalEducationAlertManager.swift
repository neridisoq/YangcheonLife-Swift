import Foundation
import UserNotifications

class PhysicalEducationAlertManager {
    static let shared = PhysicalEducationAlertManager()
    
    private let peAlertIdentifierPrefix = "physical-education-alert-"
    private let peKeywords = ["체육", "운건"]
    
    private init() {}
    
    // 체육 수업 알림 예약
    func scheduleAlerts() {
        // 기존 체육 알림 제거
        removeAllAlerts()
        
        // 알림 활성화 확인
        guard UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled"),
              UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            return
        }
        
        // 현재 학년, 반 정보 가져오기
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        
        // 시간표 데이터 가져오기
        if let scheduleData = ScheduleManager.shared.loadDataStore(),
           scheduleData.grade == grade && scheduleData.classNumber == classNumber {
            
            // 체육 수업이 있는 요일 확인
            let peWeekdays = findPhysicalEducationWeekdays(schedules: scheduleData.schedules)
            
            // 각 요일에 대해 알림 설정
            for weekday in peWeekdays {
                schedulePhysicalEducationAlert(weekday: weekday)
            }
        }
    }
    
    // 체육 수업이 있는 요일 찾기 (월요일: 0, 화요일: 1, ...)
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
            }
        }
        
        return peWeekdays
    }
    
    // 특정 요일에 체육 알림 예약
    private func schedulePhysicalEducationAlert(weekday: Int) {
        // 알림 ID 생성 (요일별로 다른 ID)
        let identifier = "\(peAlertIdentifierPrefix)\(weekday)"
        
        // 알림 내용 설정
        let content = UNMutableNotificationContent()
        content.title = "체육 수업 알림"
        content.body = "오늘 체육 수업이 있습니다."
        content.sound = UNNotificationSound.default
        
        // 알림 트리거 생성 (설정된 시간 기준)
        let trigger = createNotificationTrigger(weekday: weekday + 2) // API는 월요일이 0이지만, UNCalendarNotificationTrigger는 월요일이 2
        
        // 알림 요청 생성 및 등록
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("체육 알림 설정 실패: \(error)")
            } else {
                print("체육 알림 설정 완료 (요일: \(weekday+2))")
            }
        }
    }
    
    // 알림 트리거 생성
    private func createNotificationTrigger(weekday: Int) -> UNCalendarNotificationTrigger {
        // UserDefaults에서 알림 시간 가져오기
        let timeString = UserDefaults.standard.string(forKey: "physicalEducationAlertTime") ?? "07:00"
        let components = timeString.components(separatedBy: ":")
        
        // 시간과 분 추출
        let hour = Int(components[0]) ?? 7
        let minute = Int(components[1]) ?? 0
        
        // 알림 트리거용 날짜 구성요소 생성
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = weekday // 일요일: 1, 월요일: 2, ..., 토요일: 7
        
        // 주간 반복 알림 트리거 생성
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }
    
    // 모든 체육 알림 제거
    func removeAllAlerts() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let peIdentifiers = requests.filter { $0.identifier.starts(with: self.peAlertIdentifierPrefix) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: peIdentifiers)
        }
    }
    
    // 시간표 업데이트 시 체육 알림 재설정
    func refreshAlertsAfterScheduleUpdate() {
        if UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled") {
            scheduleAlerts()
        }
    }
}