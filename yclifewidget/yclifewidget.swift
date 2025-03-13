import WidgetKit
import SwiftUI

@main
struct YclifeWidget: Widget {
    let kind: String = "yclifewidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NextClassWidgetView(entry: entry)
        }
        .configurationDisplayName("다음 수업")
        .description("다음 수업 시간과 장소를 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
