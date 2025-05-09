//
//  WhereNowWidget.swift
//  WhereNowWidget
//
//  Created by Jon on 7/31/24.
//

import WidgetKit
import SwiftUI
import CoreLocation
import AppIntents

private enum MapWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Map Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget showing a map."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
}

private enum MapAndWeatherWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Map and Weather Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget showing a map and reported weather for the same location."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.systemLarge, .systemExtraLarge]
}

private enum LongWeatherWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Long Weather Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget showing reported weather."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.systemLarge, .systemExtraLarge]
}

private enum TextWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Text Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to show metadata of a location."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.accessoryInline, .accessoryCircular, .accessoryRectangular]
}

private enum WeatherTextWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Weather Text Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to show weather data."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.accessoryRectangular]
}

private enum BirdSightingsWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Bird Sightings Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to show bird sighting data reported near the current location."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.systemLarge, .systemExtraLarge, .accessoryRectangular]
}

private enum NotableBirdSightingsWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Notable Bird Sightings Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to show notable bird sighting data reported near the current location."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.systemLarge, .systemExtraLarge, .accessoryRectangular]
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
        #if os(watchOS)
        var location: CLLocation
        if let locationIntent = configuration.locationIntent {
            let placemark = await LocationManager.locationFrom(postalCode: locationIntent)
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
        let entry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses, weather: weather, birdSightings: birdData, notableBirdSightings: notables)))
        return entry
        #else
            print("Not watchOS")
            var location: CLLocation
            if let locationIntent = configuration.locationIntent {
                let placemark = await LocationManager.locationFrom(postalCode: locationIntent)
                let userRequestedLocation = placemark?.location
                location = userRequestedLocation ?? locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
            } else {
                location = locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
            }
            let coordinate = location.coordinate
        
            let snapshots = MapSnapshotManager()
            let snapshotResult = await snapshots.snapshot(of: coordinate)
            let addresses = await location.getAddresses()
            var forecastInfos = await weatherManager.getForecasts(using: coordinate)
            let birdData = await birdSightingService.getSightings(using: location.coordinate)
            let notables = await birdSightingService.getNotableSightings(using: location.coordinate)
        if forecastInfos.count > 0 {
            for (index, forecastInfo) in forecastInfos.enumerated() {
                UserDefaults.standard.set(weather: forecastInfo, forKey: "\(location.coordinate) \(index)")
            }
        } else {
            for i in 1...15 {
                if let forecastInfo =  UserDefaults.standard.weather(forKey: "\(location.coordinate) \(i)") {
                    forecastInfos[i] = forecastInfo
                }
            }
        }
        
        switch snapshotResult {
        case .success(let image):
            return LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: image, addresses: addresses, weather: forecastInfos, birdSightings: birdData, notableBirdSightings: notables)))
        case .failure(_):
            return LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses, weather: forecastInfos, birdSightings: birdData, notableBirdSightings: notables)))
        }
        #endif
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<LocationInformationEntry> {
        #if os(watchOS)
        var location: CLLocation
        if let locationIntent = configuration.locationIntent {
            let placemark = await LocationManager.locationFrom(postalCode: locationIntent)
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
        #else
        if let location = locationManager.immediateLocation() {
            let snapshots = MapSnapshotManager()
            let snapshotResult = await snapshots.snapshot(of: location.coordinate)
            let addresses = await location.getAddresses()
            var forecastInfos = await weatherManager.getForecasts(using: location.coordinate)
            let birdData = await birdSightingService.getSightings(using: location.coordinate)
            let notables = await birdSightingService.getNotableSightings(using: location.coordinate)
            if forecastInfos.count > 0 {
                for (index, forecastInfo) in forecastInfos.enumerated() {
                    UserDefaults.standard.set(weather: forecastInfo, forKey: "\(location.coordinate) \(index)")
                }
            } else {
                for i in 1...15 {
                    if let forecastInfo =  UserDefaults.standard.weather(forKey: "\(location.coordinate) \(i)") {
                        forecastInfos[i] = forecastInfo
                    }
                }
            }
            var locationInformationEntry: LocationInformationEntry
            switch snapshotResult {
            case .success(let image):
                locationInformationEntry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: image, addresses: addresses, weather: forecastInfos, birdSightings: birdData, notableBirdSightings: notables)))
            case .failure(_):
                locationInformationEntry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses, weather: forecastInfos, birdSightings: birdData, notableBirdSightings: notables)))
            }
            
            return Timeline(entries: [locationInformationEntry], policy: .after(.now + 60*19.5))
        } else {
            return Timeline(entries: [], policy: .after(.now + 60*10))
        }
        #endif
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct WhereNowWidgetTextView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            Text(entry.shortDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .accessoryRectangular:
            Text(entry.flagAndFreeformDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .accessoryCircular:
            VStack {
                Text(entry.townStateDescription)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                Text(entry.flagDescription)
                    .font(.caption)
            }
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemSmall:
            Text(entry.flagAndFreeformDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemMedium:
            Text(entry.flagAndFreeformDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemLarge:
            Text(entry.flagAndFreeformDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemExtraLarge:
            Text(entry.flagAndFreeformDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        @unknown default:
            Text(entry.flagAndFreeformDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct WhereNowTextWidget: Widget {
    
    let kind: String = WidgetKinds.WhereNowTextWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowWidgetTextView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(TextWidgetConfig.displayName)
        .description(TextWidgetConfig.description)
        .supportedFamilies(TextWidgetConfig.supportedFamilies)
    }
}

struct WhereNowWidgetWeatherTextView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            switch entry.state {
            case .success(let info):
                Text((Fun.emojis.randomElement() ?? "") + " " + (info.weather?.first?.forecast ?? ""))
                    .containerBackground(.fill.tertiary, for: .widget)
            case .failure(let error):
                Text(error.localizedDescription)
                    .containerBackground(.fill.tertiary, for: .widget)
            case .placeholder:
                Text((Fun.emojis.randomElement() ?? "") + " Weather Now!")
            }
        case .systemSmall,.systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryInline:
            Text((Fun.emojis.randomElement() ?? "") + " Weather Now!")
        @unknown default:
            Text((Fun.emojis.randomElement() ?? "") + " Weather Now!")
        }
    }
}

struct WhereNowWeatherTextWidget: Widget {
    let kind: String = WidgetKinds.WhereNowWeatherTextWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowWidgetWeatherTextView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(WeatherTextWidgetConfig.displayName)
        .description(WeatherTextWidgetConfig.description)
        .supportedFamilies(WeatherTextWidgetConfig.supportedFamilies)
    }
}

struct WhereNowMapWidgetView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    // MARK: - Config

    private enum Config {
        /// The size of the blue dot reflecting the user location.
        static let userLocationDotSize: CGFloat = 20

        /// If a user-location is older then the given time interval we assume it's outdated and therefore
        /// apply another `foregroundColor` to the dot, reflecting the user-location.
        static let validUserLocationTimeInterval: TimeInterval = 5 * 60
    }

    // MARK: - Public properties

    let info: LocationInformation

    // MARK: - Private properties

    var circleFillColor: Color {
        info.userLocation.timestamp > Date(timeIntervalSinceNow: -Config.validUserLocationTimeInterval)
            ? .blue
            : .gray
    }

    // MARK: - Render

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                info.image?
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 80, maxWidth: 370, maxHeight: .infinity)
                
                // The map is centered on the user location, therefore we can simply draw the blue dot in the
                // center of our view to simulate the user coordinate.
                Circle()
                    .foregroundColor(circleFillColor)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .frame(width: Config.userLocationDotSize,
                           height: Config.userLocationDotSize)
            }
            .frame(minWidth: 80, maxWidth: 370, maxHeight: .infinity)
            .overlay(alignment: .center, content: {
                Text("\n\n\n\n"+(info.addresses?.first?.formattedCommonVeryLongFlag() ?? "Planet Earth, Milky Way"))
                        .multilineTextAlignment(.center)
                        .lineLimit(20)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0, blue: 0.7))
                        .bold()
                        .opacity(widgetFamily != .systemMedium ? 1 : 0)
            })
            
            if widgetFamily == .systemMedium {
                Text(info.addresses?.first?.formattedCommonVeryLongFlag() ?? "Planet Earth, Milky Way")
                    .multilineTextAlignment(.center)
                    .lineLimit(100)
                    .font(.caption)
                    .frame(minWidth: 80, maxWidth: 185, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .padding(-16)
    }
}

