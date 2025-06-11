import Foundation

/// Extension에서 사용할 간단한 시간 유틸리티
/// UIApplication을 사용할 수 없으므로 간소화된 버전
struct ExtensionTimeUtility {
    
    /// 현재 교시 번호 반환 (간소화된 버전)
    static func getCurrentPeriodNumber() -> Int? {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        switch hour {
        case 9:
            return 1
        case 10:
            return 2
        case 11:
            return 3
        case 12:
            return 4
        case 14:
            return 5
        case 15:
            return 6
        case 16:
            return 7
        default:
            return nil
        }
    }
    
    /// 현재 요일 인덱스 (월=0, 화=1, ..., 금=4)
    static func getCurrentWeekdayIndex() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        return weekday - 2 // 일요일=1이므로 월요일=0으로 조정
    }
    
    /// 현재 상태 반환
    static func getCurrentStatus() -> ClassStatus {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        switch hour {
        case 0..<8:
            return .beforeSchool
        case 8..<9:
            return .preClass
        case 9, 10, 11:
            return .inClass
        case 12:
            if minute < 10 {
                return .lunchTime
            } else {
                return .inClass
            }
        case 13:
            if minute < 10 {
                return .breakTime
            } else {
                return .inClass
            }
        case 14, 15, 16:
            return .inClass
        case 17...:
            return .afterSchool
        default:
            return .afterSchool
        }
    }
    
    /// 남은 시간 계산 (분)
    static func getRemainingMinutes() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let minute = calendar.component(.minute, from: now)
        
        // 간단한 계산: 50분 수업 기준
        return max(0, 50 - minute)
    }
    
    /// 교시별 시간 문자열 반환
    static func getPeriodTimeString(period: Int) -> String {
        switch period {
        case 1:
            return "09:00 - 09:50"
        case 2:
            return "10:00 - 10:50"
        case 3:
            return "11:00 - 11:50"
        case 4:
            return "12:00 - 12:50"
        case 5:
            return "14:00 - 14:50"
        case 6:
            return "15:00 - 15:50"
        case 7:
            return "16:00 - 16:50"
        default:
            return "00:00 - 00:00"
        }
    }
}