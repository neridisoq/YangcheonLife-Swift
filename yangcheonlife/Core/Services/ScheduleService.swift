import Foundation
import UserNotifications
import WidgetKit

// MARK: - 시간표 서비스
/// 시간표 데이터 관리 및 알림 처리를 담당하는 서비스
class ScheduleService: ObservableObject {
    
    static let shared = ScheduleService()
    
    // MARK: - Properties
    @Published var currentScheduleData: ScheduleData?
    @Published var isLoading = false
    @Published var lastError: Error?
    
    private let userDefaults = UserDefaults.standard
    private let sharedUserDefaults = SharedUserDefaults.shared
    
    private init() {
        loadCurrentSchedule()
    }
    
    // MARK: - Public Methods
    
    /// 시간표 데이터 로드 (로컬 우선, 필요시 서버에서 가져오기)
    func loadSchedule(grade: Int, classNumber: Int, forceRefresh: Bool = false) async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            if !forceRefresh {
                // 로컬 데이터 먼저 확인
                if let localData = loadLocalSchedule(),
                   localData.grade == grade && localData.classNumber == classNumber {
                    await MainActor.run {
                        currentScheduleData = localData
                        isLoading = false
                    }
                    return
                }
            }
            
            // 서버에서 새 데이터 가져오기
            let newData = try await fetchScheduleFromServer(grade: grade, classNumber: classNumber)
            
            await MainActor.run {
                currentScheduleData = newData
                isLoading = false
            }
            
            // 로컬에 저장
            saveScheduleData(newData)
            
