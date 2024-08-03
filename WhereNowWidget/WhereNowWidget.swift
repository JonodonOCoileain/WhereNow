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

private enum TextWidgetConfig {
    /// The name shown for a widget when a user adds or edits it.
    static let displayName = "Text Widget"

    /// The description shown for a widget when a user adds or edits it.
    static let description = "This is a widget to show metadata of a location."

    /// The sizes that our widget supports.
    static let supportedFamilies: [WidgetFamily] = [.accessoryInline, .accessoryCircular, .accessoryRectangular]
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
    //private let mapSnapshotManager: MapSnapshotManager
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> LocationInformationEntry {
        #if TARGET_OS_WATCH
            print("watchOS")
            let location = locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
            let addresses = await location.getAddresses()
            let entry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses)))
            return entry
        #else
            print("Not watchOS")
            let location = locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
            let coordinate = location.coordinate
        
            let snapshots = MapSnapshotManager()
            let snapshotResult = await snapshots.snapshot(of: coordinate)
            let addresses = await location.getAddresses()
        
        switch snapshotResult {
        case .success(let image):
            return LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: image, addresses: addresses)))
        case .failure(_):
            return LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses)))
        }
#endif
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<LocationInformationEntry> {
        if let location = locationManager.immediateLocation() {
            let snapshots = MapSnapshotManager()
            let snapshotResult = await snapshots.snapshot(of: location.coordinate)
            let addresses = await location.getAddresses()
            var locationInformationEntry: LocationInformationEntry
            switch snapshotResult {
            case .success(let image):
                locationInformationEntry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: image, addresses: addresses)))
            case .failure(_):
                locationInformationEntry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses)))
            }
            
            return Timeline(entries: [locationInformationEntry], policy: .after(.now + 60*19.5))
        } else {
            return Timeline(entries: [], policy: .after(.now + 60*10))
        }
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

struct WhereNowMapWidgetViewX : View {
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
        ZStack {
            info.image?
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            Text(info.addresses?.first?.formattedCommonVeryLongFlag() ?? "Planet Earth, Milky Way")
                .multilineTextAlignment(.center)
                .lineLimit(0)
                .background(.white)
        }
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
                
                Text(info.addresses?.first?.formattedCommonVeryLongFlag() ?? "Planet Earth, Milky Way")
                        .multilineTextAlignment(.center)
                        .lineLimit(8)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.4, green: 0, blue: 0.7))
                        .frame(minWidth: 80, maxWidth: .infinity, maxHeight: .infinity)
                        .bold()
                        .opacity(widgetFamily != .systemMedium ? 1 : 0)
            }
            .frame(minWidth: 80, maxWidth: 370, maxHeight: .infinity)
            
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
                
                Text(info.addresses?.first?.formattedCommonVeryLongFlag() ?? "Planet Earth, Milky Way")
                        .multilineTextAlignment(.center)
                        .lineLimit(8)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.4, green: 0, blue: 0.7))
                        .frame(minWidth: 80, maxWidth: .infinity, maxHeight: .infinity)
                        .bold()
                        .opacity(widgetFamily != .systemMedium ? 1 : 0)
            }
            .frame(minWidth: 80, maxWidth: 370, maxHeight: .infinity)
            
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
                        .containerBackground(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .bottomLeading, endPoint: .topTrailing), for: .widget)
                case .placeholder:
                    WhereNowMapAndWeatherWidgetView(info: LocationInformation(userLocation: CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792), image: Image("MapApplePark"), addresses: [Address(localName: "Apple")]))
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

extension ConfigurationAppIntent {
    fileprivate static var SpartaNJ: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.location = "07871"
        return intent
    }
    
    fileprivate static var CurrentLocation: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.location = "Current Location"
        return intent
    }
}

/*#Preview(as: .systemSmall) {
    WhereNowTextWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .SpartaNJ)
}*/

#if DEBUG
    struct WhereNowMapWidgetView_Previews: PreviewProvider {
        static var previews: some View {
            let appleParkLocation = CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792)
            let info = LocationInformation(userLocation: appleParkLocation,
                                          image: Image("MapApplePark"))

            let informationEntry = LocationInformationEntry(date: Date(),
                                                    state: .success(info))

            return Group {
                WhereNowWidgetTextView(entry: informationEntry)
                    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                
                WhereNowWidgetTextView(entry: informationEntry)
                    .previewContext(WidgetPreviewContext(family: .accessoryInline))
                
                WhereNowWidgetTextView(entry: informationEntry)
                    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            }
        }
    }
#endif
