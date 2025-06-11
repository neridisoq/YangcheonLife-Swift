import Foundation
import ActivityKit

// MARK: - Live Activity Models (Shared)
// Note: 실제 구현에서는 main app의 모델 파일을 target에 추가하는 것이 좋습니다.

/// Live Activity 상태 정보
struct ClassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 현재 교시 상태
        var currentStatus: ClassStatus
        /// 현재 수업 정보 (수업 중일 때)
        var currentClass: ClassInfo?
        /// 다음 수업 정보
        var nextClass: ClassInfo?
        /// 남은 시간 (분)
        var remainingMinutes: Int
        /// 마지막 업데이트 시간
        var lastUpdated: Date
    }
    
    /// 학년, 반 정보 (변경되지 않는 속성)
    var grade: Int
    var classNumber: Int
}

/// 수업 상태 열거형
enum ClassStatus: String, Codable, CaseIterable {
    case beforeSchool = "등교전"
    case inClass = "수업중"
    case breakTime = "쉬는시간"
    case lunchTime = "점심시간"
    case preClass = "수업전"
    case afterSchool = "하교후"
    
    var displayText: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .beforeSchool:
            return "🌅"
        case .inClass:
            return "📚"
        case .breakTime:
            return "☕️"
        case .lunchTime:
            return "🍽️"
        case .preClass:
            return "⏰"
        case .afterSchool:
            return "🏠"
        }
    }
}

/// 수업 정보 모델 (Live Activity용)
struct ClassInfo: Codable, Hashable {
    var period: Int
    var subject: String
    var classroom: String
    var startTime: String
    var endTime: String
    
    /// 과목 표시명 (단순화된 버전)
    func getDisplaySubject() -> String {
        return subject
    }
    
    /// 교실 표시명 (단순화된 버전)
    func getDisplayClassroom() -> String {
        return classroom
    }
}

// MARK: - Schedule Models (Simplified for Extension)

/// 시간표 데이터 모델 (단순화된 버전)
struct ScheduleData: Codable {
    var schedules: [[ScheduleItem]]
    
    func getDailySchedule(for weekdayIndex: Int) -> [ScheduleItem] {
        guard weekdayIndex >= 0 && weekdayIndex < schedules.count else {
            return []
        }
        return schedules[weekdayIndex]
    }
}

/// 개별 수업 모델 (단순화된 버전)
struct ScheduleItem: Codable {
    var period: Int
    var subject: String
    var classroom: String
}