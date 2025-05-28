import WidgetKit
import SwiftUI

struct YclifeWidget: Widget {
    let kind: String = "yclifewidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            // iOS 버전에 따른 조건부 내용 표시
            if #available(iOS 17.0, *) {
                NextClassWidgetView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                NextClassWidgetView(entry: entry)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
            }
        }
        .configurationDisplayName("다음 수업")
        .description("다음 수업 시간과 장소를 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
