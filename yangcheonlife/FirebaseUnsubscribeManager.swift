import SwiftUI
import FirebaseCore
import FirebaseMessaging

// Firebase 초기화 및 토픽 구독 해제를 관리하는 클래스
class FirebaseUnsubscribeManager {
    static let shared = FirebaseUnsubscribeManager()
    
    private let hasUnsubscribedKey = "hasUnsubscribedFromAllFirebaseTopics"
    
    private init() {}
    
    // Firebase 초기화
    func configureFirebase() {
        // 이미 모든 토픽 구독 해제를 완료했다면 Firebase 초기화를 건너뜀
        if UserDefaults.standard.bool(forKey: hasUnsubscribedKey) {
            print("✅ 이미 모든 Firebase 토픽 구독 해제를 완료했습니다.")
            return
        }
        
        // Firebase 초기화
        FirebaseApp.configure()
        print("🔥 Firebase 초기화 완료")
    }
    
    // 모든 학년/반 토픽 구독 해제
    func unsubscribeFromAllTopics(completion: @escaping () -> Void) {
        // 이미 구독 해제를 완료했다면 다시 실행하지 않음
        if UserDefaults.standard.bool(forKey: hasUnsubscribedKey) {
            print("✅ 이미 모든 Firebase 토픽 구독 해제를 완료했습니다.")
            completion()
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
            completion()
        }
    }
}

// 앱 실행 시 자동으로 토픽 구독 해제를 수행하는 뷰 수정자
struct FirebaseUnsubscribeModifier: ViewModifier {
    @State private var isUnsubscribing = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // 이미 구독 해제되었는지 확인
                if !UserDefaults.standard.bool(forKey: "hasUnsubscribedFromAllFirebaseTopics") {
                    isUnsubscribing = true
                    
                    // Firebase 초기화
                    FirebaseUnsubscribeManager.shared.configureFirebase()
                    
                    // 토픽 구독 해제 (백그라운드에서 처리)
                    DispatchQueue.global(qos: .utility).async {
                        FirebaseUnsubscribeManager.shared.unsubscribeFromAllTopics {
                            DispatchQueue.main.async {
                                isUnsubscribing = false
                            }
                        }
                    }
                }
            }
    }
}

// View 확장으로 사용하기 쉽게 만듦
extension View {
    func withFirebaseUnsubscribe() -> some View {
        modifier(FirebaseUnsubscribeModifier())
    }
}