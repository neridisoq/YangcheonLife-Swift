import Foundation

// MARK: - 교시별 시간 정보 모델
struct PeriodTime {
    let startTime: (hour: Int, minute: Int)  // 시작 시간
    let endTime: (hour: Int, minute: Int)    // 종료 시간
    
    /// 전체 교시 시간표
    static let allPeriods: [PeriodTime] = [
        PeriodTime(startTime: (8, 20), endTime: (9, 10)),   // 1교시
        PeriodTime(startTime: (9, 20), endTime: (10, 10)),  // 2교시
        PeriodTime(startTime: (10, 20), endTime: (11, 10)), // 3교시
        PeriodTime(startTime: (11, 20), endTime: (12, 10)), // 4교시
        PeriodTime(startTime: (13, 10), endTime: (14, 0)),  // 5교시
        PeriodTime(startTime: (14, 10), endTime: (15, 0)),  // 6교시
        PeriodTime(startTime: (15, 10), endTime: (16, 0))   // 7교시
    ]
    
    /// 현재 시간이 수업 시간인지 확인
    func isCurrentPeriod(at currentTime: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentTotalMinutes = hour * 60 + minute
        
        let startTotalMinutes = startTime.hour * 60 + startTime.minute
        let endTotalMinutes = endTime.hour * 60 + endTime.minute
        
        return currentTotalMinutes >= startTotalMinutes && currentTotalMinutes <= endTotalMinutes
    }
    
    /// 현재 시간이 수업 10분 전인지 확인
    func isPreClassTime(at currentTime: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentTotalMinutes = hour * 60 + minute
        
        let startTotalMinutes = startTime.hour * 60 + startTime.minute
        let preClassTotalMinutes = startTotalMinutes - 10
        
        return currentTotalMinutes >= preClassTotalMinutes && currentTotalMinutes < startTotalMinutes
    }
}

// MARK: - 현재 교시 상태 열거형
enum CurrentPeriodStatus {
    case beforeSchool       // 등교 전
    case inClass(Int)      // 수업 중 (교시)
    case breakTime(Int)    // 쉬는 시간 (다음 교시)
    case lunchTime         // 점심 시간
    case preClass(Int)     // 수업 10분 전 (교시)
    case afterSchool       // 하교 후
    
    /// 현재 시간을 기준으로 교시 상태 계산
    static func getCurrentStatus(at date: Date = Date()) -> CurrentPeriodStatus {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTotalMinutes = hour * 60 + minute
        
        // 등교 전 (7시 이전)
        if hour < 7 {
            return .beforeSchool
        }
        
        // 1교시 전 시간 처리
        let firstPeriodStart = PeriodTime.allPeriods[0].startTime.hour * 60 + PeriodTime.allPeriods[0].startTime.minute
        if currentTotalMinutes < firstPeriodStart - 10 {
            return .beforeSchool
        } else if currentTotalMinutes < firstPeriodStart {
            return .preClass(1)
        }
        
        // 각 교시별 확인
        for (index, period) in PeriodTime.allPeriods.enumerated() {
            let periodNumber = index + 1
            
            // 수업 중인지 확인
            if period.isCurrentPeriod(at: date) {
                return .inClass(periodNumber)
            }
            
            // 4교시 종료 후 점심시간 처리 (12:10 ~ 13:00)
            if index == 3 { // 4교시 (index 3)
                let currentEndMinutes = period.endTime.hour * 60 + period.endTime.minute // 12:10 = 730분
                let lunchEndMinutes = 13 * 60 // 13:00 = 780분
                
                if currentTotalMinutes > currentEndMinutes && currentTotalMinutes < lunchEndMinutes {
                    return .lunchTime
                }
            }
            
            // 다음 교시가 있는 경우 쉬는 시간과 수업 전 시간 확인
            if index < PeriodTime.allPeriods.count - 1 {
                let nextPeriod = PeriodTime.allPeriods[index + 1]
                let currentEndMinutes = period.endTime.hour * 60 + period.endTime.minute
                let nextStartMinutes = nextPeriod.startTime.hour * 60 + nextPeriod.startTime.minute
                let nextPreClassMinutes = nextStartMinutes - 10
                
                // 4교시 이후는 점심시간으로 별도 처리되므로 제외
                if index != 3 {
                    if currentTotalMinutes > currentEndMinutes && currentTotalMinutes < nextPreClassMinutes {
                        return .breakTime(periodNumber + 1)
                    } else if currentTotalMinutes >= nextPreClassMinutes && currentTotalMinutes < nextStartMinutes {
                        return .preClass(periodNumber + 1)
                    }
                }
            }
        }
        
        // 5교시 수업 10분 전 (13:00 ~ 13:10) 처리
        let fifthPeriodPreStart = 13 * 60 // 13:00 = 780분
        let fifthPeriodStart = 13 * 60 + 10 // 13:10 = 790분
        
        if currentTotalMinutes >= fifthPeriodPreStart && currentTotalMinutes < fifthPeriodStart {
            return .preClass(5)
        }
        
        // 하교 후
        return .afterSchool
    }
}

