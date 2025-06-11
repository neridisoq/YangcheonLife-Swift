import UserNotifications
import ActivityKit
import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        print("🔔 [NotificationService] 알림 수신: \(request.content.userInfo)")
        
        // Firebase 메시지 처리
        handleFirebaseMessage(request: request)
        
        // 알림 내용 수정 (필요시)
        if let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.title = request.content.title
            bestAttemptContent.body = request.content.body
            contentHandler(bestAttemptContent)
        } else {
            contentHandler(request.content)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // 시간이 만료되기 전에 호출됨
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - Firebase 메시지 처리
    
    private func handleFirebaseMessage(request: UNNotificationRequest) {
        let userInfo = request.content.userInfo
        
        // 메시지 타입 확인
        var messageType: String?
        if let data = userInfo["data"] as? [String: Any] {
            messageType = data["type"] as? String
        } else {
            messageType = userInfo["type"] as? String
        }
        
        guard let type = messageType else {
            print("🔔 [NotificationService] 메시지 타입을 찾을 수 없음")
            return
        }
        
        print("🔔 [NotificationService] 메시지 타입: \(type)")
        
        switch type {
        case "start_live_activity":
            handleLiveActivityStart()
        case "stop_live_activity":
            handleLiveActivityStop()
        default:
            print("🔔 [NotificationService] 알 수 없는 메시지 타입: \(type)")
        }
    }
    
    // MARK: - Live Activity 제어
    
    private func handleLiveActivityStart() {
        print("🔔 [NotificationService] Live Activity 시작 요청")
        
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else {
            print("🔔 [NotificationService] iOS 18.0 이상 필요")
            return
        }
        
        // ActivityKit 권한 확인
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("🔔 [NotificationService] Live Activities 비활성화됨")
            return
        }
        
        // App Group UserDefaults에서 학년/반 정보 가져오기
        let groupDefaults = UserDefaults(suiteName: "group.com.helgisnw.yangcheonlife")
        let grade = groupDefaults?.integer(forKey: "defaultGrade") ?? 0
        let classNumber = groupDefaults?.integer(forKey: "defaultClass") ?? 0
        
        guard grade > 0 && classNumber > 0 else {
            print("🔔 [NotificationService] 유효하지 않은 학년/반: \(grade)학년 \(classNumber)반")
            return
        }
        
        print("🔔 [NotificationService] Live Activity 시작 시도: \(grade)학년 \(classNumber)반")
        
        // 기존 활동 확인 및 종료
        for activity in Activity<ClassActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        
        // Live Activity 시작
        do {
            let attributes = ClassActivityAttributes(grade: grade, classNumber: classNumber)
            let initialState = ClassActivityAttributes.ContentState(
                currentStatus: getCurrentStatus(),
                currentClass: getCurrentClass(grade: grade, classNumber: classNumber),
                nextClass: getNextClass(grade: grade, classNumber: classNumber),
                remainingMinutes: getRemainingMinutes(),
                lastUpdated: Date()
            )
            
            let activity = try Activity<ClassActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            
            print("🔔 [NotificationService] Live Activity 시작 성공: \(activity.id)")
        } catch {
            print("🔔 [NotificationService] Live Activity 시작 실패: \(error)")
        }
        #endif
    }
    
    private func handleLiveActivityStop() {
        print("🔔 [NotificationService] Live Activity 종료 요청")
        
        #if canImport(ActivityKit)
        guard #available(iOS 18.0, *) else { return }
        
        // 모든 활성 Live Activity 종료
        for activity in Activity<ClassActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
                print("🔔 [NotificationService] Live Activity 종료: \(activity.id)")
            }
        }
        #endif
    }
    
    // MARK: - Helper Methods
    
    @available(iOS 18.0, *)
    private func getCurrentStatus() -> ClassStatus {
        // 현재 시간에 따른 상태 반환 (단순화된 버전)
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        switch hour {
        case 0..<8:
            return .beforeSchool
        case 8..<12:
            return .inClass
        case 12..<13:
            return .lunchTime
        case 13..<17:
            return .inClass
        default:
            return .afterSchool
        }
    }
    
    @available(iOS 18.0, *)
    private func getCurrentClass(grade: Int, classNumber: Int) -> ClassInfo? {
        // App Group UserDefaults에서 시간표 데이터 가져오기
        let groupDefaults = UserDefaults(suiteName: "group.com.helgisnw.yangcheonlife")
        guard let data = groupDefaults?.data(forKey: "schedule_data_store"),
              let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data) else {
            return nil
        }
        
        // 현재 교시 계산 (단순화된 버전)
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        var currentPeriod: Int = 0
        switch hour {
        case 9:
            currentPeriod = 1
        case 10:
            currentPeriod = 2
        case 11:
            currentPeriod = 3
        case 12:
            currentPeriod = 4
        case 14:
            currentPeriod = 5
        case 15:
            currentPeriod = 6
        case 16:
            currentPeriod = 7
        default:
            return nil
        }
        
        let weekdayIndex = calendar.component(.weekday, from: now) - 2 // 월요일=0
        guard weekdayIndex >= 0 && weekdayIndex < 5 else { return nil } // 월-금만
        
        let dailySchedule = scheduleData.getDailySchedule(for: weekdayIndex)
        guard let scheduleItem = dailySchedule.first(where: { $0.period == currentPeriod }) else {
            return nil
        }
        
        return ClassInfo(
            period: currentPeriod,
            subject: scheduleItem.subject,
            classroom: scheduleItem.classroom,
            startTime: "\(hour):00",
            endTime: "\(hour):50"
        )
    }
    
    @available(iOS 18.0, *)
    private func getNextClass(grade: Int, classNumber: Int) -> ClassInfo? {
        // 다음 교시 정보 (단순화된 버전)
        return nil
    }
    
    private func getRemainingMinutes() -> Int {
        // 남은 시간 계산 (단순화된 버전)
        let calendar = Calendar.current
        let now = Date()
        let minute = calendar.component(.minute, from: now)
        return 50 - minute
    }
}