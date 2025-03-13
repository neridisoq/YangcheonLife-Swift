import Foundation
import UserNotifications
import Combine
import WidgetKit

// 시간표 데이터와 메타데이터를 함께 저장하는 구조체
struct ScheduleData: Codable, Equatable {
    let grade: Int
    let classNumber: Int
    let lastUpdated: Date
    let schedules: [[ScheduleItem]]
    
    static func == (lhs: ScheduleData, rhs: ScheduleData) -> Bool {
        // 학년/반 확인
        guard lhs.grade == rhs.grade && lhs.classNumber == rhs.classNumber else {
            return false
        }
        
        // 시간표 내용 비교
        guard lhs.schedules.count == rhs.schedules.count else { return false }
        
        for i in 0..<lhs.schedules.count {
            guard lhs.schedules[i].count == rhs.schedules[i].count else { return false }
            
            for j in 0..<lhs.schedules[i].count {
                let item1 = lhs.schedules[i][j]
                let item2 = rhs.schedules[i][j]
                
                if item1.subject != item2.subject || item1.teacher != item2.teacher {
                    return false
                }
            }
        }
        
        return true
    }
}

// 시간표 데이터 관리 클래스
class ScheduleManager {
    static let shared = ScheduleManager()
    
    private let compareStoreKey = "schedule_compare_store" // 저장소1: 비교용
    private let dataStoreKey = "schedule_data_store"       // 저장소2: 사용용
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // 저장소1에서 데이터 로드
    func loadCompareStore() -> ScheduleData? {
        guard let data = UserDefaults.standard.data(forKey: compareStoreKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(ScheduleData.self, from: data)
        } catch {
            print("비교 저장소 로드 실패: \(error)")
            return nil
        }
    }
    
    // 저장소2에서 데이터 로드
    func loadDataStore() -> ScheduleData? {
        guard let data = UserDefaults.standard.data(forKey: dataStoreKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(ScheduleData.self, from: data)
        } catch {
            print("데이터 저장소 로드 실패: \(error)")
            return nil
        }
    }
    
