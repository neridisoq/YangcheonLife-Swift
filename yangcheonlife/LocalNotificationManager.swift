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
        
        // 초기화 시 저장소에서 데이터 로드
        if let savedData = ScheduleService.shared.currentScheduleData {
            self.schedules = savedData.weeklySchedule
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
        Task {
            await ScheduleService.shared.loadSchedule(grade: grade, classNumber: classNumber)
            
            // 저장소에서 최신 데이터 로드하여 UI 갱신
            if let savedData = ScheduleService.shared.currentScheduleData {
                await MainActor.run {
                    self.schedules = savedData.weeklySchedule
                }
            }
        }
    }
    
    func loadLocalSchedule() -> [[ScheduleItem]]? {
        if let savedData = ScheduleService.shared.currentScheduleData {
            return savedData.weeklySchedule
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