struct WhereNowMapAndWeatherWidgetView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    // MARK: - Config

    private enum Config {
        /// The size of the blue dot reflecting the user location.
        static let userLocationDotSize: CGFloat = 20

        /// If a user-location is older then the given time interval we assume it's outdated and therefore
        /// apply another `foregroundColor` to the dot, reflecting the user-location.
        static let validUserLocationTimeInterval: TimeInterval = 5 * 60
    }

    // MARK: - Public properties

    let info: LocationInformation

    // MARK: - Private properties

    var circleFillColor: Color {
        info.userLocation.timestamp > Date(timeIntervalSinceNow: -Config.validUserLocationTimeInterval)
            ? .blue
            : .gray
    }

    // MARK: - Render

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ZStack {
                        info.image?
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width / 2, height: geometry.size.width / 2)
                            .cornerRadius(10)
                            .clipped()
                        
                        // The map is centered on the user location, therefore we can simply draw the blue dot in the
                        // center of our view to simulate the user coordinate.
                        Circle()
                            .foregroundColor(circleFillColor)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .frame(width: Config.userLocationDotSize,
                                   height: Config.userLocationDotSize)
                    }
                    .frame(width: geometry.size.width / 2, height: geometry.size.width / 2)
                    .ignoresSafeArea()
                    
                    if [WidgetFamily.systemLarge, WidgetFamily.systemExtraLarge].contains(widgetFamily) {
                        Text(info.addresses?.first?.formattedCommonVeryLongFlag() ?? "Planet Earth, Milky Way")
                            .multilineTextAlignment(.center)
                            .lineLimit(100)
                            .font(.caption)
                            .frame(minWidth: 80, maxWidth: 185, maxHeight: .infinity)
                            .ignoresSafeArea()
                    }
                }
        
                if let weather = info.weather, let first = weather.first {
                    Text(("\(Fun.emojis.randomElement() ?? "") ") + (first.name ?? ""))
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                        .bold()
                    Text(first.forecast)
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                    Text(("\(Fun.emojis.randomElement() ?? "") ") + (weather[1].name ?? ""))
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                        .bold()
                    Text(weather[1].forecast)
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                }
                Spacer()
            }
            .ignoresSafeArea()
            .frame(width: geometry.size.width,
                                   height: geometry.size.height,
                                   alignment: .topLeading)
        }.ignoresSafeArea()
    }
}

