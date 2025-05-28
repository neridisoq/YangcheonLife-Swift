import Foundation

/// Minimal utility functions for Live Activity
struct LiveActivityUtilities {
    
    /// Date를 "HH:mm" 형태로 변환
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}