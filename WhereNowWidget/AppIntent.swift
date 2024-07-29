//
//  AppIntent.swift
//  WhereNowWidget
//
//  Created by Jon on 7/19/24.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Where Now!" }
    static var description: IntentDescription { "This widget is intended to display information about the user's current location." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
    
    @Parameter(title: "Location", default: "Planet Earth, Milky Way Galaxy")
    var location: String
}
