import Foundation

// MARK: - 시간표 관련 모델들

/// 개별 수업 정보 모델
struct ScheduleItem: Codable, Equatable, Identifiable {
    let id = UUID()
    let grade: Int          // 학년
    let classNumber: Int    // 반
    let weekday: Int        // 요일 (0: 월요일, 4: 금요일)
    let weekdayString: String // 요일 문자열
    let period: Int         // 교시
    var classroom: String   // 교실
    var subject: String     // 과목명
    
    enum CodingKeys: String, CodingKey {
        case grade, classNumber = "class", weekday, weekdayString, period = "classTime", classroom = "teacher", subject
    }
    
    init(grade: Int, classNumber: Int, weekday: Int, weekdayString: String, period: Int, classroom: String, subject: String) {
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
struct ScheduleData: Codable, Equatable {
    let grade: Int              // 학년
    let classNumber: Int        // 반
    let lastUpdated: Date       // 최종 업데이트 시간
    let weeklySchedule: [[ScheduleItem]] // 주간 시간표 (5일치)
    
    enum CodingKeys: String, CodingKey {
        case grade, classNumber, lastUpdated, weeklySchedule = "schedules"
    }
    
    init(grade: Int, classNumber: Int, lastUpdated: Date, weeklySchedule: [[ScheduleItem]]) {
        self.grade = grade
        self.classNumber = classNumber
        self.lastUpdated = lastUpdated
        self.weeklySchedule = weeklySchedule
    }
    
    /// 특정 요일의 시간표 가져오기
    func getDailySchedule(for weekday: Int) -> [ScheduleItem] {
        guard weekday >= 0 && weekday < weeklySchedule.count else { return [] }
        return weeklySchedule[weekday]
    }
    
    /// 특정 교시의 수업 정보 가져오기
    func getClassInfo(weekday: Int, period: Int) -> ScheduleItem? {
        let dailySchedule = getDailySchedule(for: weekday)
        return dailySchedule.first { $0.period == period }
    }
}

// PeriodTime은 TimeUtility.swift로 이동되었습니다

