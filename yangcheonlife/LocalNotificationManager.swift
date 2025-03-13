import Foundation
import UserNotifications
import Combine

class LocalNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationManager()
    
    @Published var schedules: [[ScheduleItem]] = []
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        // 초기화 시 저장소2에서 데이터 로드
        if let savedData = ScheduleManager.shared.loadDataStore() {
            self.schedules = savedData.schedules
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func fetchAndSaveSchedule(grade: Int, classNumber: Int) {
        // ScheduleManager의 개선된 로직 사용
        ScheduleManager.shared.fetchAndUpdateSchedule(grade: grade, classNumber: classNumber) { [weak self] success in
            if success {
                print("시간표 및 알림 업데이트 완료")
                
                // 저장소에서 최신 데이터 로드하여 UI 갱신
                if let savedData = ScheduleManager.shared.loadDataStore() {
                    DispatchQueue.main.async {
                        self?.schedules = savedData.schedules
                    }
                }
            } else {
                print("시간표 업데이트 없음 또는 실패")
            }
        }
    }
    
    func loadLocalSchedule() -> [[ScheduleItem]]? {
        if let savedData = ScheduleManager.shared.loadDataStore() {
            return savedData.schedules
        }
        return nil
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 포그라운드에 있을 때도 알림 표시
        completionHandler([.badge, .sound, .banner, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 알림 선택 시 처리 (필요하면 추가 구현)
        completionHandler()
    }
}