            // 위젯 업데이트
            updateWidgets()
            
        } catch {
            await MainActor.run {
                lastError = error
                isLoading = false
            }
        }
    }
    
    /// 현재 수업 정보 가져오기
    func getCurrentClassInfo(at date: Date = Date()) -> ScheduleItem? {
        guard let scheduleData = currentScheduleData else { return nil }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 2 // 월요일: 0
        
        guard weekday >= 0 && weekday < 5 else { return nil } // 주말 제외
        
        let status = CurrentPeriodStatus.getCurrentStatus(at: date)
        
        switch status {
        case .inClass(let period), .preClass(let period):
            return scheduleData.getClassInfo(weekday: weekday, period: period)
        default:
            return nil
        }
    }
    
    /// 다음 수업 정보 가져오기
    func getNextClassInfo(at date: Date = Date()) -> ScheduleItem? {
        guard let scheduleData = currentScheduleData else { return nil }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 2
        
        guard weekday >= 0 && weekday < 5 else { return nil }
        
        let status = CurrentPeriodStatus.getCurrentStatus(at: date)
        
        switch status {
        case .breakTime(let nextPeriod), .preClass(let nextPeriod):
            return scheduleData.getClassInfo(weekday: weekday, period: nextPeriod)
        case .beforeSchool:
            return scheduleData.getClassInfo(weekday: weekday, period: 1)
        default:
            return nil
        }
    }
    
    /// 알림 설정 업데이트
    func updateNotifications(grade: Int, classNumber: Int) async {
        guard userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) else {
            await removeAllNotifications()
            return
        }
        
        do {
            // 최신 시간표 데이터 가져오기
            let scheduleData = try await fetchScheduleFromServer(grade: grade, classNumber: classNumber)
            
            // 기존 알림 제거
            await removeAllNotifications()
            
            // 새 알림 스케줄링
            await scheduleNotifications(scheduleData: scheduleData)
            
            // 데이터 저장
            saveScheduleData(scheduleData)
            
        } catch {
            print("❌ 알림 업데이트 실패: \(error)")
        }
    }
    
    /// 강제 새로고침
    func forceRefresh() {
        let grade = userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        let classNumber = userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        guard grade > 0 && classNumber > 0 else { return }
        
        Task {
            await loadSchedule(grade: grade, classNumber: classNumber, forceRefresh: true)
        }
    }
    
    // MARK: - Private Methods
    
    /// 로컬 시간표 데이터 로드
    private func loadLocalSchedule() -> ScheduleData? {
        guard let data = userDefaults.data(forKey: AppConstants.UserDefaultsKeys.scheduleDataStore) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(ScheduleData.self, from: data)
        } catch {
            print("❌ 로컬 시간표 로드 실패: \(error)")
            return nil
        }
    }
    
    /// 현재 저장된 시간표 로드
    private func loadCurrentSchedule() {
        currentScheduleData = loadLocalSchedule()
    }
    
    /// 서버에서 시간표 데이터 가져오기
    private func fetchScheduleFromServer(grade: Int, classNumber: Int) async throws -> ScheduleData {
        let urlString = AppConstants.API.scheduleURL(grade: grade, classNumber: classNumber)
        guard let url = URL(string: urlString) else {
            throw ScheduleError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ScheduleError.serverError
        }
        
        // 기존 형식의 데이터 파싱 ([[ScheduleItem]])
        let schedules = try JSONDecoder().decode([[ScheduleItem]].self, from: data)
        
        return ScheduleData(
            grade: grade,
            classNumber: classNumber,
            lastUpdated: Date(),
            weeklySchedule: schedules
        )
    }
    
    /// 시간표 데이터 저장
    private func saveScheduleData(_ data: ScheduleData) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            
            // 로컬 UserDefaults에 저장
            userDefaults.set(encodedData, forKey: AppConstants.UserDefaultsKeys.scheduleDataStore)
            
            // 위젯용 공유 UserDefaults에 저장
            sharedUserDefaults.userDefaults.set(encodedData, forKey: AppConstants.UserDefaultsKeys.scheduleDataStore)
            
        } catch {
            print("❌ 시간표 데이터 저장 실패: \(error)")
        }
    }
    
    /// 알림 스케줄링
    private func scheduleNotifications(scheduleData: ScheduleData) async {
        let notificationCenter = UNUserNotificationCenter.current()
        
        for (weekdayIndex, dailySchedule) in scheduleData.weeklySchedule.enumerated() {
            let weekday = weekdayIndex + 2 // 월요일: 2, 화요일: 3, ...
            
            guard weekday <= 6 else { continue } // 토요일까지만
            
            for scheduleItem in dailySchedule {
                guard !scheduleItem.subject.isEmpty else { continue }
                
                let identifier = AppConstants.Notification.scheduleIdentifier(
                    grade: scheduleData.grade,
                    classNumber: scheduleData.classNumber,
                    weekday: weekday,
                    period: scheduleItem.period
                )
                
                let content = createNotificationContent(for: scheduleItem)
                let trigger = createNotificationTrigger(weekday: weekday, period: scheduleItem.period)
                
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await notificationCenter.add(request)
                } catch {
                    print("❌ 알림 등록 실패: \(error)")
                }
            }
        }
    }
    
    /// 알림 콘텐츠 생성
    private func createNotificationContent(for scheduleItem: ScheduleItem) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(scheduleItem.period)교시 수업 알림 (10분 전)"
        
        var displaySubject = scheduleItem.subject
        var displayLocation = scheduleItem.classroom
        
        // 탐구 과목 치환 로직
        if scheduleItem.subject.contains("반") {
            let customKey = AppConstants.UserDefaultsKeys.selectedSubjectKey(for: scheduleItem.subject)
            
            if let selectedSubject = userDefaults.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
                
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
                content.body = "\(scheduleItem.period)교시 \(displaySubject) 수업입니다. (설정필요)"
            } else {
                content.body = "\(scheduleItem.period)교시 \(displaySubject) 수업입니다. \(displayLocation) 교실입니다."
            }
        } else {
            content.body = "\(scheduleItem.period)교시 \(displaySubject) 수업입니다. 교실수업입니다."
        }
        
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notification.categoryIdentifier
        
        return content
    }
    
    /// 알림 트리거 생성
    private func createNotificationTrigger(weekday: Int, period: Int) -> UNCalendarNotificationTrigger {
        guard period >= 1 && period <= PeriodTime.allPeriods.count else {
            // 기본값
            var components = DateComponents()
            components.hour = 8
            components.minute = 10
            components.weekday = weekday
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        
        let periodTime = PeriodTime.allPeriods[period - 1]
        
        // 10분 전 알림 시간 계산
        var notificationHour = periodTime.startTime.hour
        var notificationMinute = periodTime.startTime.minute - AppConstants.Notification.beforeClassMinutes
        
        if notificationMinute < 0 {
            notificationHour -= 1
            notificationMinute += 60
        }
        
        var components = DateComponents()
        components.hour = notificationHour
        components.minute = notificationMinute
        components.weekday = weekday
        
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }
    
    /// 모든 알림 제거
    private func removeAllNotifications() async {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// 위젯 업데이트
    private func updateWidgets() {
        sharedUserDefaults.synchronizeFromStandardUserDefaults()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - 시간표 에러 타입
enum ScheduleError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .serverError:
            return "서버 오류가 발생했습니다."
        case .decodingError:
            return "데이터 파싱 오류가 발생했습니다."
        case .noData:
            return "시간표 데이터가 없습니다."
        }
    }
}