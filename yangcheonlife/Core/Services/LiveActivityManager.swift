import Foundation
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

/// iOS 18+ Live Activity 관리 클래스 (완전 새 아키텍처)
@available(iOS 18.0, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    #if canImport(ActivityKit)
    @Published var currentActivity: Activity<ClassActivityAttributes>?
    #endif
    
    /// Live Activity가 실행 중인지 확인
    var isActivityRunning: Bool {
        #if canImport(ActivityKit)
        if let activity = currentActivity {
            let state = activity.activityState
            if state == .ended || state == .dismissed {
                currentActivity = nil
                return false
            }
            return state == .active
        }
        // currentActivity가 nil이면 시스템에서 활성 Activity 찾기
        let activeActivities = Activity<ClassActivityAttributes>.activities.filter { $0.activityState == .active }
        if let foundActivity = activeActivities.first {
            currentActivity = foundActivity
            return true
        }
        #endif
        return false
    }
    
    private init() {
        #if canImport(ActivityKit)
        // 앱 시작 시 기존 활성 상태인 Live Activity 찾기
        if let existingActivity = Activity<ClassActivityAttributes>.activities.first {
            currentActivity = existingActivity
            print("🔍 Found existing Live Activity: \(existingActivity.activityState)")
        }
        
        #endif
    }
    
    /// Live Activity 시작 (앱 내부 시작도 지원)
    func startLiveActivity(grade: Int, classNumber: Int) {
        #if canImport(ActivityKit)
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities are not enabled")
            return
        }
        
        // 기존 활동이 있으면 종료
        stopLiveActivity()
        
        let attributes = ClassActivityAttributes(schoolId: "yangcheon")
        let (startDate, endDate) = getCurrentPeriodTimes()
        let initialState = ClassActivityAttributes.ContentState(
            currentStatus: getCurrentStatus(),
            currentClass: getCurrentClass(),
            nextClass: getNextClass(),
            startDate: startDate.timeIntervalSince1970,
            endDate: endDate.timeIntervalSince1970,
            lastUpdated: Date().timeIntervalSince1970
        )
        
        do {
            let activity = try Activity<ClassActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: getNextStaleDate()),
                pushType: .none
            )
            
            DispatchQueue.main.async {
                self.currentActivity = activity
            }
            
            print("✅ Live Activity started successfully from app")
            
            
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
        #endif
    }
    
    /// Live Activity 업데이트
    func updateLiveActivity() {
        #if canImport(ActivityKit)
        // currentActivity가 nil이면 활성 Activity 다시 찾기
        if currentActivity == nil {
            let activeActivities = Activity<ClassActivityAttributes>.activities.filter { $0.activityState == .active }
            if let foundActivity = activeActivities.first {
                currentActivity = foundActivity
                print("🔍 Found existing Live Activity for update: \(foundActivity.activityState)")
            }
        }
        
        guard let activity = currentActivity else {
            print("❌ No current activity to update")
            return
        }
        
        let (startDate, endDate) = getCurrentPeriodTimes()
        let newState = ClassActivityAttributes.ContentState(
            currentStatus: getCurrentStatus(),
            currentClass: getCurrentClass(),
            nextClass: getNextClass(),
            startDate: startDate.timeIntervalSince1970,
            endDate: endDate.timeIntervalSince1970,
            lastUpdated: Date().timeIntervalSince1970
        )
        
        Task {
            do {
                let staleDate = getNextStaleDate()
                await activity.update(ActivityContent(state: newState, staleDate: staleDate))
                print("✅ Live Activity updated successfully")
            } catch {
                print("❌ Live Activity update failed: \(error)")
            }
        }
        #endif
    }
    
    /// 백그라운드 전용 Live Activity 강제 업데이트 (재시도 로직 포함)
    func updateLiveActivityInBackground() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else {
            print("❌ [Background Update] No current activity to update")
            return
        }
        
        let startTime = Date()
        print("🔄 [Background Update] Live Activity 업데이트 시작: \(startTime)")
        print("🔄 [Background Update] Activity ID: \(activity.id)")
        print("🔄 [Background Update] Activity State: \(activity.activityState)")
        
        let (startDate, endDate) = getCurrentPeriodTimes()
        let newState = ClassActivityAttributes.ContentState(
            currentStatus: getCurrentStatus(),
            currentClass: getCurrentClass(),
            nextClass: getNextClass(),
            startDate: startDate.timeIntervalSince1970,
            endDate: endDate.timeIntervalSince1970,
            lastUpdated: Date().timeIntervalSince1970
        )
        
        print("🔄 [Background Update] State Data:")
        print("   - Status: \(newState.currentStatus)")
        print("   - Current Class: \(newState.currentClass?.subject ?? "None")")
        print("   - Next Class: \(newState.nextClass?.subject ?? "None")")
        print("   - End Date: \(Date(timeIntervalSince1970: newState.endDate))")
        
        Task {
            await performBackgroundUpdateWithRetry(activity: activity, newState: newState, startTime: startTime)
        }
        #endif
    }
    
    /// 백그라운드 업데이트 재시도 로직
    #if canImport(ActivityKit)
    private func performBackgroundUpdateWithRetry(activity: Activity<ClassActivityAttributes>, newState: ClassActivityAttributes.ContentState, startTime: Date, retryCount: Int = 0) async {
        let maxRetries = 3
        let staleDate = getNextStaleDate()
        
        do {
            await activity.update(ActivityContent(state: newState, staleDate: staleDate))
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [Background Update] Live Activity 업데이트 성공 (\(String(format: "%.2f", duration))s)")
            if retryCount > 0 {
                print("✅ [Background Update] Retry \(retryCount) succeeded")
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("❌ [Background Update] Live Activity 업데이트 실패 (\(String(format: "%.2f", duration))s): \(error)")
            
            if retryCount < maxRetries {
                let delay = Double(retryCount + 1) * 2.0  // 2초, 4초, 6초 대기
                print("🔄 [Background Update] Retry \(retryCount + 1)/\(maxRetries) in \(delay)s...")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await performBackgroundUpdateWithRetry(activity: activity, newState: newState, startTime: startTime, retryCount: retryCount + 1)
            } else {
                print("❌ [Background Update] All retries failed - giving up")
            }
        }
    }
    #endif
    
    /// Live Activity 종료
    func stopLiveActivity() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }
        
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
            if period == 5 {
                return .breakTime
            } else {
                return .preClass
            }
        case .afterSchool:
            return .afterSchool
        }
    }
    
    private func getCurrentClass() -> ClassInfo? {
        guard let currentPeriod = TimeUtility.getCurrentPeriodNumber() else { return nil }
        
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
    
    private func getNextClass() -> ClassInfo? {
        let weekdayIndex = TimeUtility.getCurrentWeekdayIndex()
        guard weekdayIndex >= 0 else { return nil }
        
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        guard let data = sharedDefaults.data(forKey: "schedule_data_store"),
              let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data) else {
            return nil
        }
        
        let dailySchedule = scheduleData.getDailySchedule(for: weekdayIndex)
        let timeStatus = TimeUtility.getCurrentPeriodStatus()
        var nextPeriod: Int?
        
        switch timeStatus {
        case .beforeSchool:
            nextPeriod = 1
        case .inClass(let period):
            if period == 4 {
                return nil
            }
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
        
        return nil
    }
    
    private func getCurrentPeriodTimes() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        let timeStatus = TimeUtility.getCurrentPeriodStatus()
        
        let periodTimes = [
            (start: (8, 20), end: (9, 10)),   // 1교시
            (start: (9, 20), end: (10, 10)),  // 2교시  
            (start: (10, 20), end: (11, 10)), // 3교시
            (start: (11, 20), end: (12, 10)), // 4교시
            (start: (13, 10), end: (14, 0)),  // 5교시
            (start: (14, 10), end: (15, 0)),  // 6교시
            (start: (15, 10), end: (16, 0))   // 7교시
        ]
        
        switch timeStatus {
        case .inClass(let period):
            if period >= 1 && period <= 7 {
                let periodTime = periodTimes[period - 1]
                let startDate = calendar.date(bySettingHour: periodTime.start.0, minute: periodTime.start.1, second: 0, of: now) ?? now
                let endDate = calendar.date(bySettingHour: periodTime.end.0, minute: periodTime.end.1, second: 0, of: now) ?? now
                return (startDate, endDate)
            }
            
        case .breakTime(let nextPeriod):
            if nextPeriod >= 2 && nextPeriod <= 7 {
                let prevPeriodTime = periodTimes[nextPeriod - 2]
                let nextPeriodTime = periodTimes[nextPeriod - 1]
                let startDate = calendar.date(bySettingHour: prevPeriodTime.end.0, minute: prevPeriodTime.end.1, second: 0, of: now) ?? now
                let endDate = calendar.date(bySettingHour: nextPeriodTime.start.0, minute: nextPeriodTime.start.1, second: 0, of: now) ?? now
                return (startDate, endDate)
            }
            
        case .lunchTime:
            let startDate = calendar.date(bySettingHour: 12, minute: 10, second: 0, of: now) ?? now
            let endDate = calendar.date(bySettingHour: 13, minute: 10, second: 0, of: now) ?? now
            return (startDate, endDate)
            
        case .preClass(let period):
            if period >= 1 && period <= 7 {
                let periodTime = periodTimes[period - 1]
                let endDate = calendar.date(bySettingHour: periodTime.start.0, minute: periodTime.start.1, second: 0, of: now) ?? now
                return (now, endDate)
            }
            
        case .beforeSchool:
            let endDate = calendar.date(bySettingHour: 8, minute: 20, second: 0, of: now) ?? now
            return (now, endDate)
            
        case .afterSchool:
            let startDate = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? now
            return (startDate, endDate)
        }
        
        return (now, calendar.date(byAdding: .hour, value: 1, to: now) ?? now)
    }
    
    private func getNextStaleDate() -> Date {
        let interval: TimeInterval = 300 // 5분
        return Date().addingTimeInterval(interval)
    }
    
    /// 교시 변화 시 Live Activity 업데이트 (수동 시작된 경우만)
    func updateOnClassPeriodChange() {
        // 이미 실행 중인 Live Activity만 업데이트 (자동 시작 안함)
        if isActivityRunning {
            updateLiveActivity()
        }
    }
    
    /// 앱 포그라운드 진입시 Live Activity 상태 체크 (수동 시작된 경우만)
    func checkLiveActivityOnForeground() {
        // 이미 실행 중인 Live Activity만 업데이트 (자동 시작 안함)
        if isActivityRunning {
            updateLiveActivity()
        }
    }
}
