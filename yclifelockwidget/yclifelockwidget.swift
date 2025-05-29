import WidgetKit
import SwiftUI

struct YclifeLockWidget: Widget {
    let kind: String = "YclifeLockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else if #available(iOS 16.0, *) {
                LockWidgetEntryView(entry: entry)
                    .widgetAccentable()
            } else {
                LockWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("다음 수업")
        .description("다음 수업 정보를 잠금화면에 표시합니다.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockWidgetEntry {
        // Show sample data in placeholder
        let currentDate = Date()
        let calendar = Calendar.current
        let sampleClass = LockClassInfo(
            subject: "수학",
            classroom: "301호",
            period: 3,
            startTime: calendar.date(bySettingHour: 10, minute: 20, second: 0, of: currentDate) ?? currentDate,
            endTime: calendar.date(bySettingHour: 11, minute: 10, second: 0, of: currentDate) ?? currentDate
        )
        
        return LockWidgetEntry(
            date: currentDate,
            displayMode: .nextClass(sampleClass),
            grade: 3,
            classNumber: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LockWidgetEntry) -> Void) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        let displayMode = LockWidgetDataService.shared.getDisplayMode(for: context.family)
        
        let entry = LockWidgetEntry(
            date: Date(),
            displayMode: displayMode,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockWidgetEntry>) -> Void) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        let currentDate = Date()
        let displayMode = LockWidgetDataService.shared.getDisplayMode(for: context.family)
        
        let entry = LockWidgetEntry(
            date: currentDate,
            displayMode: displayMode,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        // 다음 갱신 시간 계산 (5분 후)
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
        
        completion(timeline)
    }
}

struct LockWidgetEntry: TimelineEntry {
    let date: Date
    let displayMode: LockWidgetDisplayMode
    let grade: Int
    let classNumber: Int
}

enum LockWidgetDisplayMode {
    case nextClass(LockClassInfo)
    case peInfo(weekday: Int, hasPhysicalEducation: Bool)
    case noInfo
}

struct LockClassInfo {
    let subject: String
    let classroom: String
    let period: Int
    let startTime: Date
    let endTime: Date
}

struct LockWidgetEntryView: View {
    var entry: LockWidgetEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            if #available(iOS 16.0, *) {
                CircularWidgetView(entry: entry)
            } else {
                Text("iOS 16+ 필요")
            }
        case .accessoryRectangular:
            if #available(iOS 16.0, *) {
                RectangularWidgetView(entry: entry)
            } else {
                Text("iOS 16+ 필요")
            }
        case .accessoryInline:
            if #available(iOS 16.0, *) {
                InlineWidgetView(entry: entry)
            } else {
                Text("iOS 16+ 필요")
            }
        default:
            Text("지원되지 않는 위젯")
        }
    }
}

// MARK: - Circular Widget (원형)
@available(iOS 16.0, *)
struct CircularWidgetView: View {
    let entry: LockWidgetEntry
    
