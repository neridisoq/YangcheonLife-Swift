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
        // 기본 위젯만 등록 (iOS 15 호환성을 위해)
        YclifeWidget()
        
        // iOS 16 이상에서만 잠금화면 위젯 추가
        if #available(iOS 16.0, *) {
            LockScreenClassWidget()
        }
    }
}
