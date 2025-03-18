import WidgetKit
import SwiftUI

struct MealWidget: Widget {
    let kind: String = "MealWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MealProvider()) { entry in
            if #available(iOS 17.0, *) {
                MealWidgetView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                MealWidgetView(entry: entry)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
            }
        }
        .configurationDisplayName("급식 정보")
        .description("오늘의 급식 메뉴를 확인합니다.")
        .supportedFamilies([.systemMedium]) // 4x2 size (medium)
    }
}

struct MealProvider: TimelineProvider {
    func placeholder(in context: Context) -> MealEntry {
        return MealEntry(date: Date(), mealInfo: nil, useNextDay: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MealEntry) -> Void) {
        // Create a sample meal for preview
        let sampleMeal = MealInfo(
            mealType: .lunch,
            menuText: "쇠고기미역국\n차조밥\n닭갈비\n김치\n과일",
            calInfo: "650 Kcal"
        )
        
        let entry = MealEntry(date: Date(), mealInfo: sampleMeal, useNextDay: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MealEntry>) -> Void) {
        let currentDate = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        
        // Determine which meal type to display based on time of day
        var mealType: MealType = .lunch
        var targetDate = currentDate
        var useNextDay = false
        
        if hour >= 18 {
            // After 6 PM, show next day's lunch
            mealType = .lunch
            targetDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            useNextDay = true
        } else if hour >= 13 {
            // After 1 PM, show dinner
            mealType = .dinner
        }
        
        // 오늘 혹은 다음날 급식 가져오기
        fetchMealInfo(date: targetDate, mealType: mealType, currentDate: currentDate, useNextDay: useNextDay, completion: completion)
    }
    
    // 급식 정보 가져오기 함수 분리
    private func fetchMealInfo(date targetDate: Date, mealType: MealType, currentDate: Date, useNextDay: Bool, completion: @escaping (Timeline<MealEntry>) -> Void) {
        // 캐시에서 먼저 확인
        if let cachedMeal = NeisAPIManager.shared.getCachedMeal(date: targetDate, mealType: mealType) {
            let entry = MealEntry(date: currentDate, mealInfo: cachedMeal, useNextDay: useNextDay)
            let refreshDate = Calendar.current.date(byAdding: .hour, value: 3, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
            return
        }
        
        // 급식 정보 가져오기
        NeisAPIManager.shared.fetchMeal(date: targetDate, mealType: mealType) { mealInfo in
            if let mealInfo = mealInfo {
                // 급식 정보가 있으면 캐시하고 표시
                NeisAPIManager.shared.cacheMeal(date: targetDate, mealInfo: mealInfo)
                let entry = MealEntry(date: currentDate, mealInfo: mealInfo, useNextDay: useNextDay)
                let refreshDate = Calendar.current.date(byAdding: .hour, value: 3, to: currentDate)!
                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                completion(timeline)
            } else if !useNextDay && mealType == .dinner {
                // 석식 정보가 없으면 내일 중식 정보 시도
                let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
                self.fetchMealInfo(date: nextDay, mealType: .lunch, currentDate: currentDate, useNextDay: true, completion: completion)
            } else if useNextDay && mealType == .lunch {
                // 내일 중식 정보도 없으면 내일 조식 시도
                self.fetchMealInfo(date: targetDate, mealType: .breakfast, currentDate: currentDate, useNextDay: true, completion: completion)
            } else {
                // 모든 급식 정보가 없는 경우
                let entry = MealEntry(date: currentDate, mealInfo: nil, useNextDay: useNextDay)
                let refreshDate = Calendar.current.date(byAdding: .hour, value: 3, to: currentDate)!
                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                completion(timeline)
            }
        }
    }
}

struct MealEntry: TimelineEntry {
    let date: Date
    let mealInfo: MealInfo?
    let useNextDay: Bool
    
    init(date: Date, mealInfo: MealInfo?, useNextDay: Bool = false) {
        self.date = date
        self.mealInfo = mealInfo
        self.useNextDay = useNextDay
    }
}

struct MealWidgetView: View {
    var entry: MealEntry
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
            
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.orange)
                    
                    // 실제 표시되는 날짜 계산 (다음 날 정보인 경우 내일 날짜)
                    let targetDate = entry.useNextDay ?
                                    Calendar.current.date(byAdding: .day, value: 1, to: entry.date)! :
                                    entry.date
                    
                    // 식사 종류
                    let mealTypeText = getMealTypeText(entry.mealInfo?.mealType)
                    
                    // 날짜 포맷팅
                    Text("\(formatDate(targetDate)) \(mealTypeText)\(entry.useNextDay ? " (내일)" : "")")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    if let mealInfo = entry.mealInfo {
                        Text(mealInfo.calInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 2)
                
                if let mealInfo = entry.mealInfo {
                    // Menu grid
                    let menuItems = getMenuItems(mealInfo.menuText)
                    
                    // Display in a grid layout
                    VStack(spacing: 4) {
                        if menuItems.count > 0 {
                            HStack {
                                if menuItems.count > 0 {
                                    menuItemView(menuItems[0])
                                }
                                if menuItems.count > 1 {
                                    menuItemView(menuItems[1])
                                }
                            }
                        }
                        
                        if menuItems.count > 2 {
                            HStack {
                                if menuItems.count > 2 {
                                    menuItemView(menuItems[2])
                                }
                                if menuItems.count > 3 {
                                    menuItemView(menuItems[3])
                                }
                            }
                        }
                        
                        if menuItems.count > 4 {
                            HStack {
                                if menuItems.count > 4 {
                                    menuItemView(menuItems[4])
                                }
                                if menuItems.count > 5 {
                                    menuItemView(menuItems[5])
                                }
                            }
                        }
                        
                        if menuItems.count > 6 {
                            HStack {
                                if menuItems.count > 6 {
                                    menuItemView(menuItems[6])
                                }
                                if menuItems.count > 7 {
                                    menuItemView(menuItems[7])
                                }
                            }
                        }
                        
                        if menuItems.count > 8 {
                            Text("외 \(menuItems.count - 8)개...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                } else {
                    Spacer()
                    Text("급식 정보가 없습니다")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func menuItemView(_ item: String) -> some View {
        HStack {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.orange)
            Text(item)
                .font(.system(size: 13))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func getMealTypeText(_ mealType: MealType?) -> String {
        guard let mealType = mealType else { return "급식" }
        
        switch mealType {
        case .breakfast:
            return "조식"
        case .lunch:
            return "중식"
        case .dinner:
            return "석식"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func getMenuItems(_ text: String) -> [String] {
        return text.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
