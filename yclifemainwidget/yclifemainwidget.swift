import WidgetKit
import SwiftUI

struct YclifeMainWidget: Widget {
    let kind: String = "YclifeMainWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MainWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                MainWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                MainWidgetEntryView(entry: entry)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
            }
        }
        .configurationDisplayName("메인 위젯")
        .description("다음 수업과 시간표 정보를 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MainWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MainWidgetEntry {
        MainWidgetEntry(
            date: Date(),
            displayMode: .noInfo,
            grade: 3,
            classNumber: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MainWidgetEntry) -> Void) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        let displayMode = MainWidgetDataService.shared.getDisplayMode(for: context.family)
        
        let entry = MainWidgetEntry(
            date: Date(),
            displayMode: displayMode,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MainWidgetEntry>) -> Void) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        let currentDate = Date()
        let displayMode = MainWidgetDataService.shared.getDisplayMode(for: context.family)
        
        let entry = MainWidgetEntry(
            date: currentDate,
            displayMode: displayMode,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        // 다음 갱신 시간 계산 (5분 후 또는 다음 교시 시작 시간)
        let nextRefreshDate = MainWidgetDataService.shared.getNextRefreshTime(from: currentDate)
        let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
        
        completion(timeline)
    }
}

struct MainWidgetEntry: TimelineEntry {
    let date: Date
    let displayMode: MainWidgetDisplayMode
    let grade: Int
    let classNumber: Int
}

enum MainWidgetDisplayMode {
    case nextClass(ClassInfo)
    case dailySchedule([ScheduleItem], currentPeriod: Int?)
    case mealInfo(MealInfo)
    case peInfo(weekday: Int, hasPhysicalEducation: Bool)
    case noInfo
}

struct ClassInfo {
    let subject: String
    let classroom: String
    let period: Int
    let startTime: Date
    let endTime: Date
}

