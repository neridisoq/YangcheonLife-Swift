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
        
        // 급식 시간대인지 확인하고 미리 데이터 가져오기
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let minute = calendar.component(.minute, from: currentDate)
        let currentMinutes = hour * 60 + minute
        
        // 급식 시간대에 데이터 미리 가져오기
        if context.family == .systemMedium {
            if currentMinutes >= (11 * 60 + 20) && currentMinutes < (12 * 60 + 50) {
                // 점심시간: 급식 정보 가져오기
                fetchMealDataIfNeeded(date: currentDate, mealType: .lunch) {
                    self.createTimelineEntry(currentDate: currentDate, grade: finalGrade, classNumber: finalClass, family: context.family, completion: completion)
                }
                return
            } else if currentMinutes >= (15 * 60 + 10) && currentMinutes <= (17 * 60 + 30) {
                // 석식시간: 석식 정보 가져오기, 없으면 다음날 중식
                fetchMealDataIfNeeded(date: currentDate, mealType: .dinner) {
                    let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    self.fetchMealDataIfNeeded(date: nextDay, mealType: .lunch) {
                        self.createTimelineEntry(currentDate: currentDate, grade: finalGrade, classNumber: finalClass, family: context.family, completion: completion)
                    }
                }
                return
            }
        }
        
        // 일반적인 경우
        createTimelineEntry(currentDate: currentDate, grade: finalGrade, classNumber: finalClass, family: context.family, completion: completion)
    }
    
    private func fetchMealDataIfNeeded(date: Date, mealType: MealType, completion: @escaping () -> Void) {
        // 이미 캐시된 데이터가 있으면 바로 완료
        if NeisAPIManager.shared.getCachedMeal(date: date, mealType: mealType) != nil {
            completion()
            return
        }
        
        // 캐시가 없으면 API 호출
        NeisAPIManager.shared.fetchMeal(date: date, mealType: mealType) { mealInfo in
            if let mealInfo = mealInfo {
                NeisAPIManager.shared.cacheMeal(date: date, mealInfo: mealInfo)
            }
            completion()
        }
    }
    
    private func createTimelineEntry(currentDate: Date, grade: Int, classNumber: Int, family: WidgetFamily, completion: @escaping (Timeline<MainWidgetEntry>) -> Void) {
        let displayMode = MainWidgetDataService.shared.getDisplayMode(for: family)
        
        let entry = MainWidgetEntry(
            date: currentDate,
            displayMode: displayMode,
            grade: grade,
            classNumber: classNumber
        )
        
        // 다음 갱신 시간 계산 (1분 후)
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
                    
                    Text(getDisplaySubject(classInfo))
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(getDisplayClassroom(classInfo))
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
        case .peInfo(let weekday, let hasPhysicalEducation):
            PEMediumWidgetView(weekday: weekday, hasPhysicalEducation: hasPhysicalEducation, entry: entry)
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
                
                Text(getDisplaySubject(classInfo))
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(getDisplayClassroom(classInfo))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Text("\(classInfo.period)교시")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\(formatTime(classInfo.startTime)) ~ \(formatTime(classInfo.endTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
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

struct PEMediumWidgetView: View {
    let weekday: Int
    let hasPhysicalEducation: Bool
    let entry: MainWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - PE info
            VStack(alignment: .leading, spacing: 8) {
                Text("\(entry.grade)학년 \(entry.classNumber)반")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("내일 체육")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(weekdayString(weekday)) 체육")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(hasPhysicalEducation ? "있음" : "없음")
                    .font(.subheadline)
                    .foregroundColor(hasPhysicalEducation ? .blue : .secondary)
                
                Spacer()
            }
            
            Spacer()
            
            // Right side - Icon
            VStack {
                Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                    .font(.system(size: 40))
                    .foregroundColor(hasPhysicalEducation ? .blue : .gray)
                
                Text(hasPhysicalEducation ? "준비하세요!" : "편안한 하루")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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

private func getDisplaySubject(_ classInfo: ClassInfo) -> String {
    var displaySubject = classInfo.subject
    
    if classInfo.subject.contains("반") {
        let customKey = "selected\(classInfo.subject)Subject"
        
        if let selectedSubject = SharedUserDefaults.shared.userDefaults.string(forKey: customKey),
           selectedSubject != "선택 없음" && selectedSubject != classInfo.subject {
            
            let components = selectedSubject.components(separatedBy: "/")
            if components.count == 2 {
                displaySubject = components[0]
            }
        }
    }
    
    return displaySubject
}

private func getDisplayClassroom(_ classInfo: ClassInfo) -> String {
    var displayClassroom = classInfo.classroom
    
    if classInfo.subject.contains("반") {
        let customKey = "selected\(classInfo.subject)Subject"
        
        if let selectedSubject = SharedUserDefaults.shared.userDefaults.string(forKey: customKey),
           selectedSubject != "선택 없음" && selectedSubject != classInfo.subject {
            
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
            let minute = calendar.component(.minute, from: currentDate)
            let currentMinutes = hour * 60 + minute
            
            // 4교시 시작 (11:20) 후부터 12시 50분 전까지: 급식
            if currentMinutes >= (11 * 60 + 20) && currentMinutes < (12 * 60 + 50) {
                if let mealInfo = NeisAPIManager.shared.getCachedMeal(date: currentDate, mealType: .lunch) {
                    return .mealInfo(mealInfo)
                }
                // 급식 정보가 없어도 다음 수업을 보여주지 않고 빈 상태로
                return .noInfo
            }
            
            // 7교시 시작 (15:00) 부터 17시 30분까지: 석식
            if currentMinutes >= (15 * 60) && currentMinutes <= (17 * 60 + 30) {
                if let mealInfo = NeisAPIManager.shared.getCachedMeal(date: currentDate, mealType: .dinner) {
                    return .mealInfo(mealInfo)
                }
                // 석식이 없으면 다음날 중식 시도
                let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                if let mealInfo = NeisAPIManager.shared.getCachedMeal(date: nextDay, mealType: .lunch) {
                    return .mealInfo(mealInfo)
                }
                return .noInfo
            }
            
            // 17:30 이후: 다음날 체육 알림
            if currentMinutes > (17 * 60 + 30) || currentMinutes < (8 * 60){
                if let peInfo = getPEInfo(from: scheduleData, at: currentDate) {
                    return .peInfo(weekday: peInfo.weekday, hasPhysicalEducation: peInfo.hasPhysicalEducation)
                }
            }
            
            // 그 외: 다음 수업 (단, 점심시간과 석식시간 제외)
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
        let currentMinute = calendar.component(.minute, from: date)
        
        // 다음 n:00 또는 n:05 시점으로 설정 (5분 간격)
        let targetMinutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
        
        // 현재 분보다 큰 가장 가까운 목표 분 찾기
        if let nextTargetMinute = targetMinutes.first(where: { $0 > currentMinute }) {
            // 같은 시간 내에서 다음 목표 분으로 설정
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
            components.minute = nextTargetMinute
            components.second = 0
            return calendar.date(from: components) ?? date
        } else {
            // 다음 시간의 00분으로 설정
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
            components.hour = (components.hour ?? 0) + 1
            components.minute = 0
            components.second = 0
            return calendar.date(from: components) ?? date
        }
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
        let currentPeriod = getCurrentPeriod(at: date)
        
        // 점심시간(12:10-13:10) 처리: 5교시부터 찾기
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        let startPeriod: Int
        if currentMinutes >= (12 * 60 + 10) && currentMinutes < (13 * 60 + 10) {
            // 점심시간이면 5교시부터 찾기
            startPeriod = 5
        } else {
            // 일반적인 경우: 현재 교시 다음부터 찾기
            startPeriod = (currentPeriod ?? 0) + 1
        }
        
        // 7교시 이후에는 다음 수업이 없으므로 nil 반환 (석식 시간으로 넘어가도록)
        if startPeriod > 7 {
            return nil
        }
        
        // Find next class
        for period in startPeriod...7 {
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
