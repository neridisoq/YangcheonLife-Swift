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
        /// 남은 시간 (분)
        var remainingMinutes: Int
        /// 마지막 업데이트 시간
        var lastUpdated: Date
    }
    
    /// 학년, 반 정보 (변경되지 않는 속성)
    var grade: Int
    var classNumber: Int
    
    /// More Frequent Updates 지원 설정
    public var prefersFrequentUpdates: Bool {
        return true  // 학교 시간표는 실시간성이 중요하므로 빠른 업데이트 선호
    }
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
