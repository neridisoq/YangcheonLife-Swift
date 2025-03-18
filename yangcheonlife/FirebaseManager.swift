import Foundation
import FirebaseCore
import FirebaseMessaging

// Firebase 토픽 구독 해제를 관리하는 싱글톤 클래스
class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let hasUnsubscribedKey = "hasUnsubscribedFromAllFirebaseTopics"
    private var isFirebaseConfigured = false
    
    private init() {}
    
    // Firebase 초기화 - 앱에서 한 번만 호출되도록 보장
    func ensureFirebaseConfigured() {
        // 이미 구독 해제가 완료되었거나 Firebase가 이미 초기화되었다면 건너뜀
        if UserDefaults.standard.bool(forKey: hasUnsubscribedKey) || isFirebaseConfigured {
            print("⏭️ Firebase 초기화 건너뜀 (이미 초기화됨 또는 구독 해제 완료)")
            return
        }
        
        // Firebase가 이미 초기화되었는지 확인
        if FirebaseApp.app() == nil {
            // Firebase 초기화
            FirebaseApp.configure()
            isFirebaseConfigured = true
            print("🔥 Firebase 초기화 완료")
        } else {
            isFirebaseConfigured = true
            print("🔥 Firebase는 이미 초기화되어 있습니다.")
        }
    }
    
    // 모든 학년/반 토픽 구독 해제
    func unsubscribeFromAllTopics(completion: @escaping () -> Void) {
        // 이미 구독 해제가 완료되었는지 확인
        if UserDefaults.standard.bool(forKey: hasUnsubscribedKey) {
            print("✅ 이미 모든 Firebase 토픽 구독 해제를 완료했습니다.")
            completion()
            return
        }
        
        // Firebase가 초기화되었는지 확인
        ensureFirebaseConfigured()
        
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
            completion()
        }
    }
}