// MARK: - 시간 관련 유틸리티
struct TimeUtility {
    
    // MARK: - 현재 교시 관련
    
    /// 현재 교시 상태 가져오기
    static func getCurrentPeriodStatus(at date: Date = Date()) -> CurrentPeriodStatus {
        return CurrentPeriodStatus.getCurrentStatus(at: date)
    }
    
    /// 현재 진행 중인 교시 번호 가져오기 (없으면 nil)
    static func getCurrentPeriodNumber(at date: Date = Date()) -> Int? {
        let status = getCurrentPeriodStatus(at: date)
        
        switch status {
        case .inClass(let period):
            return period
        default:
            return nil
        }
    }
    
    /// 다음 교시 번호 가져오기 (없으면 nil)
    static func getNextPeriodNumber(at date: Date = Date()) -> Int? {
        let status = getCurrentPeriodStatus(at: date)
        
        switch status {
        case .preClass(let period), .breakTime(let period):
            return period
        case .beforeSchool:
            return 1
        case .lunchTime:
            return 5 // 점심시간 다음은 5교시
        default:
            return nil
        }
    }
    
    // MARK: - 시간 형식화
    
    /// Date를 "HH:mm" 형태로 변환
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// Date를 "M월 d일 (E)" 형태로 변환
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    /// Date를 "yyyy-MM-dd" 형태로 변환
    static func formatDateISO(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// "HH:mm" 문자열을 Date로 변환 (오늘 날짜 기준)
    static func timeStringToDate(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                            minute: timeComponents.minute ?? 0,
                            second: 0,
                            of: Date())
    }
    
    // MARK: - 요일 관련
    
    /// 현재 요일 인덱스 가져오기 (월요일: 0, 금요일: 4, 주말: -1)
    static func getCurrentWeekdayIndex(at date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 일요일: 1, 월요일: 2, ..., 토요일: 7
        switch weekday {
        case 2...6: // 월요일(2) ~ 금요일(6)
            return weekday - 2 // 0 ~ 4로 변환
        default: // 주말
            return -1
        }
    }
    
    /// 요일 인덱스를 한글 요일명으로 변환
    static func weekdayIndexToKorean(_ index: Int) -> String {
        guard index >= 0 && index < AppConstants.School.weekdays.count else {
            return "주말"
        }
        return AppConstants.School.weekdays[index]
    }
    
    /// 내일이 주말인지 확인
    static func isTomorrowWeekend(from date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else { return false }
        
        let weekday = calendar.component(.weekday, from: tomorrow)
        return weekday == 1 || weekday == 7 // 일요일 또는 토요일
    }
    
    /// 다음 수업일 가져오기 (주말 제외)
    static func getNextSchoolDay(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var nextDay = date
        
        repeat {
            guard let next = calendar.date(byAdding: .day, value: 1, to: nextDay) else { break }
            nextDay = next
            
            let weekday = calendar.component(.weekday, from: nextDay)
            if weekday >= 2 && weekday <= 6 { // 월요일 ~ 금요일
                break
            }
        } while true
        
        return nextDay
    }
    
    // MARK: - 교시 시간 관련
    
    /// 특정 교시의 시작 시간 가져오기
    static func getPeriodStartTime(period: Int) -> (hour: Int, minute: Int)? {
        guard period >= 1 && period <= PeriodTime.allPeriods.count else { return nil }
        return PeriodTime.allPeriods[period - 1].startTime
    }
    
    /// 특정 교시의 종료 시간 가져오기
    static func getPeriodEndTime(period: Int) -> (hour: Int, minute: Int)? {
        guard period >= 1 && period <= PeriodTime.allPeriods.count else { return nil }
        return PeriodTime.allPeriods[period - 1].endTime
    }
    
    /// 특정 교시의 시간 문자열 가져오기 ("08:20 - 09:10")
    static func getPeriodTimeString(period: Int) -> String {
        guard period >= 1 && period <= AppConstants.School.periodTimeStrings.count else {
            return "시간 정보 없음"
        }
        
        let timeInfo = AppConstants.School.periodTimeStrings[period - 1]
        return "\(timeInfo.0) - \(timeInfo.1)"
    }
    
