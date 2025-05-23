//
//  AppIntent.swift
//  WhereNowWidget
//
//  Created by Jon on 7/31/24.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    var uuid = UUID()
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is a widget about locations." }

    // An example configurable parameter.
    @Parameter(title: "Location: current or zip code", default: "Current Location")
    var locationIntent: String?
}
