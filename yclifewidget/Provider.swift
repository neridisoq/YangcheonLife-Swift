import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NextClassEntry {
        NextClassEntry(
            date: Date(),
            nextClass: nil,
            remainingTime: nil,
            grade: 0,
            classNumber: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextClassEntry) -> ()) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let nextClass = WidgetScheduleManager.shared.getNextClass()
        let remainingTime = calculateRemainingTime(nextClass: nextClass)
        
        let entry = NextClassEntry(
            date: Date(),
            nextClass: nextClass,
            remainingTime: remainingTime,
            grade: grade,
            classNumber: classNumber
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextClassEntry>) -> ()) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let nextClass = WidgetScheduleManager.shared.getNextClass()
        let remainingTime = calculateRemainingTime(nextClass: nextClass)
        
        let currentDate = Date()
        let entry = NextClassEntry(
            date: currentDate,
            nextClass: nextClass,
            remainingTime: remainingTime,
            grade: grade,
            classNumber: classNumber
        )
        
        // 다음 업데이트 시간 (10분마다 또는 다음 수업 시작 시)
        let nextUpdateDate: Date
        if let nextClass = nextClass {
            let tenMinutesLater = Calendar.current.date(byAdding: .minute, value: 10, to: currentDate) ?? currentDate
            nextUpdateDate = min(nextClass.startTime, tenMinutesLater)
        } else {
            nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    private func calculateRemainingTime(nextClass: ClassInfo?) -> TimeInterval? {
        guard let nextClass = nextClass else { return nil }
        
        let now = Date()
        return nextClass.startTime.timeIntervalSince(now)
    }
}

// 위젯 엔트리 모델
struct NextClassEntry: TimelineEntry {
    let date: Date
    let nextClass: ClassInfo?
    let remainingTime: TimeInterval?
    let grade: Int
    let classNumber: Int
}