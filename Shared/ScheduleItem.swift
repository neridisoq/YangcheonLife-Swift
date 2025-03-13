//
//  ScheduleItem.swift
//  yangcheonlife
//
//  Created by Woohyun Jin on 3/11/25.
//


import Foundation

// 시간표 항목 구조체
public struct ScheduleItem: Codable {
    public var grade: Int
    public var `class`: Int
    public var weekday: Int
    public var weekdayString: String
    public var classTime: Int
    public var teacher: String
    public var subject: String
    
    public init(grade: Int, class: Int, weekday: Int, weekdayString: String, classTime: Int, teacher: String, subject: String) {
        self.grade = grade
        self.class = `class`
        self.weekday = weekday
        self.weekdayString = weekdayString
        self.classTime = classTime
        self.teacher = teacher
        self.subject = subject
    }
}

// 시간표 데이터 구조체
public struct ScheduleData: Codable, Equatable {
    public let grade: Int
    public let classNumber: Int
    public let lastUpdated: Date
    public let schedules: [[ScheduleItem]]
    
    public init(grade: Int, classNumber: Int, lastUpdated: Date, schedules: [[ScheduleItem]]) {
        self.grade = grade
        self.classNumber = classNumber
        self.lastUpdated = lastUpdated
        self.schedules = schedules
    }
    
    public static func == (lhs: ScheduleData, rhs: ScheduleData) -> Bool {
        // 학년/반 확인
        guard lhs.grade == rhs.grade && lhs.classNumber == rhs.classNumber else {
            return false
        }
        
        // 시간표 내용 비교
        guard lhs.schedules.count == rhs.schedules.count else { return false }
        
        for i in 0..<lhs.schedules.count {
            guard lhs.schedules[i].count == rhs.schedules[i].count else { return false }
            
            for j in 0..<lhs.schedules[i].count {
                let item1 = lhs.schedules[i][j]
                let item2 = rhs.schedules[i][j]
                
                if item1.subject != item2.subject || item1.teacher != item2.teacher {
                    return false
                }
            }
        }
        
        return true
    }
}

// Collection 확장
public extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}