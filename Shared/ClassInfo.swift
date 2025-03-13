import Foundation
import WidgetKit

// 수업 정보 모델
struct ClassInfo {
    let subject: String
    let teacher: String  // 교실
    let periodIndex: Int
    let startTime: Date
    let endTime: Date
}

class WidgetScheduleManager {
    static let shared = WidgetScheduleManager()
    
    private let sharedDefaults = SharedUserDefaults.shared.userDefaults
    
    private init() {}
    
    // 다음 수업 정보 가져오기
    func getNextClass() -> ClassInfo? {
        // 현재 요일 및 시간 확인
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now) - 1 // 일요일: 0, 월요일: 1
        
        // 주말이면 다음 월요일 첫 수업 반환
        if weekday == 0 || weekday == 6 {
            return getNextMondayFirstClass()
        }
        
        // 현재 학년/반 가져오기
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        // 시간표 데이터 가져오기
        guard let scheduleData = loadScheduleData(grade: grade, classNumber: classNumber),
              weekday >= 1 && weekday <= 5,
              let daySchedule = scheduleData.schedules[safe: weekday - 1] else {
            return nil
        }
        
        // 현재 수업 인덱스 찾기
        let currentPeriodIndex = getCurrentPeriodIndex(now: now)
        
        // 오늘 남은 수업 확인
        for i in 0..<daySchedule.count {
            if i > currentPeriodIndex && !daySchedule[i].subject.isEmpty {
                // 다음 수업 시간 정보 생성
                if let classTime = createClassTime(periodIndex: i) {
                    return ClassInfo(
                        subject: getDisplaySubject(scheduleItem: daySchedule[i]),
                        teacher: getDisplayLocation(scheduleItem: daySchedule[i]),
                        periodIndex: i,
                        startTime: classTime.startTime,
                        endTime: classTime.endTime
                    )
                }
            }
        }
        
