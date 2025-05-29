import WidgetKit
import SwiftUI
import Foundation

// MARK: - 필요한 모델들과 매니저들을 위젯 내에서 정의


struct YclifeMealWidget: Widget {
    let kind: String = "YclifeMealWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MealWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                MealWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                MealWidgetEntryView(entry: entry)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
            }
        }
        .configurationDisplayName("급식 위젯")
        .description("시간에 따라 자동으로 급식 정보를 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MealWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MealWidgetEntry {
        MealWidgetEntry(
            date: Date(),
            mealInfo: nil,
            isLoading: false,
            grade: 3,
            classNumber: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MealWidgetEntry) -> Void) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        let entry = MealWidgetEntry(
            date: Date(),
            mealInfo: nil,
            isLoading: false,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MealWidgetEntry>) -> Void) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        let currentDate = Date()
        
        // 급식 데이터를 미리 가져오기
        fetchMealDataIfNeeded(date: currentDate) {
            let mealInfo = self.getMealInfoForCurrentTime(at: currentDate)
            
            let entry = MealWidgetEntry(
                date: currentDate,
                mealInfo: mealInfo,
                isLoading: false,
                grade: finalGrade,
                classNumber: finalClass
            )
            
            // 다음 갱신 시간 계산
            let nextRefreshDate = self.getNextRefreshTime(from: currentDate)
            let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
            
            completion(timeline)
        }
    }
    
    private func fetchMealDataIfNeeded(date: Date, completion: @escaping () -> Void) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        var fetchTasks: [(Date, MealType)] = []
        
        // 시간에 따라 필요한 급식 데이터 결정
        if currentMinutes >= (18 * 60) {
            // 다음날 중식이 필요
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            fetchTasks.append((nextDay, .lunch))
        } else if currentMinutes >= (13 * 60 + 30) && currentMinutes < (18 * 60) {
            // 석식과 당일 중식이 필요
            fetchTasks.append((date, .dinner))
            fetchTasks.append((date, .lunch))
        } else {
            // 당일 중식이 필요
            fetchTasks.append((date, .lunch))
        }
        
        let group = DispatchGroup()
        
        for (fetchDate, mealType) in fetchTasks {
            // 이미 캐시된 데이터가 있으면 스킵
            if NeisAPIManager.shared.getCachedMeal(date: fetchDate, mealType: mealType) != nil {
                continue
            }
            
            group.enter()
            NeisAPIManager.shared.fetchMeal(date: fetchDate, mealType: mealType) { mealInfo in
                if let mealInfo = mealInfo {
                    NeisAPIManager.shared.cacheMeal(date: fetchDate, mealInfo: mealInfo)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    private func getMealInfoForCurrentTime(at date: Date) -> MealInfo? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        // 시간별 급식 로직
        if currentMinutes >= (18 * 60) {
            // 오후 6시부터 다음날 1시 30분까지: 다음날 중식
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            return NeisAPIManager.shared.getCachedMeal(date: nextDay, mealType: .lunch)
        } else if currentMinutes >= (13 * 60 + 30) && currentMinutes < (18 * 60) {
            // 1시 30분부터 오후 6시까지: 석식
            if let dinnerInfo = NeisAPIManager.shared.getCachedMeal(date: date, mealType: .dinner) {
                return dinnerInfo
            } else {
                // 석식이 없으면 당일 중식 표시
                return NeisAPIManager.shared.getCachedMeal(date: date, mealType: .lunch)
            }
        } else {
            // 기본적으로 당일 중식
            return NeisAPIManager.shared.getCachedMeal(date: date, mealType: .lunch)
        }
    }
    
    private func getNextRefreshTime(from date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        // 시간 전환 시점에 맞춰 갱신
        if currentMinutes < (13 * 60 + 30) {
            // 1시 30분에 갱신
            return calendar.date(bySettingHour: 13, minute: 30, second: 0, of: date) ?? date
        } else if currentMinutes < (18 * 60) {
            // 오후 6시에 갱신
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) ?? date
        } else {
            // 다음날 1시 30분에 갱신
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: date) {
                return calendar.date(bySettingHour: 13, minute: 30, second: 0, of: nextDay) ?? date
            }
        }
        
        // 기본적으로 30분 후 갱신
        return calendar.date(byAdding: .minute, value: 30, to: date) ?? date
    }
}

struct MealWidgetEntry: TimelineEntry {
    let date: Date
    let mealInfo: MealInfo?
    let isLoading: Bool
    let grade: Int
    let classNumber: Int
}

struct MealWidgetEntryView: View {
    var entry: MealWidgetEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallMealWidgetView(entry: entry)
        case .systemMedium:
            MediumMealWidgetView(entry: entry)
        default:
            Text("지원되지 않는 위젯 크기")
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallMealWidgetView: View {
    let entry: MealWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text(getMealTimeText())
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Content
            if let mealInfo = entry.mealInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mealInfo.mealType.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    let menuItems = getMenuItems(mealInfo.menuText)
                    if !menuItems.isEmpty {
                        Text(menuItems.first ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if menuItems.count > 1 {
                            Text("외 \(menuItems.count - 1)개")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(mealInfo.calInfo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "questionmark.diamond")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    Text("급식 정보 없음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    private func getMealTimeText() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        let minute = calendar.component(.minute, from: entry.date)
        let currentMinutes = hour * 60 + minute
        
        if currentMinutes >= (18 * 60){
            return "내일"
        } else if currentMinutes >= (13 * 60 + 30) && currentMinutes < (18 * 60) {
            return "오늘"
        } else {
            return "오늘"
        }
    }
}

// MARK: - Medium Widget (4x2)
struct MediumMealWidgetView: View {
    let entry: MealWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                    .font(.headline)
                
                Text("\(getMealTimeText()) \(entry.mealInfo?.mealType.name ?? "급식")")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let mealInfo = entry.mealInfo {
                    Text(mealInfo.calInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Menu content
            if let mealInfo = entry.mealInfo {
                let menuItems = getMenuItems(mealInfo.menuText)
                LazyVGrid(columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading)
                ], spacing: 4) {
                    ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                        if index < 10 {
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
                
                if menuItems.count > 10 {
                    Text("외 \(menuItems.count - 10)개...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "questionmark.diamond")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("급식 정보가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    private func getMealTimeText() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        let minute = calendar.component(.minute, from: entry.date)
        let currentMinutes = hour * 60 + minute
        
        if currentMinutes >= (18 * 60) {
            return "내일"
        } else if currentMinutes >= (13 * 60 + 30) && currentMinutes < (18 * 60) {
            return "오늘"
        } else {
            return "오늘"
        }
    }
}

// MARK: - Large Widget (4x4)


// MARK: - Helper Functions
private func getMenuItems(_ text: String) -> [String] {
    return text.split(separator: "\n")
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M월 d일 (E)"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter.string(from: date)
}
