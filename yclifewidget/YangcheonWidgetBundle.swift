//
//  YangcheonWidgetBundle.swift
//  yangcheonlife
//
//  Created by Woohyun Jin on 3/13/25.
//


import WidgetKit
import SwiftUI

@main
struct YangcheonWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        // 기존 위젯
        YclifeWidget()
        
        // 새로운 위젯
        LockScreenClassWidget()
    }
}
