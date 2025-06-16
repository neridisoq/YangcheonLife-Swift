import UserNotifications
import Foundation

/// Notification Service Extension (Firebase FCM 전용)
class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        print("🔔 [NotificationService] Firebase FCM Extension called!")
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        print("🔔 [NotificationService] Firebase FCM notification received: \(request.content.userInfo)")
        
        // Firebase FCM 알림 처리 (필요한 경우)
        handleFirebaseFCMNotification(request: request)
        
        // 알림 내용 전달
        if let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.title = request.content.title
            bestAttemptContent.body = request.content.body
            contentHandler(bestAttemptContent)
        } else {
            contentHandler(request.content)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - Firebase FCM 처리
    
    private func handleFirebaseFCMNotification(request: UNNotificationRequest) {
        let userInfo = request.content.userInfo
        
        // Firebase FCM에서 보낸 데이터 확인
        if let data = userInfo["data"] as? [String: Any] {
            print("🔔 [NotificationService] Firebase FCM data: \(data)")
            
            // 필요한 경우 여기서 FCM 데이터 처리
            if let type = data["type"] as? String {
                print("🔔 [NotificationService] FCM message type: \(type)")
                
                switch type {
                case "wake_live_activity":
                    print("🔔 [NotificationService] FCM wake signal received")
                    // FCM wake 신호는 앱에서 처리됨
                    break
                default:
                    print("🔔 [NotificationService] Unknown FCM message type: \(type)")
                }
            }
        }
    }
}