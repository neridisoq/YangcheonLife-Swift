//LocalNotificationManager.swift
import Foundation
import UserNotifications
import Combine

class LocalNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationManager()
    
    @Published var schedules: [[ScheduleItem]] = []
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        // 초기화 시 로컬에 저장된 시간표 로드
        if let savedSchedules = loadLocalSchedule() {
            self.schedules = savedSchedules
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func fetchAndSaveSchedule(grade: Int, classNumber: Int) {
        // 먼저 로컬에 저장된 시간표 확인
        if let savedSchedules = loadLocalSchedule(), !savedSchedules.isEmpty {
            self.schedules = savedSchedules
            
            // 알림이 활성화된 경우 현재 시간표로 알림 설정
            if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                scheduleNotifications(schedules: savedSchedules, grade: grade, classNumber: classNumber)
            }
        }
        
        // 서버에서 최신 시간표 가져오기 시도
        let urlString = "https://comsi.helgisnw.me/\(grade)/\(classNumber)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [[ScheduleItem]].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("시간표 갱신 완료")
                case .failure(let error):
                    print("시간표 갱신 실패: \(error)")
                }
            }, receiveValue: { [weak self] schedules in
                guard let self = self else { return }
                self.schedules = schedules
                self.saveScheduleLocally(schedules)
                
                // 알림이 활성화된 경우 새 시간표로 알림 재설정
                if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                    self.scheduleNotifications(schedules: schedules, grade: grade, classNumber: classNumber)
                }
            })
            .store(in: &cancellables)
    }
    
    private func saveScheduleLocally(_ schedules: [[ScheduleItem]]) {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "savedSchedule")
            // 마지막 업데이트 시간 기록
            UserDefaults.standard.set(Date(), forKey: "lastScheduleUpdateTime")
        }
    }
    
    func loadLocalSchedule() -> [[ScheduleItem]]? {
        if let savedData = UserDefaults.standard.data(forKey: "savedSchedule"),
           let decodedSchedule = try? JSONDecoder().decode([[ScheduleItem]].self, from: savedData) {
            return decodedSchedule
        }
        return nil
    }
    
    func scheduleNotifications(schedules: [[ScheduleItem]], grade: Int, classNumber: Int) {
        // 먼저 모든 예약된 알림을 제거
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 알림 설정이 활성화되어 있는지 확인
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if !notificationsEnabled {
            return
        }
        
        // 현재 날짜에서 요일 정보 가져오기 (1: 일요일, 2: 월요일, ... 7: 토요일)
        let calendar = Calendar.current
        
        // 주간 스케줄 기준으로 알림 설정
        for (weekdayIndex, daySchedule) in schedules.enumerated() {
            let weekday = weekdayIndex + 2 // API의 주간 스케줄이 월요일(2)부터 시작
            if weekday > 7 || daySchedule.isEmpty {
                continue // 토요일, 일요일 또는 비어있는 스케줄 무시
            }
            
            // 해당 요일의 모든 수업에 대해 알림 설정
            for schedule in daySchedule {
                scheduleClassNotification(
                    weekday: weekday,
                    classTime: schedule.classTime,
                    subject: schedule.subject,
                    teacher: schedule.teacher,
                    grade: grade,
                    classNumber: classNumber
                )
            }
        }
    }
    
    private func scheduleClassNotification(weekday: Int, classTime: Int, subject: String, teacher: String, grade: Int, classNumber: Int) {
        // 알림이 발생할 요일과 시간 계산
        let periodTimes: [(start: (hour: Int, minute: Int), end: (hour: Int, minute: Int))] = [
            ((8, 20), (9, 10)),   // 1교시
            ((9, 20), (10, 10)),  // 2교시
            ((10, 20), (11, 10)), // 3교시
            ((11, 20), (12, 10)), // 4교시
            ((13, 10), (14, 0)),  // 5교시
            ((14, 10), (15, 0)),  // 6교시
            ((15, 10), (16, 0))   // 7교시
        ]
        
        guard classTime >= 1 && classTime <= periodTimes.count else { return }
        
        let periodTime = periodTimes[classTime - 1]
        let startTime = periodTime.start
        
        // 현재 시간 기준으로 다음 해당 요일의 해당 시간 계산
        var dateComponents = DateComponents()
        dateComponents.hour = startTime.hour
        dateComponents.minute = startTime.minute
        dateComponents.weekday = weekday
        
        // 알림 내용 설정
        let notificationContent = UNMutableNotificationContent()
        
        // 사용자가 설정한 과목 정보 확인
        var displaySubject = subject
        var displayLocation = teacher
        
        // A반과 같은 형식인 경우 사용자 설정 확인
        if subject.contains("반") {
            if let selectedSubject = UserDefaults.standard.string(forKey: "selected\(subject)Subject"),
               selectedSubject != "선택 없음" && selectedSubject != subject {
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displaySubject = components[0]
                    displayLocation = components[1]
                }
            }
        }
        
        // 알림 제목 및 내용 설정
        notificationContent.title = "\(classTime)교시 수업 알림"
        
        if displaySubject.contains("반") {
            notificationContent.body = "\(classTime)교시 수업입니다. \(grade)학년 \(classNumber)반 교실입니다."
        } else {
            notificationContent.body = "\(classTime)교시 \(displaySubject) 수업입니다. \(displayLocation)교실입니다."
        }
        
        notificationContent.sound = UNNotificationSound.default
        
        // 알림 트리거 설정 (매주 해당 요일의 해당 시간에)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        // 알림 요청 생성 및 등록
        let identifier = "class-notification-\(weekday)-\(classTime)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: notificationContent,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 포그라운드에 있을 때도 알림 표시
        completionHandler([.badge, .sound, .banner, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 알림 선택 시 처리 (필요하면 추가 구현)
        completionHandler()
    }
}
