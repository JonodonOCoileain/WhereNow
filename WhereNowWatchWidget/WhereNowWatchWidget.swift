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
        //#if TARGET_OS_WATCH
            print("watchOS")
            let location = locationManager.immediateLocation() ?? CLLocation(latitude: 0, longitude: 0)
            let addresses = await location.getAddresses()
            let entry = LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: addresses)))
            return entry
        /*#else
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
        //#endif*/
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<LocationInformationEntry> {
        if let location = locationManager.immediateLocation() {
        let addresses = await location.getAddresses()
            let entries = addresses.compactMap({ LocationInformationEntry(date: .now, state: .success(LocationInformation(userLocation: location, image: nil, addresses: [$0]))) })
            return Timeline(entries: entries, policy: .atEnd)
        } else {
            return Timeline(entries: [], policy: .after(.now + 60*10))
        }
    }
    
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Create an array with all the preconfigured widgets to show.
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Watch Widget")]
    }
//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct WhereNowTextWidgetView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.shortDescription)
    }
}
@main
struct WhereNowTextWidget: Widget {
    let kind: String = WidgetKinds.WhereNowTextWidget.description

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowTextWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(TextWidgetConfig.displayName)
        .description(TextWidgetConfig.description)
        .supportedFamilies(TextWidgetConfig.supportedFamilies)
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
    struct WhereNowTextWidgetView_Previews: PreviewProvider {
        static var previews: some View {
            let appleParkLocation = CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792)
            let info = LocationInformation(userLocation: appleParkLocation,
                                          image: Image("MapApplePark"))

            let informationEntry = LocationInformationEntry(date: Date(),
                                                    state: .success(info))

            return Group {
                WhereNowTextWidgetView(entry: informationEntry)
                    .previewContext(WidgetPreviewContext(family: .accessoryInline))
            }
        }
    }
#endif


/*#Preview(as: .accessoryRectangular) {
    WhereNowWatchWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}    */
