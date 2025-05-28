import Foundation

// MARK: - 시간표 관련 모델들

/// 개별 수업 정보 모델
public struct ScheduleItem: Codable, Equatable, Identifiable {
    public let id = UUID()
    public let grade: Int          // 학년
    public let classNumber: Int    // 반
    public let weekday: Int        // 요일 (0: 월요일, 4: 금요일)
    public let weekdayString: String // 요일 문자열
    public let period: Int         // 교시
    public var classroom: String   // 교실
    public var subject: String     // 과목명
    
    enum CodingKeys: String, CodingKey {
        case grade, classNumber = "class", weekday, weekdayString, period = "classTime", classroom = "teacher", subject
    }
    
    public init(grade: Int, classNumber: Int, weekday: Int, weekdayString: String, period: Int, classroom: String, subject: String) {
        self.grade = grade
        self.classNumber = classNumber
        self.weekday = weekday
        self.weekdayString = weekdayString
        self.period = period
        self.classroom = classroom
        self.subject = subject
    }
}

/// 주간 시간표 데이터 모델
public struct ScheduleData: Codable, Equatable {
    public let grade: Int              // 학년
    public let classNumber: Int        // 반
    public let lastUpdated: Date       // 최종 업데이트 시간
    public let weeklySchedule: [[ScheduleItem]] // 주간 시간표 (5일치)
    
    enum CodingKeys: String, CodingKey {
        case grade, classNumber, lastUpdated, weeklySchedule = "schedules"
    }
    
    public init(grade: Int, classNumber: Int, lastUpdated: Date, weeklySchedule: [[ScheduleItem]]) {
        self.grade = grade
        self.classNumber = classNumber
        self.lastUpdated = lastUpdated
        self.weeklySchedule = weeklySchedule
    }
    
    /// 특정 요일의 시간표 가져오기
    public func getDailySchedule(for weekday: Int) -> [ScheduleItem] {
        guard weekday >= 0 && weekday < weeklySchedule.count else { return [] }
        return weeklySchedule[weekday]
    }
    
    /// 특정 교시의 수업 정보 가져오기
    public func getClassInfo(weekday: Int, period: Int) -> ScheduleItem? {
        let dailySchedule = getDailySchedule(for: weekday)
        return dailySchedule.first { $0.period == period }
    }
}

// PeriodTime은 TimeUtility.swift로 이동되었습니다

