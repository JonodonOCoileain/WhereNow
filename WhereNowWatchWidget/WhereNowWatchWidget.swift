
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

private enum BirdSightingsWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Bird Sightings Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to metadata of bird sightings."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.accessoryRectangular]
}

private enum NotableBirdSightingsWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Notable Bird Sightings Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to metadata of notable bird sightings."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.accessoryRectangular]
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
    private let birdSightingService: BirdSightingService = BirdSightingService()
   
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
        let birdData = await birdSightingService.getSightings(using: location.coordinate)
        let notables = await birdSightingService.getNotableSightings(using: location.coordinate)
        let entry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses, weather: weather, birdSightings: birdData, notableBirdSightings: notables)))
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
        let birdData = await birdSightingService.getSightings(using: location.coordinate)
        let notables = await birdSightingService.getNotableSightings(using: location.coordinate)
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
        let entries = [LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses, weather: weather, birdSightings: birdData, notableBirdSightings: notables)))]
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
        case .accessoryInline:
            Text(entry.shortDescription + (emojiLine ? "" : " " + (Fun.emojis.randomElement() ?? "")))
        case .accessoryCorner, .accessoryCircular:
            Text(entry.birdsDescriptionShorter)
        @unknown default:
            Text(entry.shortDescription)
        }
        
    }
}

struct WhereNowBirdSightingsWidgetView : View {
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
                if ![.accented].contains(self.widgetRenderingMode) && emojiLine {
                    Text(Fun.eBirdjis.randomElement() ?? "")
                        .multilineTextAlignment(.center)
                        .font(.system(size: emojiFontSize))
                }
                Text(entry.birdsDescription)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .font(.system(size: titleFontSize))
            }
            .frame(maxHeight: .infinity)
            Spacer()
        case .accessoryInline:
            Text(entry.birdsDescriptionShorter + (emojiLine ? "" : " " + (Fun.eBirdjis.randomElement() ?? "")))
        case .accessoryCorner, .accessoryCircular:
            Text(entry.birdsDescriptionShorter)
        @unknown default:
            Text(entry.shortDescription)
        }
        
    }
}

struct WhereNowNotableBirdSightingsWidgetView : View {
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
                if ![.accented].contains(self.widgetRenderingMode) && emojiLine {
                    Text(Fun.eBirdjis.randomElement() ?? "")
                        .multilineTextAlignment(.center)
                        .font(.system(size: emojiFontSize))
                }
                Text(entry.notableBirdsDescription)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .font(.system(size: titleFontSize))
            }
            .frame(maxHeight: .infinity)
            Spacer()
        case .accessoryInline:
            Text(entry.notableBirdsDescriptionShorter + (emojiLine ? "" : " " + (Fun.eBirdjis.randomElement() ?? "")))
        case .accessoryCorner, .accessoryCircular:
            Text(entry.notableBirdsDescriptionShorter)
        @unknown default:
            Text(entry.notableBirdsDescriptionShorter)
        }
        
    }
}

@main
struct WhereNowWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhereNowTextWidget()
        WhereNowLocationTextOnlyWidget()
        WhereNowBirdSightingsWidget()
        WhereNowNotableBirdSightingsWidget()
    }
}

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

struct WhereNowBirdSightingsWidget: Widget {
    
    let kind: String = WidgetKinds.WhereNowBirdSightingsWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowBirdSightingsWidgetView(entry: entry, emojiLine: false)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(BirdSightingsWidgetConfig.displayName)
        .description(BirdSightingsWidgetConfig.description)
        .supportedFamilies(BirdSightingsWidgetConfig.supportedFamilies)
    }
}

struct WhereNowNotableBirdSightingsWidget: Widget {
    
    let kind: String = WidgetKinds.WhereNowNotableBirdSightingsWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowNotableBirdSightingsWidgetView(entry: entry, emojiLine: false)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(NotableBirdSightingsWidgetConfig.displayName)
        .description(NotableBirdSightingsWidgetConfig.description)
        .supportedFamilies(NotableBirdSightingsWidgetConfig.supportedFamilies)
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
