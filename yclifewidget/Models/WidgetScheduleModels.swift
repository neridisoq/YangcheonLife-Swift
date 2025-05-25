// WidgetScheduleModels.swift - 위젯용 시간표 모델
import Foundation

// MARK: - 위젯용 시간표 모델 (기존 모델과 호환성 유지)

/// 개별 수업 정보 (위젯용)
struct ScheduleItem: Codable, Identifiable {
    let id = UUID()
    let grade: Int
    let classNumber: Int      // 기존 'class' 필드와 호환
    let weekday: Int
    let weekdayString: String
    let period: Int          // 기존 'classTime' 필드와 호환
    let classroom: String    // 기존 'teacher' 필드와 호환
    let subject: String
    
    enum CodingKeys: String, CodingKey {
        case grade
        case classNumber = "class"
        case weekday
        case weekdayString
        case period = "classTime"
        case classroom = "teacher"
        case subject
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

/// 주간 시간표 데이터 (위젯용)
struct ScheduleData: Codable {
    let grade: Int
    let classNumber: Int
    let lastUpdated: Date
    let weeklySchedule: [[ScheduleItem]]
    
    enum CodingKeys: String, CodingKey {
        case grade
        case classNumber
        case lastUpdated
        case weeklySchedule = "schedules"
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

// SimpleNextClassEntry는 SimpleNextClassEntry.swift 파일에 정의되어 있습니다