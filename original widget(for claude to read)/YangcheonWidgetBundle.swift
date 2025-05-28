import WidgetKit
import SwiftUI

@main
struct YangcheonWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        // Basic widgets
        YclifeWidget()
        MealWidget()
        DailyScheduleWidget()
        
        // iOS 16+ lock screen widgets
        LockScreenClassWidget()
        
    }
}
