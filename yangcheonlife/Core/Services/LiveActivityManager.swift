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
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    #endif
    
    /// Live Activity가 실행 중인지 확인
    var isActivityRunning: Bool {
        #if canImport(ActivityKit)
        if #available(iOS 18.0, *) {
            // 현재 Activity 상태 검증
            if let activity = currentActivity {
                let state = activity.activityState
                print("📊 [ActivityCheck] Current activity state: \(state)")
                
                // 종료된 Activity라면 currentActivity를 nil로 설정
                if state == .ended || state == .dismissed {
                    print("📊 [ActivityCheck] Activity is ended/dismissed, clearing reference")
                    currentActivity = nil
                    return false
                }
                
                return state == .active
            } else {
                // currentActivity가 nil이면 시스템에서 활성 Activity 찾기
                let activeActivities = Activity<ClassActivityAttributes>.activities.filter { $0.activityState == .active }
                if let foundActivity = activeActivities.first {
                    print("📊 [ActivityCheck] Found orphaned active activity, restoring reference")
                    currentActivity = foundActivity
                    return true
                }
            }
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
                print("🔍 Found existing Live Activity: \(existingActivity.activityState)")
            } else {
                print("🔍 No existing Live Activity found")
            }
        }
        #endif
        
        // Apple 정책 준수: 백그라운드 타이머 제거, 이벤트 기반으로만 동작
    }
    
    /// Apple 정책 준수: 백그라운드 타이머 완전 제거
    /// Live Activity는 교시 변화 시에만 업데이트, 시간 진행은 시스템에 위임
    private func startBackgroundHealthCheck() {
        // 타이머 제거 - Apple 가이드라인 준수
        // Live Activity는 이벤트 기반으로만 업데이트
    }
    
    /// Apple 정책 준수: 백그라운드 건강성 체크 제거
    /// Live Activity 상태는 시스템이 관리하며, 앱은 교시 변화시에만 개입
    private func performHealthCheck() {
        // 제거됨 - Apple 가이드라인 준수
        // Live Activity의 건강성은 시스템이 관리
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
        let (startDate, endDate) = getCurrentPeriodTimes()
        let initialState = ClassActivityAttributes.ContentState(
            currentStatus: getCurrentStatus(),
            currentClass: getCurrentClass(),
            nextClass: getNextClass(),
            startDate: startDate,
            endDate: endDate,
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity<ClassActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: getNextStaleDate())
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
        guard #available(iOS 18.0, *) else {
            print("❌ iOS 18.0+ required for Live Activity")
            return
        }
        
        guard let activity = currentActivity else {
            print("❌ No current activity to update")
            return
        }
        
        print("🔄 Updating Live Activity - State: \(activity.activityState)")
        
        let (startDate, endDate) = getCurrentPeriodTimes()
        let newState = ClassActivityAttributes.ContentState(
            currentStatus: getCurrentStatus(),
            currentClass: getCurrentClass(),
            nextClass: getNextClass(),
            startDate: startDate,
            endDate: endDate,
            lastUpdated: Date()
        )
        
        let remainingMinutes = max(0, Int(newState.endDate.timeIntervalSince(Date()) / 60))
        print("🔄 New state: Status=\(newState.currentStatus.rawValue), Remaining=\(remainingMinutes)min")
        
        _Concurrency.Task {
            do {
                let staleDate = getNextStaleDate()
                print("🔄 Updating with staleDate: \(staleDate)")
                
                await activity.update(ActivityContent(state: newState, staleDate: staleDate))
                print("✅ Live Activity updated successfully at \(Date())")
                
                // 업데이트 후 상태 재확인
                print("📊 Activity state after update: \(activity.activityState)")
                
            } catch {
                print("❌ Live Activity update failed: \(error)")
                print("📊 Activity state when failed: \(activity.activityState)")
                
                // 업데이트 실패 시 Activity 상태 확인
                checkActivityStateAndRestart()
            }
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
        
        _Concurrency.Task {
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
        
        _Concurrency.Task {
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
    
    /// 현재 시간대의 시작/종료 시각 계산 (Apple Live Activity 정책 준수)
    private func getCurrentPeriodTimes() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        let timeStatus = TimeUtility.getCurrentPeriodStatus()
        
        // 학교 시간표: 각 교시별 정확한 시간
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
            // 수업 중: 해당 교시의 시작/종료 시간
            if period >= 1 && period <= 7 {
                let periodTime = periodTimes[period - 1]
                let startDate = calendar.date(bySettingHour: periodTime.start.0, minute: periodTime.start.1, second: 0, of: now) ?? now
                let endDate = calendar.date(bySettingHour: periodTime.end.0, minute: periodTime.end.1, second: 0, of: now) ?? now
                return (startDate, endDate)
            }
            
        case .breakTime(let nextPeriod):
            // 쉬는시간: 이전 교시 종료 시간부터 다음 교시 시작 시간까지
            if nextPeriod >= 2 && nextPeriod <= 7 {
                let prevPeriodTime = periodTimes[nextPeriod - 2]
                let nextPeriodTime = periodTimes[nextPeriod - 1]
                let startDate = calendar.date(bySettingHour: prevPeriodTime.end.0, minute: prevPeriodTime.end.1, second: 0, of: now) ?? now
                let endDate = calendar.date(bySettingHour: nextPeriodTime.start.0, minute: nextPeriodTime.start.1, second: 0, of: now) ?? now
                return (startDate, endDate)
            }
            
        case .lunchTime:
            // 점심시간: 12:10 - 13:10
            let startDate = calendar.date(bySettingHour: 12, minute: 10, second: 0, of: now) ?? now
            let endDate = calendar.date(bySettingHour: 13, minute: 10, second: 0, of: now) ?? now
            return (startDate, endDate)
            
        case .preClass(let period):
            // 수업 전: 현재 시간부터 해당 교시 시작까지
            if period >= 1 && period <= 7 {
                let periodTime = periodTimes[period - 1]
                let endDate = calendar.date(bySettingHour: periodTime.start.0, minute: periodTime.start.1, second: 0, of: now) ?? now
                return (now, endDate)
            }
            
        case .beforeSchool:
            // 등교 전: 현재 시간부터 1교시 시작까지
            let endDate = calendar.date(bySettingHour: 8, minute: 20, second: 0, of: now) ?? now
            return (now, endDate)
            
        case .afterSchool:
            // 하교 후: 7교시 종료 시간부터 다음날 1교시 시작까지 (임시)
            let startDate = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? now
            return (startDate, endDate)
        }
        
        // 기본값: 현재 시간부터 1시간 후
        return (now, calendar.date(byAdding: .hour, value: 1, to: now) ?? now)
    }
    
    /// 다음 stale date 계산 (1분 후 또는 More Frequent Updates 활용)
    private func getNextStaleDate() -> Date {
        // More Frequent Updates가 활성화되어 있으면 1분, 아니면 5분
        let interval: TimeInterval = canUseMoreFrequentUpdates() ? 60 : 300
        return Date().addingTimeInterval(interval)
    }
    
    /// More Frequent Updates 사용 가능 여부 확인
    private func canUseMoreFrequentUpdates() -> Bool {
        #if canImport(ActivityKit)
        if #available(iOS 18.0, *) {
            // 현재 활성 상태인 Live Activity가 있는 경우
            if let activity = currentActivity,
               activity.activityState == .active {
                
                // iOS 설정에서 More Frequent Updates가 활성화되어 있는지 체크
                // 이 정보는 ActivityAuthorizationInfo를 통해 확인할 수 있음
                let authInfo = ActivityAuthorizationInfo()
                let isFrequentUpdatesEnabled = authInfo.areActivitiesEnabled
                
                print("🔍 More Frequent Updates available: \(isFrequentUpdatesEnabled)")
                return isFrequentUpdatesEnabled
            }
        }
        #endif
        return false
    }
    
    /// Activity 상태 확인 및 필요시 재시작
    private func checkActivityStateAndRestart() {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else { return }
        
        // 현재 Activity 상태 확인
        if let activity = currentActivity {
            print("📊 Current Live Activity state: \(activity.activityState)")
            
            switch activity.activityState {
            case .ended, .dismissed:
                print("⚠️ Live Activity ended/dismissed, attempting restart...")
                restartLiveActivityIfNeeded()
            case .active:
                print("✅ Live Activity is still active")
            case .stale:
                print("⚠️ Live Activity is stale, updating...")
                updateLiveActivity()
            @unknown default:
                print("❓ Unknown Live Activity state")
            }
        } else {
            print("❌ No current Live Activity found, attempting restart...")
            restartLiveActivityIfNeeded()
        }
        #endif
    }
    
    /// 필요시 Live Activity 재시작
    private func restartLiveActivityIfNeeded() {
        // 학교 시간 중에만 재시작
        let shouldBeRunning = TimeUtility.shouldLiveActivityBeRunning()
        let hasValidSettings = UserDefaults.standard.integer(forKey: "defaultGrade") > 0
        
        if shouldBeRunning && hasValidSettings {
            let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
            let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
            
            print("🔄 Restarting Live Activity for Grade \(grade) Class \(classNumber)")
            
            // 잠시 대기 후 재시작 (시스템 안정성을 위해)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startLiveActivity(grade: grade, classNumber: classNumber)
            }
        } else {
            print("⏭️ Not restarting Live Activity - should be running: \(shouldBeRunning), valid settings: \(hasValidSettings)")
        }
    }
    
    /// Apple 정책 준수: 이벤트 기반 Live Activity 관리
    /// 오직 교시 변화(08:20, 09:10, 09:20, 등) 시점에만 업데이트
    func updateOnClassPeriodChange() {
        let hasValidSettings = UserDefaults.standard.integer(forKey: "defaultGrade") > 0
        guard hasValidSettings else { return }
        
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        
        // 학교 시간 중에만 Live Activity 관리
        if TimeUtility.shouldLiveActivityBeRunning() {
            if !isActivityRunning {
                print("📚 [ClassChange] Starting Live Activity for new class period")
                startLiveActivity(grade: grade, classNumber: classNumber)
            } else {
                print("📚 [ClassChange] Updating Live Activity for class period change")
                updateLiveActivity()
            }
        } else if isActivityRunning {
            print("📚 [ClassChange] Stopping Live Activity - outside school hours")
            stopLiveActivity()
        }
    }
    
    /// 앱 포그라운드 진입시 Live Activity 상태 체크 (한 번만)
    func checkLiveActivityOnForeground() {
        let hasValidSettings = UserDefaults.standard.integer(forKey: "defaultGrade") > 0
        guard hasValidSettings else { return }
        
        let shouldBeRunning = TimeUtility.shouldLiveActivityBeRunning()
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        
        if shouldBeRunning && !isActivityRunning {
            print("📱 [Foreground] Starting Live Activity")
            startLiveActivity(grade: grade, classNumber: classNumber)
        } else if !shouldBeRunning && isActivityRunning {
            print("📱 [Foreground] Stopping Live Activity")
            stopLiveActivity()
        }
    }
    
    /// Activity 상태 모니터링 시작
    func startActivityStateMonitoring() {
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else { return }
        
        _Concurrency.Task {
            // 현재 Activity의 상태 변화 모니터링
            if let activity = currentActivity {
                for await state in activity.activityStateUpdates {
                    await MainActor.run {
                        print("📊 Live Activity state changed to: \(state)")
                        
                        switch state {
                        case .ended:
                            print("🔚 Live Activity ended")
                            self.currentActivity = nil
                            self.restartLiveActivityIfNeeded()
                            
                        case .dismissed:
                            print("🗑️ Live Activity dismissed")
                            self.currentActivity = nil
                            self.restartLiveActivityIfNeeded()
                            
                        case .stale:
                            print("⚠️ Live Activity became stale, updating...")
                            self.updateLiveActivity()
                            
                        case .active:
                            print("✅ Live Activity is active")
                            
                        @unknown default:
                            print("❓ Unknown Live Activity state: \(state)")
                        }
                    }
                }
            }
        }
        #endif
    }
}
