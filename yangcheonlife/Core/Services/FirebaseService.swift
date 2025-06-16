import Foundation
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - Firebase 서비스 관리자
class FirebaseService: NSObject, ObservableObject {
    static let shared = FirebaseService()
    
    // MARK: - Private Properties
    private let hasUnsubscribedKey = "hasUnsubscribedFromAllFirebaseTopics"
    
    // MARK: - Published Properties
    @Published var isInitialized = false
    @Published var currentTopic: String?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        // 초기화 시점에는 Firebase가 아직 설정되지 않았을 수 있으므로 델리게이트 설정을 지연
        print("🔥 FirebaseService 초기화 - Firebase.configure() 대기 중")
    }
    
    // MARK: - Firebase 초기화
    func initialize() {
        guard FirebaseApp.app() == nil else {
            print("🔥 Firebase는 이미 초기화되어 있습니다.")
            isInitialized = true
            setupMessagingDelegate() // 이미 초기화된 경우에도 델리게이트 설정
            return
        }
        
        FirebaseApp.configure()
        setupMessagingDelegate()
        print("🔥 Firebase 초기화 완료")
        isInitialized = true
    }
    
    // MARK: - Messaging 델리게이트 설정
    private func setupMessagingDelegate() {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase가 아직 초기화되지 않음 - 델리게이트 설정 지연")
            return
        }
        Messaging.messaging().delegate = self
    }
    
    // MARK: - 토픽 구독 관리
    
    /// Live Activity용 통합 토픽 구독
    func subscribeToLiveActivityTopic(completion: @escaping (Bool) -> Void = { _ in }) {
        guard isInitialized else {
            print("❌ Firebase가 초기화되지 않음 - Live Activity 토픽 구독 지연")
            initialize()
            // 재귀적으로 다시 호출
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.subscribeToLiveActivityTopic(completion: completion)
            }
            return
        }
        
        // Live Activity와 Wake 토픽 모두 구독
        let topics = ["ios_liveactivity", "wake"]
        let subscribedTopicsKey = "subscribedFirebaseTopics"
        var subscribedTopics = UserDefaults.standard.stringArray(forKey: subscribedTopicsKey) ?? []
        
        var pendingSubscriptions = topics.count
        var allSuccessful = true
        
        for topic in topics {
            // 이미 구독된 토픽 체크
            if subscribedTopics.contains(topic) {
                print("⚠️ 토픽 '\(topic)'는 이미 구독됨 - 건너뛰기")
                pendingSubscriptions -= 1
                if pendingSubscriptions == 0 {
                    completion(allSuccessful)
                }
                continue
            }
            
            Messaging.messaging().subscribe(toTopic: topic) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 토픽 '\(topic)' 구독 실패: \(error.localizedDescription)")
                        allSuccessful = false
                    } else {
                        print("✅ 토픽 '\(topic)' 구독 성공")
                        // 구독 성공 시 목록에 추가
                        subscribedTopics.append(topic)
                        UserDefaults.standard.set(subscribedTopics, forKey: subscribedTopicsKey)
                    }
                    
                    pendingSubscriptions -= 1
                    if pendingSubscriptions == 0 {
                        completion(allSuccessful)
                    }
                }
            }
        }
    }
    
    /// 특정 학년/반 토픽 구독 (기존 기능 유지)
    func subscribeToTopic(grade: Int, classNumber: Int, completion: @escaping (Bool) -> Void = { _ in }) {
        guard isInitialized else {
            print("❌ Firebase가 초기화되지 않음 - 토픽 구독 지연")
            initialize()
            // 재귀적으로 다시 호출
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.subscribeToTopic(grade: grade, classNumber: classNumber, completion: completion)
            }
            return
        }
        
        let topic = "\(grade)-\(classNumber)"
        
        Messaging.messaging().subscribe(toTopic: topic) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 토픽 '\(topic)' 구독 실패: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ 토픽 '\(topic)' 구독 성공")
                    // Live Activity 토픽도 함께 구독
                    self?.subscribeToLiveActivityTopic()
                    completion(true)
                }
            }
        }
    }
    
    /// 현재 토픽에서 구독 해제하고 새 토픽 구독
    func switchTopic(to grade: Int, classNumber: Int, completion: @escaping (Bool) -> Void = { _ in }) {
        // 기존 토픽 구독 해제 (Live Activity 토픽은 유지)
        if let currentTopic = currentTopic, currentTopic != "ios_liveactivity" {
            unsubscribeFromTopic(currentTopic) { [weak self] _ in
                // 새 토픽 구독
                self?.subscribeToTopic(grade: grade, classNumber: classNumber, completion: completion)
            }
        } else {
            // 기존 토픽이 없으면 바로 새 토픽 구독
            subscribeToTopic(grade: grade, classNumber: classNumber, completion: completion)
        }
    }
    
    /// 특정 토픽 구독 해제
    private func unsubscribeFromTopic(_ topic: String, completion: @escaping (Bool) -> Void = { _ in }) {
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("⚠️ 토픽 '\(topic)' 구독 해제 실패: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ 토픽 '\(topic)' 구독 해제 성공")
                    completion(true)
                }
            }
        }
    }
    
    /// 모든 토픽 구독 해제 (앱 삭제 시 등)
    func unsubscribeFromAllTopics(completion: @escaping () -> Void = {}) {
        // 이미 구독 해제가 완료되었는지 확인
        if UserDefaults.standard.bool(forKey: hasUnsubscribedKey) {
            print("✅ 이미 모든 Firebase 토픽 구독 해제를 완료했습니다.")
            completion()
            return
        }
        
        guard isInitialized else {
            initialize()
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        // Live Activity 토픽 구독 해제
        dispatchGroup.enter()
        Messaging.messaging().unsubscribe(fromTopic: "ios_liveactivity") { error in
            if let error = error {
                print("⚠️ 토픽 'ios_liveactivity' 구독 해제 실패: \(error.localizedDescription)")
            } else {
                print("✅ 토픽 'ios_liveactivity' 구독 해제 성공")
            }
            dispatchGroup.leave()
        }
        
        // 모든 학년(1~3)과 반(1~11)의 조합에 대해 토픽 구독 해제
        for grade in 1...3 {
            for classNumber in 1...11 {
                let topic = "\(grade)-\(classNumber)"
                dispatchGroup.enter()
                
                Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                    if let error = error {
                        print("⚠️ 토픽 '\(topic)' 구독 해제 실패: \(error.localizedDescription)")
                    } else {
                        print("✅ 토픽 '\(topic)' 구독 해제 성공")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        // 모든 구독 해제가 완료되면 UserDefaults에 기록
        dispatchGroup.notify(queue: .main) {
            print("✅ 모든 Firebase 토픽 구독 해제 완료")
            UserDefaults.standard.set(true, forKey: self.hasUnsubscribedKey)
            self.currentTopic = nil
            completion()
        }
    }
    
    // MARK: - FCM 토큰 관리
    func getFCMToken(completion: @escaping (String?) -> Void) {
        guard isInitialized else {
            print("❌ Firebase가 초기화되지 않음 - 토큰 요청 지연")
            initialize()
            completion(nil)
            return
        }
        
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM 토큰 가져오기 실패: \(error.localizedDescription)")
                completion(nil)
            } else if let token = token {
                print("✅ FCM 토큰: \(token)")
                completion(token)
            }
        }
    }
    
    // MARK: - Live Activity 원격 제어
    
    /// Live Activity 원격 시작 요청 처리
    func handleRemoteLiveActivityStart(userInfo: [AnyHashable: Any]) {
        print("📱 Live Activity 원격 시작 요청 수신: \(userInfo)")
        
        // 메시지 타입 확인 (data 필드에서)
        var messageType: String?
        if let data = userInfo["data"] as? [String: Any] {
            messageType = data["type"] as? String
        } else {
            messageType = userInfo["type"] as? String
        }
        
        guard let type = messageType, type == "start_live_activity" else {
            print("⚠️ Live Activity 시작 메시지가 아님. 메시지 타입: \(messageType ?? "nil")")
            return
        }
        
        // 기기에 저장된 학년/반 정보 사용
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        
        guard grade > 0 && classNumber > 0 else {
            print("❌ 유효하지 않은 학년/반 정보: grade=\(grade), class=\(classNumber)")
            return
        }
        
        // 앱 상태 확인
        let appState = UIApplication.shared.applicationState
        if appState != .active {
            print("📱 앱이 백그라운드 상태입니다. NotificationServiceExtension에서 처리됩니다.")
            // NotificationServiceExtension에서 이미 처리하므로 여기서는 아무것도 하지 않음
            return
        }
        
        // Live Activity 시작
        if #available(iOS 18.0, *) {
            DispatchQueue.main.async {
                LiveActivityManager.shared.startLiveActivity(grade: grade, classNumber: classNumber)
                print("✅ Live Activity 원격 시작 완료: \(grade)학년 \(classNumber)반")
            }
        } else {
            print("❌ iOS 18.0 이상이 필요합니다.")
        }
    }
    
    /// Live Activity 원격 종료 요청 처리
    func handleRemoteLiveActivityStop(userInfo: [AnyHashable: Any]) {
        print("📱 Live Activity 원격 종료 요청 수신: \(userInfo)")
        
        // 메시지 타입 확인 (data 필드에서)
        var messageType: String?
        if let data = userInfo["data"] as? [String: Any] {
            messageType = data["type"] as? String
        } else {
            messageType = userInfo["type"] as? String
        }
        
        guard let type = messageType, type == "stop_live_activity" else {
            print("⚠️ Live Activity 종료 메시지가 아님. 메시지 타입: \(messageType ?? "nil")")
            return
        }
        
        // Live Activity 종료
        if #available(iOS 18.0, *) {
            DispatchQueue.main.async {
                LiveActivityManager.shared.stopLiveActivity()
                print("✅ Live Activity 원격 종료 완료")
            }
        } else {
            print("❌ iOS 18.0 이상이 필요합니다.")
        }
    }
}

// MARK: - MessagingDelegate
extension FirebaseService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔄 FCM 토큰 갱신: \(fcmToken ?? "nil")")
        
        // 토큰을 더 명확하게 표시
        if let token = fcmToken {
            print("📱 FCM 토큰 (복사용):")
            print("   \(token)")
            print("📱 Firebase Console에서 이 토큰으로 테스트 메시지를 보낼 수 있습니다.")
        }
        
        // 토큰이 갱신될 때 Live Activity 토픽 구독
        subscribeToLiveActivityTopic()
    }
    
    // Note: MessagingRemoteMessage 타입이 현재 Firebase SDK 버전에서 사용할 수 없음
    // 대신 AppDelegate의 willPresent와 didReceiveRemoteNotification 메서드에서 처리
}