struct WhereNowLongWeatherWidgetView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    // MARK: - Config

    private enum Config {
        /// The size of the blue dot reflecting the user location.
        static let userLocationDotSize: CGFloat = 20

        /// If a user-location is older then the given time interval we assume it's outdated and therefore
        /// apply another `foregroundColor` to the dot, reflecting the user-location.
        static let validUserLocationTimeInterval: TimeInterval = 5 * 60
    }

    // MARK: - Public properties

    let info: LocationInformation

    // MARK: - Private properties

    var circleFillColor: Color {
        info.userLocation.timestamp > Date(timeIntervalSinceNow: -Config.validUserLocationTimeInterval)
            ? .blue
            : .gray
    }

    // MARK: - Render

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let weather = info.weather, let first = weather.first {
                    Text(Fun.emojis.randomElement() ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .font(.subheadline)
                    Text(first.name ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                        .bold()
                    Text(first.forecast)
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                    Text(Fun.emojis.randomElement() ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .font(.subheadline)
                    Text(weather[1].name ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                        .bold()
                    Text(weather[1].forecast)
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                    Text(Fun.emojis.randomElement() ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .font(.subheadline)
                    Text(weather[2].name ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                        .bold()
                    Text(weather[2].forecast)
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                    Text(Fun.emojis.randomElement() ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .font(.subheadline)
                    Text(weather[3].name ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                        .bold()
                    Text(weather[3].forecast)
                        .multilineTextAlignment(.center)
                        .lineLimit(100)
                        .font(.caption)
                }
                
            }
        }
        .ignoresSafeArea()
    }
}

struct WhereNowBirdSightingsWidgetView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    var notables: Bool? = false

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            Text(entry.birdsDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .accessoryRectangular:
            Text(entry.birdsDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .accessoryCircular:
            VStack {
                Text(entry.birdsDescription)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                Text(entry.birdsDescription)
                    .font(.caption)
            }
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemSmall:
            Text(entry.birdsDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemMedium:
            Text(entry.birdsDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        case .systemLarge:
            switch entry.state {
            case .success(let entryInfo):
                BirdDataSightingsShortView(birdData: notables == true ? (entryInfo.notableBirdSightings ?? []) : entryInfo.birdSightings ?? [], notables: true)
                    .containerBackground(.fill.tertiary, for: .widget)
            case .placeholder:
                BirdDataSightingsShortView(birdData: [BirdSighting(subId: "S1", userDisplayName: "Unknown", speciesCode: "BigiusBirdius", comName: "Big Bird", sciName: "Bigius Birdius", locId: "SesameStreetPA", locName: "Sesame Street, NY/PA", obsDt: "Today", howMany: 1, lat: 43, lng: 72, obsValid: true, obsReviewed: true, locationPrivate: false)], notables: notables == true)
                    .containerBackground(.fill.tertiary, for: .widget)
            case .failure(let error):
                ErrorView(errorMessage: "\(error) Where now, birds!")
            }
        case .systemExtraLarge:
            Text(entry.birdsDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        @unknown default:
            Text(entry.birdsDescription)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct WhereNowBirdSightingsWidget: Widget {
    
    let kind: String = WidgetKinds.WhereNowBirdSightingsWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowBirdSightingsWidgetView(entry: entry)
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
            WhereNowBirdSightingsWidgetView(entry: entry, notables: true)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(NotableBirdSightingsWidgetConfig.displayName)
        .description(NotableBirdSightingsWidgetConfig.description)
        .supportedFamilies(NotableBirdSightingsWidgetConfig.supportedFamilies)
    }
}


struct WhereNowMapWidget: Widget {
    @Environment(\.widgetFamily) var widgetFamily
    let kind: String = WidgetKinds.WhereNowMapWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            switch entry.state {
                case .success(let locationInfo):
                    WhereNowMapWidgetView(info: locationInfo)
                        .containerBackground(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .bottomLeading, endPoint: .topTrailing), for: .widget)
                case .placeholder:
                    WhereNowMapWidgetView(info: LocationInformation(userLocation: CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792), image: Image("MapApplePark"), addresses: [Address(localName: "Apple")]))
                    .containerBackground(.fill.tertiary, for: .widget)
                case .failure(let error):
                    ErrorView(errorMessage: error.localizedDescription)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
                
        }
        .configurationDisplayName(MapWidgetConfig.displayName)
        .description(MapWidgetConfig.description)
        .supportedFamilies(MapWidgetConfig.supportedFamilies)
    }
}

struct WhereNowMapAndWeatherWidget: Widget {
    @Environment(\.widgetFamily) var widgetFamily
    let kind: String = WidgetKinds.WhereNowMapAndWeatherWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            switch entry.state {
                case .success(let locationInfo):
                    WhereNowMapAndWeatherWidgetView(info: locationInfo)
                        .ignoresSafeArea()
                        .containerBackground(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .bottomLeading, endPoint: .topTrailing), for: .widget)
                case .placeholder:
                    WhereNowMapAndWeatherWidgetView(info: LocationInformation(userLocation: CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792), image: Image("MapApplePark"), addresses: [Address(localName: "Apple")]))
                    .ignoresSafeArea()
                    .containerBackground(.fill.tertiary, for: .widget)
                case .failure(let error):
                    ErrorView(errorMessage: error.localizedDescription)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
                
        }
        .configurationDisplayName(MapAndWeatherWidgetConfig.displayName)
        .description(MapAndWeatherWidgetConfig.description)
        .supportedFamilies(MapAndWeatherWidgetConfig.supportedFamilies)
    }
}

struct WhereNowLongWeatherTextWidget: Widget {
    @Environment(\.widgetFamily) var widgetFamily
    let kind: String = WidgetKinds.WhereNowLongWeatherWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            switch entry.state {
                case .success(let locationInfo):
                    WhereNowLongWeatherWidgetView(info: locationInfo)
                        .containerBackground(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .bottomLeading, endPoint: .topTrailing), for: .widget)
                case .placeholder:
                    WhereNowLongWeatherWidgetView(info: LocationInformation(userLocation: CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792), image: Image("MapApplePark"), addresses: [Address(localName: "Apple")]))
                    .containerBackground(.fill.tertiary, for: .widget)
                case .failure(let error):
                    ErrorView(errorMessage: error.localizedDescription)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
                
        }
        .configurationDisplayName(LongWeatherWidgetConfig.displayName)
        .description(LongWeatherWidgetConfig.description)
        .supportedFamilies(LongWeatherWidgetConfig.supportedFamilies)
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

#if DEBUG
    struct WhereNowMapWidgetView_Previews: PreviewProvider {
        static var previews: some View {
            let appleParkLocation = CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792)
            let info = LocationInformation(userLocation: appleParkLocation, image: Image("MapApplePark"), addresses: [Address(streetNumber: "1", street: "street", streetName: "streetName", streetNameAndNumber: "1 streetNameWithNumber", countryCode: "US", municipality: "municipality", postalCode: "12345", country: "United States", localName: "localName")], weather: [ForecastInfo(name: "now", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! "),ForecastInfo(name: "later later", forecast: "Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! Weather Now! ")], birdSightings: [BirdSighting(subId: "S1", userDisplayName: "Hansen", speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen", speciesCode: "BigBirdo", comName: "Big Birdo", sciName: "Birdius Bigiuso", locId: "SesameStreeto", locName: "Sesame Street, PAO", obsDt: "Todayo", howMany: 100, lat: 43.1861, lng: 72.8730, obsValid: true, obsReviewed: true, locationPrivate: true),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBirdu", comName: "Big Birdu", sciName: "Birdius Bigiusu", locId: "SesameStreetu", locName: "Sesame Street, PAU", obsDt: "Todayu", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(subId: "S1", userDisplayName: "Hansen",speciesCode: "BigBirda", comName: "Big Birda", sciName: "Birdius Bigiusa", locId: "SesameStreetA", locName: "Sesame Street, PAA", obsDt: "TodayA", howMany: 1, lat: 41.1861, lng: 75.8730, obsValid: true, obsReviewed: true, locationPrivate: false)])

            let informationEntry = LocationInformationEntry(date: Date(),
                                                    state: .success(info))

            return Group {
                WhereNowBirdSightingsWidgetView(entry: informationEntry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .previewContext(WidgetPreviewContext(family: .systemLarge))
                    .previewDevice("iPhone 15 Pro")
            }
        }
    }
#endif