struct MainWidgetEntryView: View {
    var entry: MainWidgetEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            Text("지원되지 않는 위젯 크기")
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let entry: MainWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("\(entry.grade)학년 \(entry.classNumber)반")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            // Content
            switch entry.displayMode {
            case .nextClass(let classInfo):
                VStack(alignment: .leading, spacing: 4) {
                    Text("다음 수업")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(classInfo.subject)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(classInfo.classroom)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(classInfo.period)교시")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
            case .peInfo(let weekday, let hasPhysicalEducation):
                VStack(spacing: 6) {
                    Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                        .font(.system(size: 24))
                        .foregroundColor(hasPhysicalEducation ? .blue : .gray)
                    
                    Text("\(weekdayString(weekday)) 체육")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(hasPhysicalEducation ? "있음" : "없음")
                        .font(.caption2)
                        .foregroundColor(hasPhysicalEducation ? .blue : .gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            default:
                VStack {
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    Text("정보 없음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    let entry: MainWidgetEntry
    
    var body: some View {
        switch entry.displayMode {
        case .mealInfo(let mealInfo):
            MealWidgetView(mealInfo: mealInfo, entry: entry)
        case .nextClass(let classInfo):
            NextClassMediumView(classInfo: classInfo, entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct NextClassMediumView: View {
    let classInfo: ClassInfo
    let entry: MainWidgetEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Class info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.grade)학년 \(entry.classNumber)반")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("다음 수업")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(classInfo.subject)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(classInfo.classroom)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Text("\(formatTime(classInfo.startTime)) ~ \(formatTime(classInfo.endTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(classInfo.period)교시")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
            
            // Right side - Time info
            VStack(spacing: 4) {
                let timeUntil = classInfo.startTime.timeIntervalSince(entry.date)
                if timeUntil > 0 {
                    Text(formatTimeInterval(timeUntil))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("남음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("진행 중")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
    }
}

struct MealWidgetView: View {
    let mealInfo: MealInfo
    let entry: MainWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                
                Text("\(formatDate(entry.date)) \(mealInfo.mealType.name)")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text(mealInfo.calInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Menu items in grid
            let menuItems = getMenuItems(mealInfo.menuText)
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 4) {
                ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                    if index < 8 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 4, height: 4)
                            Text(item)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
            
            if menuItems.count > 8 {
                Text("외 \(menuItems.count - 8)개...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    let entry: MainWidgetEntry
    
    var body: some View {
        switch entry.displayMode {
        case .dailySchedule(let scheduleItems, let currentPeriod):
            DailyScheduleView(scheduleItems: scheduleItems, currentPeriod: currentPeriod, entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct DailyScheduleView: View {
    let scheduleItems: [ScheduleItem]
    let currentPeriod: Int?
    let entry: MainWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("\(formatDate(entry.date)) 시간표")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(entry.grade)학년 \(entry.classNumber)반")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !scheduleItems.isEmpty {
                // Schedule items
                VStack(spacing: 4) {
                    ForEach(1...7, id: \.self) { period in
                        let scheduleItem = scheduleItems.first { $0.period == period }
                        let isCurrentPeriod = currentPeriod == period
                        
                        ScheduleRowView(
                            period: period,
                            scheduleItem: scheduleItem,
                            isCurrentPeriod: isCurrentPeriod
                        )
                    }
                }
            } else {
                Spacer()
                Text("오늘은 수업이 없습니다")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
        .padding()
    }
}

struct ScheduleRowView: View {
    let period: Int
    let scheduleItem: ScheduleItem?
    let isCurrentPeriod: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Period number
            Text("\(period)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(isCurrentPeriod ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(10)
            
            // Class info
            if let item = scheduleItem {
                HStack {
                    Text(getDisplaySubject(item))
                        .font(.system(size: 14, weight: isCurrentPeriod ? .bold : .regular))
                        .foregroundColor(isCurrentPeriod ? .blue : .primary)
                    
                    Spacer()
                    
                    Text(getDisplayClassroom(item))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isCurrentPeriod ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            } else {
                Text("수업 없음")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M월 d일 (E)"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter.string(from: date)
}

private func formatTimeInterval(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)시간 \(minutes)분"
    } else {
        return "\(minutes)분"
    }
}

private func getMenuItems(_ text: String) -> [String] {
    return text.split(separator: "\n")
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
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

// MARK: - Data Service
class MainWidgetDataService {
    static let shared = MainWidgetDataService()
    
    private init() {}
    
    func getDisplayMode(for family: WidgetFamily) -> MainWidgetDisplayMode {
        let currentDate = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let weekday = calendar.component(.weekday, from: currentDate)
        
        // Weekend check
        if weekday == 1 || weekday == 7 {
            return .noInfo
        }
        
        // Get schedule data
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        guard let data = sharedDefaults.data(forKey: "schedule_data_store"),
              let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data) else {
            return .noInfo
        }
        
        let currentWeekday = weekday - 2 // Convert to 0-based (Monday = 0)
        
        switch family {
        case .systemLarge:
            // Show daily schedule for large widget
            let dailySchedule = scheduleData.getDailySchedule(for: currentWeekday)
            let currentPeriod = getCurrentPeriod(at: currentDate)
            return .dailySchedule(dailySchedule, currentPeriod: currentPeriod)
            
        case .systemMedium:
            // Check if it's meal time
            if (hour >= 12 && hour < 13) || (hour >= 18 && hour < 19) {
                if let mealInfo = getMealInfo(at: currentDate) {
                    return .mealInfo(mealInfo)
                }
            }
            
            // Otherwise show next class
            if let nextClass = getNextClass(from: scheduleData, at: currentDate) {
                return .nextClass(nextClass)
            }
            
            return .noInfo
            
        case .systemSmall:
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
            
            return .noInfo
            
        default:
            return .noInfo
        }
    }
    
    func getNextRefreshTime(from date: Date) -> Date {
        let calendar = Calendar.current
        
        // Refresh every 5 minutes
        return calendar.date(byAdding: .minute, value: 5, to: date) ?? date
    }
    
    private func getCurrentPeriod(at date: Date) -> Int? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        let periodTimes = [
            (start: 8 * 60 + 20, end: 9 * 60 + 10),   // 1교시
            (start: 9 * 60 + 20, end: 10 * 60 + 10),  // 2교시
            (start: 10 * 60 + 20, end: 11 * 60 + 10), // 3교시
            (start: 11 * 60 + 20, end: 12 * 60 + 10), // 4교시
            (start: 13 * 60 + 10, end: 14 * 60),      // 5교시
            (start: 14 * 60 + 10, end: 15 * 60),      // 6교시
            (start: 15 * 60 + 10, end: 16 * 60)       // 7교시
        ]
        
        for (index, time) in periodTimes.enumerated() {
            if currentMinutes >= time.start && currentMinutes <= time.end {
                return index + 1
            }
        }
        
        return nil
    }
    
    private func getNextClass(from scheduleData: ScheduleData, at date: Date) -> ClassInfo? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 2 // Convert to 0-based
        
        guard weekday >= 0 && weekday < 5 else { return nil }
        
        let dailySchedule = scheduleData.getDailySchedule(for: weekday)
        let currentPeriod = getCurrentPeriod(at: date) ?? 0
        
        // Find next class
        for period in (currentPeriod + 1)...7 {
            if let classItem = dailySchedule.first(where: { $0.period == period }) {
                let startTime = getPeriodStartTime(period: period, date: date)
                let endTime = getPeriodEndTime(period: period, date: date)
                
                return ClassInfo(
                    subject: classItem.subject,
                    classroom: classItem.classroom,
                    period: period,
                    startTime: startTime,
                    endTime: endTime
                )
            }
        }
        
        return nil
    }
    
    private func getMealInfo(at date: Date) -> MealInfo? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        let mealType: MealType
        if hour >= 12 && hour < 13 {
            mealType = .lunch
        } else if hour >= 18 && hour < 19 {
            mealType = .dinner
        } else {
            return nil
        }
        
        return NeisAPIManager.shared.getCachedMeal(date: date, mealType: mealType)
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
}