    var body: some View {
        switch entry.displayMode {
        case .nextClass(let classInfo):
            VStack(spacing: 2) {
                Text(getShortSubjectName(classInfo.subject))
                    .font(.system(size: 12, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text("\(classInfo.classroom)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
        case .peInfo(_, let hasPhysicalEducation):
            Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                .font(.system(size: 20))
                .foregroundColor(hasPhysicalEducation ? .primary : .secondary)
            
        case .noInfo:
            VStack(spacing: 1) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Text("수업")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Rectangular Widget (직사각형)
@available(iOS 16.0, *)
struct RectangularWidgetView: View {
    let entry: LockWidgetEntry
    
    var body: some View {
        switch entry.displayMode {
        case .nextClass(let classInfo):
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("다음교시 \(classInfo.period)교시")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text(classInfo.subject)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    
                    Text(classInfo.classroom)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.leading, 2)
            
        case .peInfo(let weekday, let hasPhysicalEducation):
            HStack(spacing: 6) {
                Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                    .font(.system(size: 14))
                    .foregroundColor(hasPhysicalEducation ? .primary : .secondary)
                
                Text("\(weekdayString(weekday)) 체육 \(hasPhysicalEducation ? "있음" : "없음")")
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            
        case .noInfo:
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("수업 정보 없음")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Inline Widget (인라인)
@available(iOS 16.0, *)
struct InlineWidgetView: View {
    let entry: LockWidgetEntry
    
    var body: some View {
        switch entry.displayMode {
        case .nextClass(let classInfo):
            ViewThatFits {
                Text("\(classInfo.period)교시 \(classInfo.subject) (\(classInfo.classroom))")
                Text("\(classInfo.period)교시 \(classInfo.subject)")
                Text(classInfo.subject)
            }
            .font(.system(size: 12))
            
        case .peInfo(let weekday, let hasPhysicalEducation):
            Text("\(weekdayString(weekday)) 체육 \(hasPhysicalEducation ? "있음" : "없음")")
                .font(.system(size: 12))
                
        case .noInfo:
            Text("수업 정보 없음")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Helper Functions
private func weekdayString(_ weekday: Int) -> String {
    switch weekday {
    case 1: return "일"
    case 2: return "월"
    case 3: return "화"
    case 4: return "수"
    case 5: return "목"
    case 6: return "금"
    case 7: return "토"
    default: return "?"
    }
}

private func getShortSubjectName(_ subject: String) -> String {
    let abbreviations: [String: String] = [
        "물리": "물리",
        "물리학": "물리",
        "생명": "생명",
        "생명과학": "생명",
        "화학": "화학",
        "지구과학": "지구",
        "지구": "지구",
        "수학": "수학",
        "국어": "국어",
        "영어": "영어",
        "사회": "사회",
        "역사": "역사",
        "체육": "체육",
        "진로": "진로",
        "미술": "미술",
        "음악": "음악",
        "정보": "정보",
        "논술": "논술",
        "심화국어": "심국",
        "심화수학": "심수",
        "심화영어": "심영"
    ]
    
    for (key, abbr) in abbreviations {
        if subject.contains(key) {
            return abbr
        }
    }
    
    return subject
}

// MARK: - Data Service
class LockWidgetDataService {
    static let shared = LockWidgetDataService()
    
    private init() {}
    
    func getDisplayMode(for family: WidgetFamily) -> LockWidgetDisplayMode {
        let currentDate = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let weekday = calendar.component(.weekday, from: currentDate)
        
        // For testing purposes, always show something even on weekends
        // Comment out weekend check temporarily
        // if weekday == 1 || weekday == 7 {
        //     return .noInfo
        // }
        
        // Get schedule data
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        
        // Try to get schedule data, but provide fallback
        if let data = sharedDefaults.data(forKey: "schedule_data_store"),
           let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data) {
            
            // Check for PE info (evening or early morning)
            if hour >= 18 || hour < 8 {
                if let peInfo = getPEInfo(from: scheduleData, at: currentDate) {
                    return .peInfo(weekday: peInfo.weekday, hasPhysicalEducation: peInfo.hasPhysicalEducation)
                }
            }
            
            // Otherwise show next class
            if let nextClass = getNextClass(from: scheduleData, at: currentDate) {
                return .nextClass(nextClass)
            }
        }
        
        // Fallback: show sample data for testing
        return .nextClass(LockClassInfo(
            subject: "수학",
            classroom: "301호",
            period: 3,
            startTime: calendar.date(bySettingHour: 10, minute: 20, second: 0, of: currentDate) ?? currentDate,
            endTime: calendar.date(bySettingHour: 11, minute: 10, second: 0, of: currentDate) ?? currentDate
        ))
    }
    
    private func getNextClass(from scheduleData: ScheduleData, at date: Date) -> LockClassInfo? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 2 // Convert to 0-based
        
        guard weekday >= 0 && weekday < 5 else { return nil }
        
        let dailySchedule = scheduleData.getDailySchedule(for: weekday)
        
        // TimeUtility의 getCurrentPeriodStatus 사용
        let timeStatus = getCurrentPeriodStatus(at: date)
        
        let startPeriod: Int
        switch timeStatus {
        case .beforeSchool:
            startPeriod = 1
        case .inClass(let period):
            // 7교시 중이면 학교 끝
            if period == 7 {
                return LockClassInfo(
                    subject: "학교 끝!",
                    classroom: "",
                    period: 0,
                    startTime: date,
                    endTime: date
                )
            }
            // 현재 수업 중이면 다음 교시부터
            startPeriod = period + 1
        case .breakTime(let nextPeriod), .preClass(let nextPeriod):
            // 쉬는시간이나 수업 전이면 해당 교시부터
            startPeriod = nextPeriod
        case .lunchTime:
            // 점심시간이면 5교시부터
            startPeriod = 5
        case .afterSchool:
            // 하교 후면 다음날 1교시부터
            return getNextDayFirstClass(from: scheduleData, currentDate: date)
        }
        
        // 현재일 수업 찾기
        if startPeriod <= 7 {
            for period in startPeriod...7 {
                if let classItem = dailySchedule.first(where: { $0.period == period }) {
                    let startTime = getPeriodStartTime(period: period, date: date)
                    let endTime = getPeriodEndTime(period: period, date: date)
                    
                    return LockClassInfo(
                        subject: getDisplaySubject(classItem),
                        classroom: getDisplayClassroom(classItem),
                        period: period,
                        startTime: startTime,
                        endTime: endTime
                    )
                }
            }
        }
        
        // 현재일에 수업이 없으면 다음날 찾기
        return getNextDayFirstClass(from: scheduleData, currentDate: date)
    }
    
    private func getNextDayFirstClass(from scheduleData: ScheduleData, currentDate: Date) -> LockClassInfo? {
        let calendar = Calendar.current
        var nextDay = currentDate
        
        // 다음 수업일 찾기 (최대 7일까지)
        for _ in 1...7 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: nextDay) else { return nil }
            nextDay = next
            
            let weekday = calendar.component(.weekday, from: nextDay) - 2
            guard weekday >= 0 && weekday < 5 else { continue } // 주말 스킵
            
            let dailySchedule = scheduleData.getDailySchedule(for: weekday)
            
            // 1교시부터 7교시까지 찾기
            for period in 1...7 {
                if let classItem = dailySchedule.first(where: { $0.period == period }) {
                    let startTime = getPeriodStartTime(period: period, date: nextDay)
                    let endTime = getPeriodEndTime(period: period, date: nextDay)
                    
                    return LockClassInfo(
                        subject: getDisplaySubject(classItem),
                        classroom: getDisplayClassroom(classItem),
                        period: period,
                        startTime: startTime,
                        endTime: endTime
                    )
                }
            }
        }
        
        return nil
    }
    
    private func getCurrentPeriodStatus(at date: Date) -> CurrentPeriodStatus {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTotalMinutes = hour * 60 + minute
        
        // 등교 전 (8:10 이전)
        if currentTotalMinutes < (8 * 60 + 10) {
            return .beforeSchool
        }
        
        let periodTimes = [
            (start: 8 * 60 + 20, end: 9 * 60 + 10),   // 1교시
            (start: 9 * 60 + 20, end: 10 * 60 + 10),  // 2교시
            (start: 10 * 60 + 20, end: 11 * 60 + 10), // 3교시
            (start: 11 * 60 + 20, end: 12 * 60 + 10), // 4교시
            (start: 13 * 60 + 10, end: 14 * 60),      // 5교시
            (start: 14 * 60 + 10, end: 15 * 60),      // 6교시
            (start: 15 * 60 + 10, end: 16 * 60)       // 7교시
        ]
        
        // 각 교시 시간 확인
        for (index, time) in periodTimes.enumerated() {
            let periodNumber = index + 1
            
            // 수업 중
            if currentTotalMinutes >= time.start && currentTotalMinutes <= time.end {
                return .inClass(periodNumber)
            }
            
            // 수업 10분 전
            if currentTotalMinutes >= (time.start - 10) && currentTotalMinutes < time.start {
                return .preClass(periodNumber)
            }
            
            // 쉬는시간 (다음 교시까지)
            if index < periodTimes.count - 1 {
                let nextTime = periodTimes[index + 1]
                if currentTotalMinutes > time.end && currentTotalMinutes < (nextTime.start - 10) {
                    // 4교시 후는 점심시간
                    if periodNumber == 4 {
                        return .lunchTime
                    } else {
                        return .breakTime(periodNumber + 1)
                    }
                }
            }
        }
        
        // 점심시간 (12:10 ~ 13:00)
        if currentTotalMinutes > (12 * 60 + 10) && currentTotalMinutes < (13 * 60) {
            return .lunchTime
        }
        
        // 하교 후
        return .afterSchool
    }
    
    enum CurrentPeriodStatus {
        case beforeSchool
        case inClass(Int)
        case breakTime(Int)
        case preClass(Int)
        case lunchTime
        case afterSchool
    }
    
    private func getPEInfo(from scheduleData: ScheduleData, at date: Date) -> (weekday: Int, hasPhysicalEducation: Bool)? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let currentWeekday = calendar.component(.weekday, from: date)
        
        // Check tomorrow's PE if it's evening
        let targetWeekday = hour >= 18 ? (currentWeekday == 6 ? 2 : currentWeekday + 1) : currentWeekday
        let scheduleWeekday = targetWeekday - 2 // Convert to 0-based
        
        guard scheduleWeekday >= 0 && scheduleWeekday < 5 else { return nil }
        
        let dailySchedule = scheduleData.getDailySchedule(for: scheduleWeekday)
        let hasPhysicalEducation = dailySchedule.contains { $0.subject.contains("체육") }
        
        return (weekday: targetWeekday, hasPhysicalEducation: hasPhysicalEducation)
    }
    
    
    private func getPeriodStartTime(period: Int, date: Date) -> Date {
        let calendar = Calendar.current
        let startTimes = [
            (8, 20), (9, 20), (10, 20), (11, 20),
            (13, 10), (14, 10), (15, 10)
        ]
        
        guard period >= 1 && period <= 7 else { return date }
        
        let (hour, minute) = startTimes[period - 1]
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
    
    private func getPeriodEndTime(period: Int, date: Date) -> Date {
        let calendar = Calendar.current
        let endTimes = [
            (9, 10), (10, 10), (11, 10), (12, 10),
            (14, 0), (15, 0), (16, 0)
        ]
        
        guard period >= 1 && period <= 7 else { return date }
        
        let (hour, minute) = endTimes[period - 1]
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
    
    private func getDisplaySubject(_ item: ScheduleItem) -> String {
        var displaySubject = item.subject
        
        if item.subject.contains("반") {
            let customKey = "selected\(item.subject)Subject"
            
            if let selectedSubject = SharedUserDefaults.shared.userDefaults.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != item.subject {
                
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displaySubject = components[0]
                }
            }
        }
        
        return displaySubject
    }
    
    private func getDisplayClassroom(_ item: ScheduleItem) -> String {
        var displayClassroom = item.classroom
        
        if item.subject.contains("반") {
            let customKey = "selected\(item.subject)Subject"
            
            if let selectedSubject = SharedUserDefaults.shared.userDefaults.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != item.subject {
                
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displayClassroom = components[1]
                }
            }
        }
        
        return displayClassroom
    }
}
