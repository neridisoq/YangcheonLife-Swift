import WidgetKit
import SwiftUI

struct LockScreenClassWidget: Widget {
    let kind: String = "LockScreenClassWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenClassWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else if #available(iOS 16.0, *) {
                LockScreenClassWidgetView(entry: entry)
                    .widgetAccentable()
            } else {
                // iOS 15 이하 버전에 대한 처리
                LockScreenClassWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("다음 수업")
        .description("다음 수업 정보를 잠금화면에 표시합니다.")
        // iOS 15에서는 잠금화면 위젯 패밀리를 지원하지 않으므로 조건부로 적용
        .supportedFamilies(getSupportedFamilies())
    }
    
    // iOS 버전에 따라 지원되는 위젯 패밀리 반환
    private func getSupportedFamilies() -> [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        } else {
            // iOS 15 이하에서는 홈 화면 위젯만 지원
            return [.systemSmall, .systemMedium]
        }
    }
}

struct LockScreenClassWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            circularWidgetView(entry: entry)
        case .accessoryRectangular:
            rectangularWidgetView(entry: entry)
        case .accessoryInline:
            inlineWidgetView(entry: entry)
        default:
            Text("지원되지 않는 위젯")
        }
    }
    
    @ViewBuilder
    private func circularWidgetView(entry: Provider.Entry) -> some View {
        // 급식 시간일 때도 다음 수업 정보 표시
        if case .mealInfo = entry.displayMode, let nextClass = WidgetScheduleManager.shared.getNextClass() {
            // 1x1 원형 위젯에 과목명 표시 (급식 시간)
            VStack {
                Text(getShortSubjectName(nextClass.subject))
                    .font(.system(size: 14, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        } else {
            switch entry.displayMode {
            case .nextClass(let nextClass):
                // 1x1 원형 위젯에 과목명 표시
                VStack {
                    Text(getShortSubjectName(nextClass.subject))
                        .font(.system(size: 14, weight: .bold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            
            case .peInfo(_, let hasPhysicalEducation):
                // 1x1 원형 위젯 (체육 정보)
                Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                    .font(.system(size: 26))
            
            default:
                // 1x1 원형 위젯 (정보 없음)
                Image(systemName: "calendar")
                    .font(.system(size: 26))
            }
        }
    }
    
    @ViewBuilder
    private func rectangularWidgetView(entry: Provider.Entry) -> some View {
        // 급식 시간일 때도 다음 수업 정보 표시
        if case .mealInfo = entry.displayMode, let nextClass = WidgetScheduleManager.shared.getNextClass() {
            // 급식 시간이지만 다음 수업 정보 우선 표시
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("다음교시 \(nextClass.periodIndex + 1)교시")
                        .font(.system(size: 12))
                    Text(nextClass.subject)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                    Text(nextClass.teacher)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.leading, 4)
        } else {
            switch entry.displayMode {
            case .nextClass(let nextClass):
                // 2x1 직사각형 위젯 (다음 교시 + 과목명)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("다음교시 \(nextClass.periodIndex + 1)교시")
                            .font(.system(size: 12))
                        Text(nextClass.subject)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                        Text(nextClass.teacher)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.leading, 4)
            
            case .peInfo(let weekday, let hasPhysicalEducation):
                // 2x1 직사각형 위젯 (체육 정보)
                HStack {
                    Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                        .font(.system(size: 16))
                    Text("\(weekdayString(weekday)) 체육 \(hasPhysicalEducation ? "있음" : "없음")")
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
            
            default:
                // 2x1 직사각형 위젯 (정보 없음)
                Text("수업 정보 없음")
                    .font(.system(size: 12))
            }
        }
    }
    
    @ViewBuilder
    private func inlineWidgetView(entry: Provider.Entry) -> some View {
        // 급식 시간일 때도 다음 수업 정보 표시
        if case .mealInfo = entry.displayMode, let nextClass = WidgetScheduleManager.shared.getNextClass() {
            // 급식 시간이지만 다음 수업 정보 우선 표시
            ViewThatFits {
                Text("\(nextClass.periodIndex + 1)교시 \(nextClass.subject)")
                Text("\(nextClass.subject)")
            }
        } else {
            switch entry.displayMode {
            case .nextClass(let nextClass):
                // inline 위젯은 공간에 맞춰 조절
                ViewThatFits {
                    Text("\(nextClass.periodIndex + 1)교시 \(nextClass.subject)")
                    Text("\(nextClass.subject)")
                }
                
            case .peInfo(let weekday, let hasPhysicalEducation):
                // 체육 정보
                Text("\(weekdayString(weekday)) 체육 \(hasPhysicalEducation ? "있음" : "없음")")
                
            default:
                // 정보 없음
                Text("수업 정보 없음")
            }
        }
    }
    
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
    
    /// 과목명이 너무 길 경우 짧게 줄여주는 함수
    private func getShortSubjectName(_ subject: String) -> String {
        // 특정 과목명에 대한 약어 처리
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
        
        // 약어가 있는 경우 반환
        for (key, abbr) in abbreviations {
            if subject.contains(key) {
                return abbr
            }
        }
        
        // 약어가 없는 경우 과목명 그대로 반환
        return subject
    }
}
