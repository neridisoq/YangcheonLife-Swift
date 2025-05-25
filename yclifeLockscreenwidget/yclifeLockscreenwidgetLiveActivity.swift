//
//  yclifeLockscreenwidgetLiveActivity.swift
//  yclifeLockscreenwidget
//
//  Created by neridisoq on 5/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct yclifeLockscreenwidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct yclifeLockscreenwidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: yclifeLockscreenwidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension yclifeLockscreenwidgetAttributes {
    fileprivate static var preview: yclifeLockscreenwidgetAttributes {
        yclifeLockscreenwidgetAttributes(name: "World")
    }
}

extension yclifeLockscreenwidgetAttributes.ContentState {
    fileprivate static var smiley: yclifeLockscreenwidgetAttributes.ContentState {
        yclifeLockscreenwidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: yclifeLockscreenwidgetAttributes.ContentState {
         yclifeLockscreenwidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: yclifeLockscreenwidgetAttributes.preview) {
   yclifeLockscreenwidgetLiveActivity()
} contentStates: {
    yclifeLockscreenwidgetAttributes.ContentState.smiley
    yclifeLockscreenwidgetAttributes.ContentState.starEyes
}
