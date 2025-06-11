import Foundation
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

/// Live Activity 관리 클래스
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    #if canImport(ActivityKit)
    private var _currentActivity: Any?
    
    @available(iOS 18.0, *)
    var currentActivity: Activity<ClassActivityAttributes>? {
        get { _currentActivity as? Activity<ClassActivityAttributes> }
        set { 
            _currentActivity = newValue
            objectWillChange.send()
        }
    }
    #endif
    
    /// Live Activity가 실행 중인지 확인
    var isActivityRunning: Bool {
        #if canImport(ActivityKit)
        if #available(iOS 18.0, *) {
            return currentActivity != nil && currentActivity?.activityState == .active
        }
        #endif
        return false
    }
    
    private init() {
        #if canImport(ActivityKit)
        if #available(iOS 18.0, *) {
            // 앱 시작 시 기존 활성 상태인 Live Activity 찾기
            if let existingActivity = Activity<ClassActivityAttributes>.activities.first {
                currentActivity = existingActivity
            }
        }
        #endif
    }
    
    /// Live Activity 시작
    func startLiveActivity(grade: Int, classNumber: Int) {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else { 
            print("❌ iOS 18.0 이상이 필요합니다. 현재 iOS 버전이 지원되지 않습니다.")
            return 
        }
        
        // Extension에서는 앱 상태 확인을 스킵
        #if !EXTENSION
        startLiveActivityWithRetry(grade: grade, classNumber: classNumber)
        #else
        performStartLiveActivity(grade: grade, classNumber: classNumber)
        #endif
        #endif
    }
    
    /// 재시도 로직이 포함된 Live Activity 시작
    private func startLiveActivityWithRetry(grade: Int, classNumber: Int, attempt: Int = 1) {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else { return }
        
        let appState = UIApplication.shared.applicationState
        print("🔍 Live Activity 시작 시도 #\(attempt) - 앱 상태: \(appState == .active ? "Active" : appState == .inactive ? "Inactive" : "Background")")
        
        // 앱이 활성 상태가 아니고 시도 횟수가 3회 미만이면 0.5초 후 재시도
        if appState != .active && attempt < 3 {
            print("⏱️ 앱이 완전히 활성화될 때까지 0.5초 대기 후 재시도...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startLiveActivityWithRetry(grade: grade, classNumber: classNumber, attempt: attempt + 1)
            }
            return
        }
        
        // 3번 시도 후에도 활성 상태가 아니면 경고만 출력하고 계속 진행
        if appState != .active {
            print("⚠️ 앱이 완전히 활성화되지 않았지만 Live Activity 시작을 시도합니다.")
        }
        
        performStartLiveActivity(grade: grade, classNumber: classNumber)
        #endif
    }
    
    /// 실제 Live Activity 시작 로직
    private func performStartLiveActivity(grade: Int, classNumber: Int) {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else { return }
        
        let authInfo = ActivityAuthorizationInfo()
        print("🔍 Live Activity Authorization Status: \(authInfo.areActivitiesEnabled)")
        print("🔍 Live Activity 기기 설정 상태:")
        print("   - Device supports Live Activities: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        print("   - Current activities count: \(Activity<ClassActivityAttributes>.activities.count)")
        #if !EXTENSION
        let appState = UIApplication.shared.applicationState
        print("   - App State: \(appState == .active ? "Active (포그라운드)" : appState == .inactive ? "Inactive" : "Background")")
        #else
        print("   - App State: Extension (상태 확인 불가)")
        #endif
        
        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities are not enabled")
            print("❌ 해결 방법: 설정 > 개인정보 보호 및 보안 > Live Activities 활성화")
            print("❌ 또는 설정 > 알림 > Live Activities 활성화")
            return
        }
        
        print("✅ Live Activity 권한 확인 완료 - 시작 가능")
        
        // 기존 활동이 있으면 종료
        stopLiveActivity()
        
        let attributes = ClassActivityAttributes(grade: grade, classNumber: classNumber)
        let initialState = ClassActivityAttributes.ContentState(
            currentStatus: getCurrentStatus(),
            currentClass: getCurrentClass(),
            nextClass: getNextClass(),
            remainingMinutes: getRemainingMinutes(),
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity<ClassActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            DispatchQueue.main.async {
                self.currentActivity = activity
            }
            print("✅ Live Activity started successfully")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
        #endif
    }
    
    /// Live Activity 업데이트
    func updateLiveActivity() {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *),
              let activity = currentActivity else { return }
        
        let newState = ClassActivityAttributes.ContentState(
            currentStatus: getCurrentStatus(),
            currentClass: getCurrentClass(),
            nextClass: getNextClass(),
            remainingMinutes: getRemainingMinutes(),
            lastUpdated: Date()
        )
        
        Task {
            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }
        #endif
    }
    
    /// Live Activity 종료
    func stopLiveActivity() {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *),
              let activity = currentActivity else { return }
        
        // UI 즉시 업데이트를 위해 먼저 nil로 설정
        DispatchQueue.main.async {
            self.currentActivity = nil
        }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        #endif
    }
    
    /// 모든 Live Activity 종료
    func stopAllActivities() {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else { return }
        
        // UI 즉시 업데이트를 위해 먼저 nil로 설정
        DispatchQueue.main.async {
            self.currentActivity = nil
        }
        
        Task {
            for activity in Activity<ClassActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
    
    // MARK: - Helper Methods
    
    @available(iOS 18.0, *)
    private func getCurrentStatus() -> ClassStatus {
        let timeStatus = TimeUtility.getCurrentPeriodStatus()
        
        switch timeStatus {
        case .beforeSchool:
            return .beforeSchool
        case .inClass(_):
            return .inClass
        case .breakTime(_):
            return .breakTime
        case .lunchTime:
            return .lunchTime
        case .preClass(let period):
            // 5교시 전 (13:00 ~ 13:10)은 쉬는시간으로 표시
            if period == 5 {
                return .breakTime
            } else {
                return .preClass
            }
        case .afterSchool:
            return .afterSchool
        }
    }
    
    @available(iOS 18.0, *)
    private func getCurrentClass() -> ClassInfo? {
        guard let currentPeriod = TimeUtility.getCurrentPeriodNumber() else { return nil }
        
        // UserDefaults에서 시간표 데이터 가져오기
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        guard let data = sharedDefaults.data(forKey: "schedule_data_store"),
              let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data) else {
            return nil
        }
        
        let weekdayIndex = TimeUtility.getCurrentWeekdayIndex()
        guard weekdayIndex >= 0 else { return nil }
        
        let dailySchedule = scheduleData.getDailySchedule(for: weekdayIndex)
        guard let scheduleItem = dailySchedule.first(where: { $0.period == currentPeriod }) else {
            return nil
        }
        
        let timeString = TimeUtility.getPeriodTimeString(period: currentPeriod)
        let timeComponents = timeString.components(separatedBy: " - ")
        
        return ClassInfo(
            period: currentPeriod,
            subject: scheduleItem.subject,
            classroom: scheduleItem.classroom,
            startTime: timeComponents.first ?? "",
            endTime: timeComponents.last ?? ""
        )
    }
    
    @available(iOS 18.0, *)
    private func getNextClass() -> ClassInfo? {
        let weekdayIndex = TimeUtility.getCurrentWeekdayIndex()
        guard weekdayIndex >= 0 else { return nil }
        
        // UserDefaults에서 시간표 데이터 가져오기
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        guard let data = sharedDefaults.data(forKey: "schedule_data_store"),
              let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data) else {
            return nil
        }
        
        let dailySchedule = scheduleData.getDailySchedule(for: weekdayIndex)
        
        // 현재 상태에 따라 다음 교시 결정
        let timeStatus = TimeUtility.getCurrentPeriodStatus()
        var nextPeriod: Int?
        
        switch timeStatus {
        case .beforeSchool:
            nextPeriod = 1
        case .inClass(let period):
            // 4교시 중이면 다음은 점심시간이므로 nil 반환
            if period == 4 {
                return nil
            }
            // 7교시 중이면 학교 끝 표시
            if period == 7 {
                return ClassInfo(
                    period: 8,
                    subject: "학교 끝!",
                    classroom: "",
                    startTime: "",
                    endTime: ""
                )
            }
            nextPeriod = period + 1
        case .breakTime(let period):
            nextPeriod = period
        case .preClass(let period):
            nextPeriod = period
        case .lunchTime:
            nextPeriod = 5
        case .afterSchool:
            return nil
        }
        
        guard let targetPeriod = nextPeriod else { return nil }
        
        // 현재일 대상 교시부터 7교시까지 찾기
        if targetPeriod <= 7 {
            for period in targetPeriod...7 {
                if let scheduleItem = dailySchedule.first(where: { $0.period == period }) {
                    let timeString = TimeUtility.getPeriodTimeString(period: period)
                    let timeComponents = timeString.components(separatedBy: " - ")
                    
                    return ClassInfo(
                        period: period,
                        subject: scheduleItem.subject,
                        classroom: scheduleItem.classroom,
                        startTime: timeComponents.first ?? "",
                        endTime: timeComponents.last ?? ""
                    )
                }
            }
        }
        
        // 현재일에서 수업을 찾지 못했으면 다음 수업일의 1교시부터 찾기
        let nextSchoolDay = TimeUtility.getNextSchoolDay()
        let nextWeekdayIndex = TimeUtility.getCurrentWeekdayIndex(at: nextSchoolDay)
        
        if nextWeekdayIndex >= 0 {
            let nextDaySchedule = scheduleData.getDailySchedule(for: nextWeekdayIndex)
            
            // 다음날 1교시부터 7교시까지 찾기
            for period in 1...7 {
                if let scheduleItem = nextDaySchedule.first(where: { $0.period == period }) {
                    let timeString = TimeUtility.getPeriodTimeString(period: period)
                    let timeComponents = timeString.components(separatedBy: " - ")
                    
                    return ClassInfo(
                        period: period,
                        subject: scheduleItem.subject,
                        classroom: scheduleItem.classroom,
                        startTime: timeComponents.first ?? "",
                        endTime: timeComponents.last ?? ""
                    )
                }
            }
        }
        
        return nil
    }
    
    private func getRemainingMinutes() -> Int {
        return TimeUtility.getMinutesUntilNextClass() ?? 0
    }
}
