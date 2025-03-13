import WidgetKit
import SwiftUI

struct SimpleNextClassEntry: TimelineEntry {
    let date: Date
    let nextClass: ClassInfo?
    let peInfo: (weekday: Int, hasPhysicalEducation: Bool)?
    let grade: Int
    let classNumber: Int
}

struct SimpleNextClassProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleNextClassEntry {
        return SimpleNextClassEntry(
            date: Date(),
            nextClass: nil,
            peInfo: nil,
            grade: 3,
            classNumber: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleNextClassEntry) -> ()) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        // Try to get next class
        let nextClass = WidgetScheduleManager.shared.getNextClass()
        
        // Try to get PE info
        var peInfo: (weekday: Int, hasPhysicalEducation: Bool)? = nil
        let displayMode = WidgetScheduleManager.shared.getDisplayInfo()
        if case let .peInfo(weekday, hasPhysicalEducation) = displayMode {
            peInfo = (weekday: weekday, hasPhysicalEducation: hasPhysicalEducation)
        }
        
        let entry = SimpleNextClassEntry(
            date: Date(),
            nextClass: nextClass,
            peInfo: peInfo,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleNextClassEntry>) -> ()) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        // Try to get next class
        let nextClass = WidgetScheduleManager.shared.getNextClass()
        
        // Try to get PE info
        var peInfo: (weekday: Int, hasPhysicalEducation: Bool)? = nil
        let displayMode = WidgetScheduleManager.shared.getDisplayInfo()
        if case let .peInfo(weekday, hasPhysicalEducation) = displayMode {
            peInfo = (weekday: weekday, hasPhysicalEducation: hasPhysicalEducation)
        }
        
        let entry = SimpleNextClassEntry(
            date: Date(),
            nextClass: nextClass,
            peInfo: peInfo,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        // Refresh every few minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
}

struct SimpleNextClassWidgetEntryView: View {
    var entry: SimpleNextClassProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        if let nextClass = entry.nextClass {
            // Show next class info
            VStack(alignment: .leading, spacing: widgetFamily == .systemSmall ? 2 : 4) {
                Text("다음교시 \(nextClass.periodIndex + 1)교시")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(nextClass.subject)
                    .font(widgetFamily == .systemSmall ? .headline : .title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                if widgetFamily != .systemSmall {
                    Spacer(minLength: 2)
                }
                
                Text(nextClass.teacher)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                if widgetFamily != .systemSmall {
                    Text("\(formatTime(nextClass.startTime)) ~ \(formatTime(nextClass.endTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetBackground()
        } else if let peInfo = entry.peInfo {
            // Show PE info
            VStack(spacing: widgetFamily == .systemSmall ? 4 : 6) {
                if widgetFamily != .systemSmall {
                    Spacer(minLength: 0)
                }
                
                Image(systemName: peInfo.hasPhysicalEducation ? "figure.run" : "figure.walk")
                    .font(.system(size: widgetFamily == .systemSmall ? 20 : 30))
                    .foregroundColor(peInfo.hasPhysicalEducation ? .blue : .gray)
                
                Text("\(weekdayString(peInfo.weekday)) 체육 \(peInfo.hasPhysicalEducation ? "있음" : "없음")")
                    .font(widgetFamily == .systemSmall ? .caption : .headline)
                    .foregroundColor(peInfo.hasPhysicalEducation ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(widgetFamily == .systemSmall ? 2 : 1)
                
                if widgetFamily != .systemSmall && peInfo.hasPhysicalEducation {
                    Text("운동복을 준비하세요!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if widgetFamily != .systemSmall {
                    Spacer(minLength: 0)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetBackground()
        } else {
            // No info
            VStack(spacing: 4) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: widgetFamily == .systemSmall ? 20 : 30))
                    .foregroundColor(.gray)
                
                Text("수업 정보 없음")
                    .font(widgetFamily == .systemSmall ? .caption : .headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetBackground()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func weekdayString(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "일요일"
        case 2: return "월요일"
        case 3: return "화요일" 
        case 4: return "수요일"
        case 5: return "목요일"
        case 6: return "금요일"
        case 7: return "토요일"
        default: return "알 수 없음"
        }
    }
}

// Widget background modifier
extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(.background, for: .widget)
        } else {
            return background(Color(UIColor.systemBackground))
        }
    }
}

struct SimpleNextClassWidget: Widget {
    let kind: String = "SimpleNextClassWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleNextClassProvider()) { entry in
            SimpleNextClassWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("다음 수업")
        .description("다음 수업 시간과 교실 정보를 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Make this available to be registered in your main WidgetBundle
struct SimpleNextClassWidget_Previews: PreviewProvider {
    static var previews: some View {
        let previewDate = Date()
        let calendar = Calendar.current
        
        // Sample class info
        let startTime = calendar.date(bySettingHour: 10, minute: 20, second: 0, of: previewDate)!
        let endTime = calendar.date(bySettingHour: 11, minute: 10, second: 0, of: previewDate)!
        
        let exampleClass = ClassInfo(
            subject: "수학",
            teacher: "302호",
            periodIndex: 2,
            startTime: startTime,
            endTime: endTime
        )
        
        Group {
            // 1x1 Widget Previews
            SimpleNextClassWidgetEntryView(entry: SimpleNextClassEntry(
                date: previewDate,
                nextClass: exampleClass,
                peInfo: nil,
                grade: 3,
                classNumber: 5
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("다음 수업 (1x1)")
            
            SimpleNextClassWidgetEntryView(entry: SimpleNextClassEntry(
                date: previewDate,
                nextClass: nil,
                peInfo: (weekday: 2, hasPhysicalEducation: true),
                grade: 3,
                classNumber: 5
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("체육 있음 (1x1)")
            
            // 2x1 Widget Previews
            SimpleNextClassWidgetEntryView(entry: SimpleNextClassEntry(
                date: previewDate,
                nextClass: exampleClass,
                peInfo: nil,
                grade: 3, 
                classNumber: 5
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("다음 수업 (2x1)")
            
            SimpleNextClassWidgetEntryView(entry: SimpleNextClassEntry(
                date: previewDate,
                nextClass: nil,
                peInfo: (weekday: 3, hasPhysicalEducation: false),
                grade: 3,
                classNumber: 5
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("체육 없음 (2x1)")
        }
    }
}