    /// 현재 시간이 학교 시간인지 확인 (7시 ~ 17시) - 기존 로직 유지
    static func isSchoolHours(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let weekdayIndex = getCurrentWeekdayIndex(at: date)
        
        return weekdayIndex >= 0 && hour >= 7 && hour < 17
    }
    
    /// Live Activity를 위한 정확한 학교 시간 체크 (8시 ~ 16시 30분)
    static func isLiveActivitySchoolHours(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let weekdayIndex = getCurrentWeekdayIndex(at: date)
        
        guard weekdayIndex >= 0 else { return false } // 주말은 false
        
        let currentTotalMinutes = hour * 60 + minute
        let schoolStartMinutes = 8 * 60  // 8:00
        let schoolEndMinutes = 16 * 60 + 30  // 16:30
        
        return currentTotalMinutes >= schoolStartMinutes && currentTotalMinutes <= schoolEndMinutes
    }
    
    /// Live Activity 자동 시작 시간인지 확인 (8:00 AM)
    static func isLiveActivityStartTime(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let weekdayIndex = getCurrentWeekdayIndex(at: date)
        
        print("🕐 Time check - Hour: \(hour), Minute: \(minute), Weekday: \(weekdayIndex)")
        
        // 8:00~8:05 사이에 시작 (정확히 8:00만 체크하면 놓칠 수 있음)
        let isRightTime = weekdayIndex >= 0 && hour == 8 && minute >= 0 && minute <= 5
        print("🕐 isLiveActivityStartTime: \(isRightTime)")
        
        return isRightTime
    }
    
    /// Live Activity 자동 종료 시간인지 확인 (4:30 PM)
    static func isLiveActivityStopTime(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let weekdayIndex = getCurrentWeekdayIndex(at: date)
        
        return weekdayIndex >= 0 && hour == 16 && minute == 30
    }
    
    /// 현재 시간이 Live Activity가 실행되어야 하는 시간인지 확인
    static func shouldLiveActivityBeRunning(at date: Date = Date()) -> Bool {
        return isLiveActivitySchoolHours(at: date)
    }
    
    /// 다음 수업까지 남은 시간 계산 (분 단위)
    static func getMinutesUntilNextClass(at date: Date = Date()) -> Int? {
        let status = getCurrentPeriodStatus(at: date)
        
        switch status {
        case .inClass(let period):
            // 현재 수업 중이면 수업 종료까지 남은 시간
            guard let endTime = getPeriodEndTime(period: period) else { return nil }
            
            let calendar = Calendar.current
            guard let classEndTime = calendar.date(bySettingHour: endTime.hour,
                                                   minute: endTime.minute,
                                                   second: 0,
                                                   of: date) else { return nil }
            
            let timeDifference = classEndTime.timeIntervalSince(date)
            return max(0, Int(timeDifference / 60))
            
        case .preClass(let period), .breakTime(let period):
            // 5교시 전 쉬는시간 (13:00 ~ 13:10)인 경우 특별 처리
            if period == 5 {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: date)
                let minute = calendar.component(.minute, from: date)
                let currentTotalMinutes = hour * 60 + minute
                
                // 13:00 ~ 13:10 가정 (5교시 전 쉬는시간)
                let fifthPeriodStart = 13 * 60 + 10 // 13:10
                
                if currentTotalMinutes >= 13 * 60 && currentTotalMinutes < fifthPeriodStart {
                    // 5교시 시작까지 남은 시간
                    return max(0, fifthPeriodStart - currentTotalMinutes)
                }
            }
            
            // 일반 수업 전이면 수업 시작까지 남은 시간
            guard let startTime = getPeriodStartTime(period: period) else { return nil }
            
            let calendar = Calendar.current
            guard let nextClassTime = calendar.date(bySettingHour: startTime.hour,
                                                   minute: startTime.minute,
                                                   second: 0,
                                                   of: date) else { return nil }
            
            let timeDifference = nextClassTime.timeIntervalSince(date)
            return max(0, Int(timeDifference / 60))
            
        case .lunchTime:
            // 점심시간이면 13:00(점심시간 끝)까지 남은 시간
            let calendar = Calendar.current
            guard let lunchEndTime = calendar.date(bySettingHour: 13,
                                                   minute: 0,
                                                   second: 0,
                                                   of: date) else { return nil }
            
            let timeDifference = lunchEndTime.timeIntervalSince(date)
            return max(0, Int(timeDifference / 60))
            
        default:
            return 0
        }
    }
}