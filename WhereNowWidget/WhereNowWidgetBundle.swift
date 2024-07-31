//
//  WhereNowWidgetBundle.swift
//  WhereNowWidget
//
//  Created by Jon on 7/31/24.
//

import WidgetKit
import SwiftUI

@main
struct WhereNowWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhereNowTextWidget()
        WhereNowMapWidget()
    }
}
