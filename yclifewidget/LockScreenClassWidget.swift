import WidgetKit
import SwiftUI

struct LockScreenClassWidget: Widget {
    let kind: String = "LockScreenClassWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenClassWidgetView(entry: entry)
        }
        .configurationDisplayName("다음 수업")
        .description("다음 수업 정보를 잠금화면에 표시합니다.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
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
        default:
            Text("지원되지 않는 위젯")
        }
    }
    
    @ViewBuilder
    private func circularWidgetView(entry: Provider.Entry) -> some View {
        switch entry.displayMode {
        case .nextClass(let nextClass):
            // 1x1 원형 위젯 (다음 교시 표시)
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(nextClass.periodIndex + 1)")
                        .font(.system(size: 22, weight: .bold))
                    Text("교시")
                        .font(.system(size: 10))
                        .padding(.top, -5)
                }
            }
        case .peInfo(_, let hasPhysicalEducation):
            // 1x1 원형 위젯 (체육 정보)
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                    .font(.system(size: 26))
            }
        default:
            // 1x1 원형 위젯 (정보 없음)
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "calendar")
                    .font(.system(size: 26))
            }
        }
    }
    
    @ViewBuilder
    private func rectangularWidgetView(entry: Provider.Entry) -> some View {
        switch entry.displayMode {
        case .nextClass(let nextClass):
            // 2x1 직사각형 위젯 (다음 교시 + 과목명)
            ZStack {
                AccessoryWidgetBackground()
                HStack {
                    VStack(alignment: .leading) {
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
            }
        case .peInfo(let weekday, let hasPhysicalEducation):
            // 2x1 직사각형 위젯 (체육 정보)
            ZStack {
                AccessoryWidgetBackground()
                HStack {
                    Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                        .font(.system(size: 16))
                    Text("\(weekdayString(weekday)) 체육 \(hasPhysicalEducation ? "있음" : "없음")")
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
            }
        default:
            // 2x1 직사각형 위젯 (정보 없음)
            ZStack {
                AccessoryWidgetBackground()
                Text("수업 정보 없음")
                    .font(.system(size: 12))
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
}

// YclifeWidget.swift 파일에 이 위젯을 추가하는 방법 (기존 WidgetBundle에 추가)
// @main
// struct YangcheonWidgetBundle: WidgetBundle {
//     @WidgetBundleBuilder
//     var body: some Widget {
//         YclifeWidget()
//         LockScreenClassWidget()
//     }
// }