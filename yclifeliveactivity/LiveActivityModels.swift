import Foundation
import ActivityKit

// MARK: - Live Activity Data Models

/// Live Activity 상태 정보
struct ClassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 현재 교시 상태
        var currentStatus: ClassStatus
        /// 현재 수업 정보 (수업 중일 때)
        var currentClass: ClassInfo?
        /// 다음 수업 정보
        var nextClass: ClassInfo?
        /// 현재 시간대 시작 시각 (TimeInterval since 1970)
        var startDate: TimeInterval
        /// 현재 시간대 종료 시각 (TimeInterval since 1970)
        var endDate: TimeInterval
        /// 마지막 업데이트 시간 (TimeInterval since 1970)
        var lastUpdated: TimeInterval
    }
    
    /// 학교 식별자 (빈 값이지만 ActivityKit에서 필요)
    var schoolId: String = "yangcheon"
    
    /// More Frequent Updates 지원 설정
    public var prefersFrequentUpdates: Bool {
        return true  // 학교 시간표는 실시간성이 중요하므로 빠른 업데이트 선호
    }
}

/// 수업 상태 열거형
enum ClassStatus: String, Codable, CaseIterable {
    case beforeSchool = "beforeSchool"
    case inClass = "inClass"
    case breakTime = "breakTime"
    case lunchTime = "lunchTime"
    case preClass = "preClass"
    case afterSchool = "afterSchool"
    
    var displayText: String {
        switch self {
        case .beforeSchool:
            return "등교전"
        case .inClass:
            return "수업중"
        case .breakTime:
            return "쉬는시간"
        case .lunchTime:
            return "점심시간"
        case .preClass:
            return "수업전"
        case .afterSchool:
            return "하교후"
        }
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
    
    /// 과목 표시명 (탐구 과목 치환 적용)
    func getDisplaySubject() -> String {
        var displaySubject = subject
        
        // 과목명에 "반"이 포함된 경우 (탐구 과목 등)
        if subject.contains("반") {
            let customKey = "selected\(subject)Subject"
            
            // UserDefaults에서 사용자가 선택한 과목 가져오기
            if let selectedSubject = SharedUserDefaults.shared.userDefaults.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != subject {
                
                // "과목명/교실명" 형태에서 과목명만 추출
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displaySubject = components[0]
                }
            }
        }
        
        return displaySubject
    }
    
    /// 교실 표시명 (탐구 과목 치환 적용)
    func getDisplayClassroom() -> String {
        var displayClassroom = classroom
        
        // 과목명에 "반"이 포함된 경우 (탐구 과목 등)
        if subject.contains("반") {
            let customKey = "selected\(subject)Subject"
            
            // UserDefaults에서 사용자가 선택한 과목 가져오기
            if let selectedSubject = SharedUserDefaults.shared.userDefaults.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != subject {
                
                // "과목명/교실명" 형태에서 교실명만 추출
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displayClassroom = components[1]
                }
            }
        }
        
        return displayClassroom
    }
}
