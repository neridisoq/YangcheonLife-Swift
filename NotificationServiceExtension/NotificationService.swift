import UserNotifications
import ActivityKit
import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

// Note: 다음 파일들이 NotificationServiceExtension 타겟에 추가되어야 합니다:
// - yclifeliveactivity/LiveActivityModels.swift
// - yangcheonlife/Core/Models/ScheduleModels.swift  
// - Shared/SharedUserDefaults.swift
// - yangcheonlife/Core/Constants/AppConstants.swift
//
// 주의: LiveActivityManager.swift는 추가하지 마세요 (UIApplication, Combine 의존성 때문)

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        print("🔔 [NotificationService] Extension 호출됨!!!")
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
        
        // App Group UserDefaults에서 학년/반 정보 가져오기
        let groupDefaults = UserDefaults(suiteName: "group.com.helgisnw.yangcheonlife")
        
        // 기존 데이터 확인
        print("🔔 [NotificationService] 기존 App Group 데이터 확인:")
        print("   - defaultGrade: \(groupDefaults?.integer(forKey: "defaultGrade") ?? -1)")
        print("   - defaultClass: \(groupDefaults?.integer(forKey: "defaultClass") ?? -1)")
        print("   - 이전 pendingLiveActivityStart: \(groupDefaults?.bool(forKey: "pendingLiveActivityStart") ?? false)")
        
        let grade = groupDefaults?.integer(forKey: "defaultGrade") ?? 0
        let classNumber = groupDefaults?.integer(forKey: "defaultClass") ?? 0
        
        guard grade > 0 && classNumber > 0 else {
            print("🔔 [NotificationService] ❌ 유효하지 않은 학년/반: \(grade)학년 \(classNumber)반")
            print("🔔 [NotificationService] 기본값으로 3학년 1반 설정")
            
            // 기본값 설정
            let defaultGrade = 3
            let defaultClass = 1
            
            // 대기 요청 저장 (기본값 사용)
            groupDefaults?.set(true, forKey: "pendingLiveActivityStart")
            groupDefaults?.set(defaultGrade, forKey: "pendingLiveActivityGrade")
            groupDefaults?.set(defaultClass, forKey: "pendingLiveActivityClass")
            groupDefaults?.set(Date().timeIntervalSince1970, forKey: "pendingLiveActivityTimestamp")
            groupDefaults?.synchronize() // 강제 동기화
            
            print("🔔 [NotificationService] ✅ 기본값으로 대기 요청 저장 완료: \(defaultGrade)학년 \(defaultClass)반")
            return
        }
        
        print("🔔 [NotificationService] Extension에서는 직접 Live Activity 시작 불가")
        print("🔔 [NotificationService] 메인 앱에 시작 요청 신호 저장: \(grade)학년 \(classNumber)반")
        
        // Extension에서는 Live Activity를 직접 시작할 수 없으므로 
        // App Group UserDefaults를 통해 메인 앱에 신호를 보냄
        groupDefaults?.set(true, forKey: "pendingLiveActivityStart")
        groupDefaults?.set(grade, forKey: "pendingLiveActivityGrade")
        groupDefaults?.set(classNumber, forKey: "pendingLiveActivityClass")
        groupDefaults?.set(Date().timeIntervalSince1970, forKey: "pendingLiveActivityTimestamp")
        
        // 강제 동기화로 확실히 저장
        groupDefaults?.synchronize()
        
        // 저장 확인
        let savedFlag = groupDefaults?.bool(forKey: "pendingLiveActivityStart") ?? false
        let savedGrade = groupDefaults?.integer(forKey: "pendingLiveActivityGrade") ?? 0
        let savedClass = groupDefaults?.integer(forKey: "pendingLiveActivityClass") ?? 0
        
        print("🔔 [NotificationService] 저장 확인:")
        print("   - pendingLiveActivityStart: \(savedFlag)")
        print("   - pendingLiveActivityGrade: \(savedGrade)")
        print("   - pendingLiveActivityClass: \(savedClass)")
        
        if savedFlag && savedGrade > 0 && savedClass > 0 {
            print("🔔 [NotificationService] ✅ 대기 요청 저장 성공! 메인 앱 활성화 시 Live Activity가 시작됩니다")
        } else {
            print("🔔 [NotificationService] ❌ 대기 요청 저장 실패!")
        }
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
        return ExtensionTimeUtility.getCurrentStatus()
    }
    
    @available(iOS 18.0, *)
    private func getCurrentClass(grade: Int, classNumber: Int) -> ClassInfo? {
        // App Group UserDefaults에서 시간표 데이터 가져오기
        let groupDefaults = UserDefaults(suiteName: "group.com.helgisnw.yangcheonlife")
        guard let data = groupDefaults?.data(forKey: "schedule_data_store"),
              let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data) else {
            return nil
        }
        
        guard let currentPeriod = ExtensionTimeUtility.getCurrentPeriodNumber() else {
            return nil
        }
        
        let weekdayIndex = ExtensionTimeUtility.getCurrentWeekdayIndex()
        guard weekdayIndex >= 0 && weekdayIndex < 5 else { return nil } // 월-금만
        
        let dailySchedule = scheduleData.getDailySchedule(for: weekdayIndex)
        guard let scheduleItem = dailySchedule.first(where: { $0.period == currentPeriod }) else {
            return nil
        }
        
        let timeString = ExtensionTimeUtility.getPeriodTimeString(period: currentPeriod)
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
    private func getNextClass(grade: Int, classNumber: Int) -> ClassInfo? {
        // 다음 교시 정보 (단순화된 버전)
        return nil
    }
    
    private func getRemainingMinutes() -> Int {
        return ExtensionTimeUtility.getRemainingMinutes()
    }
}
