//
//  WhereNowWidget.swift
//  WhereNowWidget
//
//  Created by Jon on 7/19/24.
//

import WidgetKit
import SwiftUI
import CoreLocation

struct Provider: AppIntentTimelineProvider {
    @EnvironmentObject var data: LocationDataModel
    
    func placeholder(in context: Context) -> SimpleEntry {
        let group = DispatchGroup()
            group.enter()
        var placemarkArray: [CLPlacemark]? = nil
        data.currentLocation?.getPlaces(with: { placemarks in
            placemarkArray = placemarks
            group.leave()
        })
        group.wait(timeout: DispatchTime(uptimeNanoseconds:2000000000)) // blocks current queue so beware!
        return SimpleEntry(date: Date(), placemarks: placemarkArray ?? data.placemarks, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), placemarks: data.placemarks, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        data.manager.requestWhenInUseAuthorization()
        data.manager.requestLocation()
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        /*let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, placemarks: data.placemarks, configuration: configuration)
            entries.append(entry)
        }*/
        let group = DispatchGroup()
        group.enter()
        var placemarkArray: [CLPlacemark]? = nil
        data.manager.location?.getPlaces(with: { placemarks in
            placemarkArray = placemarks
            group.leave()
        })
        group.wait(timeout: DispatchTime(uptimeNanoseconds:2000000000))
        return Timeline(entries: [SimpleEntry(date: Date(), placemarks: placemarkArray ?? data.placemarks, configuration: configuration)], policy: .atEnd)
    }

    /*func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
        return WidgetRelevances([WidgetRelevanceEntry(configuration: <#T##WidgetConfigurationIntent#>, context: RelevantContext()])
        // Generate a list containing the contexts this widget is relevant in.
    }*/
}

final class SimpleEntry: TimelineEntry, ObservableObject {
    var date: Date
    var placemarks: [CLPlacemark]
    let configuration: ConfigurationAppIntent
    let locationManager: CLLocationManager = CLLocationManager()
    @EnvironmentObject var data: LocationDataModel
    
    init(date: Date, placemarks: [CLPlacemark], configuration: ConfigurationAppIntent) {
        self.date = date
        self.configuration = configuration
        self.placemarks = placemarks
        self.data.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [weak self] in
            self?.locationManager.location?.getPlaces(with: { placemarks in
                if let placemarks = placemarks {
                    if self?.placemarks.count == 0 {
                        self?.placemarks = placemarks
                    }
                }
            })
        })
    }
}

struct WhereNowWidgetEntryView : View {
    @ObservedObject var entry: Provider.Entry

    var body: some View {
        VStack {
            if #available(watchOS 7.0, *) {
                Text(entry.locationManager.location?.description ?? entry.placemarks.compactMap({ $0.streetAndTown()
                }).joined(separator: "\n"))
            } else {
                Text(entry.locationManager.location?.description ?? entry.placemarks.compactMap({ $0.makeAddressString()
                }).joined(separator: "\n"))
            }
        }
    }
}

struct WhereNowWidget: Widget {
    let kind: String = "WhereNowWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WhereNowWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

/*#Preview(as: .systemSmall) {
    WhereNowWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}*/
