//
//  ResiWashWidgetBundle.swift
//  ResiWashWidget
//
//  Created by proglab on 5/3/26.
//

import WidgetKit
import SwiftUI

@main
struct ResiWashWidgetBundle: WidgetBundle {
    var body: some Widget {
        ResiWashWidget()
        // ResiWashWidgetControl()
        ResiWashWidgetLiveActivity()
    }
}