        // 오늘 남은 수업이 없으면 다음 요일 첫 수업 찾기
        return getNextDayFirstClass(currentWeekday: weekday)
    }
    
    private func getCurrentPeriodIndex(now: Date) -> Int {
        let periodTimes: [(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)] = [
            (8, 20, 9, 10), (9, 20, 10, 10), (10, 20, 11, 10), (11, 20, 12, 10),
            (13, 10, 14, 0), (14, 10, 15, 0), (15, 10, 16, 0)
        ]
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        for (index, period) in periodTimes.enumerated() {
            let startTotalMinutes = period.startHour * 60 + period.startMinute
            let endTotalMinutes = period.endHour * 60 + period.endMinute
            let currentTotalMinutes = hour * 60 + minute
            
            if currentTotalMinutes < endTotalMinutes {
                return index
            }
        }
        
        return periodTimes.count - 1
    }
    
    private func createClassTime(periodIndex: Int) -> (startTime: Date, endTime: Date)? {
        let periodTimes: [(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)] = [
            (8, 20, 9, 10), (9, 20, 10, 10), (10, 20, 11, 10), (11, 20, 12, 10),
            (13, 10, 14, 0), (14, 10, 15, 0), (15, 10, 16, 0)
        ]
        
        guard periodIndex >= 0 && periodIndex < periodTimes.count else {
            return nil
        }
        
        let period = periodTimes[periodIndex]
        let calendar = Calendar.current
        let now = Date()
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = period.startHour
        startComponents.minute = period.startMinute
        startComponents.second = 0
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = period.endHour
        endComponents.minute = period.endMinute
        endComponents.second = 0
        
        guard let startTime = calendar.date(from: startComponents),
              let endTime = calendar.date(from: endComponents) else {
            return nil
        }
        
        return (startTime, endTime)
    }
    
    private func getNextDayFirstClass(currentWeekday: Int) -> ClassInfo? {
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        guard let scheduleData = loadScheduleData(grade: grade, classNumber: classNumber) else {
            return nil
        }
        
        // 다음 요일 확인 (월요일~금요일 순환)
        var nextWeekday = currentWeekday + 1
        if nextWeekday > 5 {
            nextWeekday = 1 // 다음 주 월요일
        }
        
        // API에서는 월요일이 0, 화요일이 1, ... 금요일이 4로 인덱싱됨
        let apiWeekday = nextWeekday - 1
        
        // 다음 요일 시간표 확인
        while nextWeekday <= 5 {
            if let daySchedule = scheduleData.schedules[safe: apiWeekday], !daySchedule.isEmpty {
                // 첫 번째 수업 찾기
                for (index, schedule) in daySchedule.enumerated() {
                    if !schedule.subject.isEmpty {
                        // 해당 요일의 첫 수업 정보 생성
                        if let classTime = createClassTimeForDay(periodIndex: index, daysToAdd: nextWeekday - currentWeekday) {
                            return ClassInfo(
                                subject: getDisplaySubject(scheduleItem: schedule),
                                teacher: getDisplayLocation(scheduleItem: schedule),
                                periodIndex: index,
                                startTime: classTime.startTime,
                                endTime: classTime.endTime
                            )
                        }
                    }
                }
            }
            
            nextWeekday += 1
        }
        
        // 이번 주에 수업이 없으면 다음 주 월요일 첫 수업
        return getNextMondayFirstClass()
    }
    
    private func getNextMondayFirstClass() -> ClassInfo? {
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        guard let scheduleData = loadScheduleData(grade: grade, classNumber: classNumber),
              let mondaySchedule = scheduleData.schedules[safe: 0], !mondaySchedule.isEmpty else {
            return nil
        }
        
        // 월요일 첫 수업 찾기
        for (index, schedule) in mondaySchedule.enumerated() {
            if !schedule.subject.isEmpty {
                // 다음 주 월요일까지 날짜 계산
                let calendar = Calendar.current
                let now = Date()
                let weekday = calendar.component(.weekday, from: now)
                let daysUntilNextMonday = (9 - weekday) % 7 // 다음 월요일까지 남은 일수
                
                if let classTime = createClassTimeForDay(periodIndex: index, daysToAdd: daysUntilNextMonday) {
                    return ClassInfo(
                        subject: getDisplaySubject(scheduleItem: schedule),
                        teacher: getDisplayLocation(scheduleItem: schedule),
                        periodIndex: index,
                        startTime: classTime.startTime,
                        endTime: classTime.endTime
                    )
                }
            }
        }
        
        return nil
    }
    
    private func createClassTimeForDay(periodIndex: Int, daysToAdd: Int) -> (startTime: Date, endTime: Date)? {
        let periodTimes: [(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)] = [
            (8, 20, 9, 10), (9, 20, 10, 10), (10, 20, 11, 10), (11, 20, 12, 10),
            (13, 10, 14, 0), (14, 10, 15, 0), (15, 10, 16, 0)
        ]
        
        guard periodIndex >= 0 && periodIndex < periodTimes.count else {
            return nil
        }
        
        let period = periodTimes[periodIndex]
        let calendar = Calendar.current
        let now = Date()
        
        // 지정된 일수만큼 이후의 날짜
        guard let futureDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
            return nil
        }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
        startComponents.hour = period.startHour
        startComponents.minute = period.startMinute
        startComponents.second = 0
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
        endComponents.hour = period.endHour
        endComponents.minute = period.endMinute
        endComponents.second = 0
        
        guard let startTime = calendar.date(from: startComponents),
              let endTime = calendar.date(from: endComponents) else {
            return nil
        }
        
        return (startTime, endTime)
    }
    
    // 과목명 표시 (탐구반 커스텀 적용)
    private func getDisplaySubject(scheduleItem: ScheduleItem) -> String {
        var displaySubject = scheduleItem.subject
        
        if scheduleItem.subject.contains("반") {
            let customKey = "selected\(scheduleItem.subject)Subject"
            
            if let selectedSubject = sharedDefaults.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
                
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displaySubject = components[0]
                }
            }
        }
        
        return displaySubject
    }
    
    // 교실 정보 표시 (탐구반 커스텀 적용)
    private func getDisplayLocation(scheduleItem: ScheduleItem) -> String {
        var displayLocation = scheduleItem.teacher
        
        if scheduleItem.subject.contains("반") {
            let customKey = "selected\(scheduleItem.subject)Subject"
            
            if let selectedSubject = sharedDefaults.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
                
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displayLocation = components[1]
                }
            }
        }
        
        return displayLocation
    }
    
    // 시간표 데이터 로드
    private func loadScheduleData(grade: Int, classNumber: Int) -> ScheduleData? {
        guard let data = sharedDefaults.data(forKey: "schedule_data_store") else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(ScheduleData.self, from: data)
        } catch {
            print("시간표 데이터 로드 실패: \(error)")
            return nil
        }
    }
}

// Collection 확장 (TimeTableTab.swift에서 가져옴)
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}