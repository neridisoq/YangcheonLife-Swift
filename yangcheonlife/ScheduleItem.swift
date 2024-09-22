// ScheduleItem.swift
import Foundation

struct ScheduleItem: Decodable {
    var grade: Int
    var `class`: Int
    var weekday: Int
    var weekdayString: String
    var classTime: Int
    var teacher: String
    var subject: String
}
