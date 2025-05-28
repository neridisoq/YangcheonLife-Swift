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
        setupMessagingDelegate()
    }
    
    // MARK: - Firebase 초기화
    func initialize() {
        guard FirebaseApp.app() == nil else {
            print("🔥 Firebase는 이미 초기화되어 있습니다.")
            isInitialized = true
            return
        }
        
        FirebaseApp.configure()
        setupMessagingDelegate()
        print("🔥 Firebase 초기화 완료")
        isInitialized = true
    }
    
    // MARK: - Messaging 델리게이트 설정
    private func setupMessagingDelegate() {
        Messaging.messaging().delegate = self
    }
    
    // MARK: - 토픽 구독 관리
    
    /// 특정 학년/반 토픽 구독
    func subscribeToTopic(grade: Int, classNumber: Int, completion: @escaping (Bool) -> Void = { _ in }) {
        guard isInitialized else {
            initialize()
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
                    self?.currentTopic = topic
                    completion(true)
                }
            }
        }
    }
    
    /// 현재 토픽에서 구독 해제하고 새 토픽 구독
    func switchTopic(to grade: Int, classNumber: Int, completion: @escaping (Bool) -> Void = { _ in }) {
        // 기존 토픽 구독 해제
        if let currentTopic = currentTopic {
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
}

// MARK: - MessagingDelegate
extension FirebaseService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔄 FCM 토큰 갱신: \(fcmToken ?? "nil")")
        
        // 토큰이 갱신될 때 현재 설정된 학년/반으로 다시 구독
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        
        if grade > 0 && classNumber > 0 {
            subscribeToTopic(grade: grade, classNumber: classNumber)
        }
    }
}