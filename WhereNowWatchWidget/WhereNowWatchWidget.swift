
//
//  WhereNowWatchWidget.swift
//  WhereNowWatchWidget
//
//  Created by Jon on 7/31/24.
//

import WidgetKit
import SwiftUI
import CoreLocation
import AppIntents

private enum TextWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Text Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to show weather, street name, and town name metadata of a location."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.accessoryRectangular, .accessoryInline]
}

private enum LocationOnlyTextWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Location only text Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to show metadata of a location."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.accessoryInline]
}

struct Provider: AppIntentTimelineProvider {
    
    typealias Entry = LocationInformationEntry
    typealias Intent = ConfigurationAppIntent
    
    func placeholder(in context: Context) -> LocationInformationEntry {
        LocationInformationEntry(date: .now, state: .placeholder)
    }
    
    // MARK: - Config

    private enum Config {
        /// Update widget after one minute to always show an up to date user location.
        static let refreshTimeInterval: TimeInterval = 60
    }

    // MARK: - Dependencies

    private let locationManager: LocationManager = LocationManager(locationStorageManager: UserDefaults.standard)
    private let weatherManager: USAWeatherService = USAWeatherService()
   
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> LocationInformationEntry {
        var location: CLLocation
        if let locationIntent = configuration.locationIntent {
            let placemark = await locationManager.locationFrom(postalCode: locationIntent)
            let userRequestedLocation = placemark?.location
            location = userRequestedLocation ?? locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
        } else {
            location = locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
        }
        let addresses = await location.getAddresses()
        var weather = await weatherManager.getForecasts(using: location.coordinate)
        if weather.count > 0 {
            for (index, forecastInfo) in weather.enumerated() {
                UserDefaults.standard.set(weather: forecastInfo, forKey: "\(location.coordinate) \(index)")
            }
        } else {
            for i in 1...15 {
                if let forecastInfo =  UserDefaults.standard.weather(forKey: "\(location.coordinate) \(i)") {
                    weather[i] = forecastInfo
                }
            }
        }
        let entry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses, weather: weather)))
        return entry
    }
        
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<LocationInformationEntry> {
        var location: CLLocation
        if let locationIntent = configuration.locationIntent {
            let placemark = await locationManager.locationFrom(postalCode: locationIntent)
            let userRequestedLocation = placemark?.location
            location = userRequestedLocation ?? locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
        } else {
            location = locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
        }
        let addresses = await location.getAddresses()
        var weather = await weatherManager.getForecasts(using: location.coordinate)
        if weather.count > 0 {
            for (index, forecastInfo) in weather.enumerated() {
                UserDefaults.standard.set(weather: forecastInfo, forKey: "\(location.coordinate) \(index)")
            }
        } else {
            for i in 1...15 {
                if let forecastInfo =  UserDefaults.standard.weather(forKey: "\(location.coordinate) \(i)") {
                    weather[i] = forecastInfo
                }
            }
        }
        let entries = [LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses, weather: weather)))]
        return Timeline(entries: entries, policy: .after(.now + 60*10))
    }
    
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Create an array with all the preconfigured widgets to show.
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Location Widget")]
    }
    /*func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
       return [WidgetRelevanceEntry(configuration: ConfigurationAppIntent(), context: Rel)]
    }*/
}

struct WhereNowTextWidgetView : View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    var entry: Provider.Entry
    let titleFontSize: CGFloat = 8
    let fontSize: CGFloat = 8
    let emojiFontSize: CGFloat = 9
    let emojiLine: Bool
    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            VStack(alignment: .center) {
                Text(entry.mediumLocationDescription + (![.accented].contains(self.widgetRenderingMode) ? " " + entry.flagDescription : ""))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .font(.system(size: titleFontSize))
                Text(entry.weatherDescription + (emojiLine ? "" : " " + (Fun.emojis.randomElement() ?? "")))
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .font(.system(size: fontSize))
                if ![.accented].contains(self.widgetRenderingMode) && emojiLine {
                    Text(Fun.emojis.randomElement() ?? "")
                        .multilineTextAlignment(.center)
                        .font(.system(size: emojiFontSize))
                }
            }
            .frame(maxHeight: .infinity)
            Spacer()
        case .accessoryCorner, .accessoryCircular, .accessoryInline:
            Text(entry.shortDescription + (emojiLine ? "" : " " + (Fun.emojis.randomElement() ?? "")))
        @unknown default:
            Text(entry.shortDescription)
        }
        
    }
}


/*struct WhereNowWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhereNowTextWidget()
        WhereNowLocationTextOnlyWidget()
    }
}*/
@main
struct WhereNowTextWidget: Widget {
    
    let kind: String = WidgetKinds.WhereNowTextWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowTextWidgetView(entry: entry, emojiLine: true)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(TextWidgetConfig.displayName)
        .description(TextWidgetConfig.description)
        .supportedFamilies(TextWidgetConfig.supportedFamilies)
    }
}

struct WhereNowLocationTextOnlyWidget: Widget {
    
    let kind: String = WidgetKinds.WhereNowTextWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowTextWidgetView(entry: entry, emojiLine: false)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(LocationOnlyTextWidgetConfig.displayName)
        .description(LocationOnlyTextWidgetConfig.description)
        .supportedFamilies(LocationOnlyTextWidgetConfig.supportedFamilies)
    }
}

extension ConfigurationAppIntent {
    fileprivate static var SpartaNJ: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.locationIntent = "07871"
        return intent
    }
    
    fileprivate static var CurrentLocation: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.locationIntent = "Current Location"
        return intent
    }
}

/*#Preview(as: .systemSmall) {
    WhereNowTextWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .SpartaNJ)
}*/

/*#if DEBUG
    struct WhereNowTextWidgetView_Previews: PreviewProvider {
        static var previews: some View {
            let appleParkLocation = CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792)
            let info = LocationInformation(userLocation: appleParkLocation,
                                           image: Image("MapApplePark"), weather: [ForecastInfo(forecast: "There will be snow. There will be rain. There WILL be Apple's. - Jony Applyseed")])

            let informationEntry = LocationInformationEntry(date: Date(),
                                                    state: .success(info))

            return Group {
                WhereNowTextWidgetView(entry: informationEntry, emojiLine: true)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            }
        }
    }
#endif*/