    // 저장소1에 데이터 저장
    func saveToCompareStore(_ data: ScheduleData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: compareStoreKey)
        } catch {
            print("비교 저장소 저장 실패: \(error)")
        }
    }
    
    // 저장소2에 데이터 저장
    func saveToDataStore(_ data: ScheduleData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: dataStoreKey)
            
            // 위젯용 공유 UserDefaults에도 저장
            SharedUserDefaults.shared.userDefaults.set(encoded, forKey: dataStoreKey)
            
            // 위젯 타임라인 갱신
            updateWidgetTimelines()
        } catch {
            print("데이터 저장소 저장 실패: \(error)")
        }
    }
    
    // 시간표 로드 및 업데이트
    func fetchAndUpdateSchedule(grade: Int, classNumber: Int, completion: @escaping (Bool) -> Void) {
        // 서버에서 시간표 가져오기
        let urlString = "https://comsi.helgisnw.me/\(grade)/\(classNumber)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("시간표 데이터 요청 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                // 서버 응답 데이터 파싱
                let schedules = try JSONDecoder().decode([[ScheduleItem]].self, from: data)
                
                // 메타데이터를 포함한 새 데이터 객체 생성
                let newScheduleData = ScheduleData(
                    grade: grade,
                    classNumber: classNumber,
                    lastUpdated: Date(),
                    schedules: schedules
                )
                
                DispatchQueue.main.async {
                    // 비교 저장소의 기존 데이터 확인
                    if let existingData = self.loadCompareStore(),
                       existingData == newScheduleData {
                        // 데이터 변경 없음
                        print("시간표 변경 없음")
                        completion(false)
                        return
                    }
                    
                    // 데이터 변경 감지됨 - 순차적 처리 시작
                    self.processScheduleUpdate(newScheduleData: newScheduleData, completion: completion)
                }
            } catch {
                print("시간표 데이터 파싱 실패: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 업데이트된 시간표 처리 로직
    private func processScheduleUpdate(newScheduleData: ScheduleData, completion: @escaping (Bool) -> Void) {
        // 1. 비교 저장소에 원본 데이터 저장
        saveToCompareStore(newScheduleData)
        
        // 2. 탐구 과목 커스텀 적용
        let customizedSchedules = applySubjectCustomization(
            schedules: newScheduleData.schedules,
            grade: newScheduleData.grade,
            classNumber: newScheduleData.classNumber
        )
        
        // 3. 커스텀된 데이터로 최종 데이터 객체 생성
        let finalScheduleData = ScheduleData(
            grade: newScheduleData.grade,
            classNumber: newScheduleData.classNumber,
            lastUpdated: newScheduleData.lastUpdated,
            schedules: customizedSchedules
        )
        
        // 4. 데이터 저장소에 최종 데이터 저장
        saveToDataStore(finalScheduleData)
        
        // 5. 알림 재설정
        resetNotifications(scheduleData: finalScheduleData, completion: completion)
    }
    
    // 탐구과목 커스텀 로직
    private func applySubjectCustomization(schedules: [[ScheduleItem]], grade: Int, classNumber: Int) -> [[ScheduleItem]] {
        var customizedSchedules = schedules
        
        for (dayIndex, day) in schedules.enumerated() {
            for (periodIndex, item) in day.enumerated() {
                if item.subject.contains("반") {
                    // 학년/반별 과목 선택 키 생성 (원래 방식 유지)
                    let customKey = "selected\(item.subject)Subject"
                    if let selectedSubject = UserDefaults.standard.string(forKey: customKey),
                       selectedSubject != "선택 없음" && selectedSubject != item.subject {
                        
                        var updatedItem = item
                        let components = selectedSubject.components(separatedBy: "/")
                        if components.count == 2 {
                            // 과목명과 교실 분리하여 저장
                            updatedItem.subject = components[0]
                            updatedItem.teacher = components[1]
                        }
                        
                        customizedSchedules[dayIndex][periodIndex] = updatedItem
                    }
                }
            }
        }
        
        return customizedSchedules
    }
    
    // 외부에서 접근 가능한 커스텀 메서드
    func applyCurrentSubjectCustomization(schedules: [[ScheduleItem]]) -> [[ScheduleItem]] {
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        return applySubjectCustomization(schedules: schedules, grade: grade, classNumber: classNumber)
    }
    
    // 알림 초기화 및 재설정
    func resetNotifications(scheduleData: ScheduleData, completion: @escaping (Bool) -> Void) {
        // 1. 모든 알림 삭제
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 2. 알림 시스템이 업데이트되기를 보장하기 위한 짧은 지연
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            // 3. 알림이 활성화되어 있는지 확인
            let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            if !notificationsEnabled {
                completion(true)
                return
            }
            
            // 4. 새 알림 스케줄링
            self.scheduleNotifications(
                schedules: scheduleData.schedules,
                grade: scheduleData.grade,
                classNumber: scheduleData.classNumber
            )
            
            // 5. 위젯 타임라인 갱신
            self.updateWidgetTimelines()
            
            completion(true)
        }
    }
    
    // 알림 스케줄링
    private func scheduleNotifications(schedules: [[ScheduleItem]], grade: Int, classNumber: Int) {
        // 주간 스케줄 기준으로 알림 설정
        for (weekdayIndex, daySchedule) in schedules.enumerated() {
            let weekday = weekdayIndex + 2 // API의 주간 스케줄이 월요일(2)부터 시작
            if weekday > 7 || daySchedule.isEmpty {
                continue // 토요일, 일요일 또는 비어있는 스케줄 무시
            }
            
            // 해당 요일의 모든 수업에 대해 알림 설정
            for schedule in daySchedule {
                // 수업이 있는 시간만 알림 설정
                if !schedule.subject.isEmpty {
                    scheduleClassNotification(
                        schedule: schedule,
                        weekday: weekday,
                        grade: grade,
                        classNumber: classNumber
                    )
                }
            }
        }
    }
    
    // 수업별 알림 설정
    private func scheduleClassNotification(schedule: ScheduleItem, weekday: Int, grade: Int, classNumber: Int) {
        // 알림 식별자에 학년, 반 정보 포함
        let identifier = "schedule-g\(grade)-c\(classNumber)-d\(weekday)-p\(schedule.classTime)"
        
        // 알림 내용 설정
        let notificationContent = createNotificationContent(schedule: schedule)
        
        // 알림 트리거 생성
        let trigger = createNotificationTrigger(weekday: weekday, classTime: schedule.classTime)
        
        // 알림 요청 생성 및 등록
        let request = UNNotificationRequest(
            identifier: identifier,
            content: notificationContent,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 설정 실패: \(error)")
            }
        }
    }
    
    // 알림 내용 생성
    private func createNotificationContent(schedule: ScheduleItem) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(schedule.classTime)교시 수업 알림 (10분 전)"
        
        var displaySubject = schedule.subject
        var displayLocation = schedule.teacher
        
        // 탐구 과목 치환 로직
        if schedule.subject.contains("반") {
            let customKey = "selected\(schedule.subject)Subject"
            if let selectedSubject = UserDefaults.standard.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != schedule.subject {
                
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displaySubject = components[0]
                    displayLocation = components[1]
                }
            }
        }
        
        // 알림 내용 설정
        if !displayLocation.contains("T") {
            if displaySubject.contains("반") {
                content.body = "\(schedule.classTime)교시 \(displaySubject) 수업입니다. (설정필요)"
            } else {
                content.body = "\(schedule.classTime)교시 \(displaySubject) 수업입니다. \(displayLocation) 교실입니다."
            }
        } else {
            content.body = "\(schedule.classTime)교시 \(displaySubject) 수업입니다. 교실수업입니다."
        }
        
        content.sound = UNNotificationSound.default
        return content
    }
    
    // 알림 트리거 생성
    private func createNotificationTrigger(weekday: Int, classTime: Int) -> UNCalendarNotificationTrigger {
        // 알림은 수업 시작 10분 전에 발생하도록 설정
        let periodTimes: [(hour: Int, minute: Int)] = [
            (8, 20), (9, 20), (10, 20), (11, 20), (13, 10), (14, 10), (15, 10)
        ]
        
        guard classTime >= 1 && classTime <= periodTimes.count else {
            // 기본값으로 8시 10분 설정
            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 10
            dateComponents.weekday = weekday
            return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        }
        
        let startTime = periodTimes[classTime - 1]
        
        // 10분 전 알림 시간 계산
        var notificationHour = startTime.hour
        var notificationMinute = startTime.minute - 10
        
        // 분이 음수가 되는 경우 시간 조정
        if notificationMinute < 0 {
            notificationHour -= 1
            notificationMinute += 60
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute
        dateComponents.weekday = weekday
        
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }
    
    // 시간표 데이터 업데이트 후 위젯 타임라인 갱신
    func updateWidgetTimelines() {
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// ScheduleManager.swift에 추가할 메서드

// 화면 표시용 임시 저장소 키
private let displayStoreKey = "schedule_display_store"

// 화면 표시용 시간표 데이터 저장
func saveToDisplayStore(_ data: ScheduleData) {
    do {
        let encoded = try JSONEncoder().encode(data)
        UserDefaults.standard.set(encoded, forKey: displayStoreKey)
        
        // 위젯용 공유 UserDefaults에도 저장
        SharedUserDefaults.shared.userDefaults.set(encoded, forKey: displayStoreKey)
    } catch {
        print("디스플레이 저장소 저장 실패: \(error)")
    }
}

// 화면 표시용 시간표 데이터 로드
func loadDisplayStore() -> ScheduleData? {
    guard let data = UserDefaults.standard.data(forKey: displayStoreKey) else {
        return nil
    }
    
    do {
        return try JSONDecoder().decode(ScheduleData.self, from: data)
    } catch {
        print("디스플레이 저장소 로드 실패: \(error)")
        return nil
    }
}

// 화면 표시용 시간표 가져오기 (알림 설정에 영향 없음)
func fetchScheduleForDisplay(grade: Int, classNumber: Int, completion: @escaping ([[ScheduleItem]]?) -> Void) {
    // 서버에서 시간표 가져오기
    let urlString = "https://comsi.helgisnw.me/\(grade)/\(classNumber)"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        completion(nil)
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data,
              error == nil else {
            print("시간표 데이터 요청 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        do {
            // 서버 응답 데이터 파싱
            let schedules = try JSONDecoder().decode([[ScheduleItem]].self, from: data)
            
            // 메타데이터를 포함한 새 데이터 객체 생성
            let newScheduleData = ScheduleData(
                grade: grade,
                classNumber: classNumber,
                lastUpdated: Date(),
                schedules: schedules
            )
            
            // 디스플레이 저장소에 저장
            do {
                let encoded = try JSONEncoder().encode(newScheduleData)
                UserDefaults.standard.set(encoded, forKey: "schedule_display_store")
                
                // 위젯용 공유 UserDefaults에도 저장
                SharedUserDefaults.shared.userDefaults.set(encoded, forKey: "schedule_display_store")
            } catch {
                print("디스플레이 저장소 저장 실패: \(error)")
            }
            
            DispatchQueue.main.async {
                completion(schedules)
                
                // 위젯 타임라인 갱신
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("시간표 데이터 파싱 실패: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }.resume()
}

// 알림 초기화 및 재설정 - self 참조 제거 버전
func resetNotifications(scheduleData: ScheduleData, completion: @escaping (Bool) -> Void) {
    // 1. 모든 알림 삭제
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    
    // 2. 알림 시스템이 업데이트되기를 보장하기 위한 짧은 지연
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        // 3. 알림이 활성화되어 있는지 확인
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if !notificationsEnabled {
            completion(true)
            return
        }
        
        // 4. 새 알림 스케줄링 - 클로저 내부에서 scheduleNotifications 직접 호출
        let schedules = scheduleData.schedules
        let grade = scheduleData.grade
        let classNumber = scheduleData.classNumber
        
        // 주간 스케줄 기준으로 알림 설정
        for (weekdayIndex, daySchedule) in schedules.enumerated() {
            let weekday = weekdayIndex + 2 // API의 주간 스케줄이 월요일(2)부터 시작
            if weekday > 7 || daySchedule.isEmpty {
                continue // 토요일, 일요일 또는 비어있는 스케줄 무시
            }
            
            // 해당 요일의 모든 수업에 대해 알림 설정
            for schedule in daySchedule {
                // 수업이 있는 시간만 알림 설정
                if !schedule.subject.isEmpty {
                    // 알림 식별자에 학년, 반 정보 포함
                    let identifier = "schedule-g\(grade)-c\(classNumber)-d\(weekday)-p\(schedule.classTime)"
                    
                    // 알림 내용 설정
                    let content = UNMutableNotificationContent()
                    content.title = "\(schedule.classTime)교시 수업 알림 (10분 전)"
                    
                    var displaySubject = schedule.subject
                    var displayLocation = schedule.teacher
                    
                    // 탐구 과목 치환 로직
                    if schedule.subject.contains("반") {
                        let customKey = "selected\(schedule.subject)Subject"
                        if let selectedSubject = UserDefaults.standard.string(forKey: customKey),
                           selectedSubject != "선택 없음" && selectedSubject != schedule.subject {
                            
                            let components = selectedSubject.components(separatedBy: "/")
                            if components.count == 2 {
                                displaySubject = components[0]
                                displayLocation = components[1]
                            }
                        }
                    }
                    
                    // 알림 내용 설정
                    if !displayLocation.contains("T") {
                        if displaySubject.contains("반") {
                            content.body = "\(schedule.classTime)교시 \(displaySubject) 수업입니다. (설정필요)"
                        } else {
                            content.body = "\(schedule.classTime)교시 \(displaySubject) 수업입니다. \(displayLocation) 교실입니다."
                        }
                    } else {
                        content.body = "\(schedule.classTime)교시 \(displaySubject) 수업입니다. 교실수업입니다."
                    }
                    
                    content.sound = UNNotificationSound.default
                    
                    // 알림 트리거 생성
                    // 알림은 수업 시작 10분 전에 발생하도록 설정
                    let periodTimes: [(hour: Int, minute: Int)] = [
                        (8, 20), (9, 20), (10, 20), (11, 20), (13, 10), (14, 10), (15, 10)
                    ]
                    
                    let classTime = schedule.classTime
                    guard classTime >= 1 && classTime <= periodTimes.count else {
                        continue
                    }
                    
                    let startTime = periodTimes[classTime - 1]
                    
                    // 10분 전 알림 시간 계산
                    var notificationHour = startTime.hour
                    var notificationMinute = startTime.minute - 10
                    
                    // 분이 음수가 되는 경우 시간 조정
                    if notificationMinute < 0 {
                        notificationHour -= 1
                        notificationMinute += 60
                    }
                    
                    var dateComponents = DateComponents()
                    dateComponents.hour = notificationHour
                    dateComponents.minute = notificationMinute
                    dateComponents.weekday = weekday
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    
                    // 알림 요청 생성 및 등록
                    let request = UNNotificationRequest(
                        identifier: identifier,
                        content: content,
                        trigger: trigger
                    )
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("알림 설정 실패: \(error)")
                        }
                    }
                }
            }
        }
        
        // 5. 체육 수업 알림 업데이트
        if UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled") {
            PhysicalEducationAlertManager.shared.scheduleAlerts()
        }
        
        // 6. 위젯 타임라인 갱신
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        WidgetCenter.shared.reloadAllTimelines()
        
        completion(true)
    }
}
