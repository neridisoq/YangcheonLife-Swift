import Foundation
import WidgetKit

// MARK: - 위젯에 표시할 수업 정보 구조체
public struct ClassInfo {
    public let subject: String
    public let teacher: String  // 교실
    public let periodIndex: Int
    public let startTime: Date
    public let endTime: Date
    
    public init(subject: String, teacher: String, periodIndex: Int, startTime: Date, endTime: Date) {
        self.subject = subject
        self.teacher = teacher
        self.periodIndex = periodIndex
        self.startTime = startTime
        self.endTime = endTime
    }
}

// 디스플레이 모드 열거형
public enum DisplayMode {
    case nextClass(ClassInfo)
    case peInfo(weekday: Int, hasPhysicalEducation: Bool)
    case mealInfo(MealInfo)  // 급식 정보 추가
    case noInfo
}

// 위젯 엔트리 구조체
public struct NextClassEntry: TimelineEntry {
    public let date: Date
    public let displayMode: DisplayMode
    public let grade: Int
    public let classNumber: Int
    
    public init(date: Date, displayMode: DisplayMode, grade: Int, classNumber: Int) {
        self.date = date
        self.displayMode = displayMode
        self.grade = grade
        self.classNumber = classNumber
    }
}