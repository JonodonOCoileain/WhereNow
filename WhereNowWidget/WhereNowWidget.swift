//
//  WhereNowWidget.swift
//  WhereNowWidget
//
//  Created by Jon on 7/19/24.
//

import WidgetKit
import SwiftUI
import CoreLocation
import MapKit
import Foundation
/*
struct Provider: AppIntentTimelineProvider {
    @EnvironmentObject var data: LocationDataModel
    
    func placeholder(in context: Context) -> SimpleEntry {
        let group = DispatchGroup()
        group.enter()
        var addresses: [Address]? = nil
        guard let coordinate = data.manager.location?.coordinate, let url = URL(string: "https://api.tomtom.com/search/2/reverseGeocode/\(coordinate.latitude),\(coordinate.longitude).json?key=FBSjYeqToGYAeG2A5txodKfGHrql38S4&radius=100") else { return SimpleEntry(date: Date(), state: .failure(SnapshotManager.SnapshotError.noAddresses)) }
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
            do {
                let newResponse = try JSONDecoder().decode(Response.self, from: data)
                addresses = newResponse.addresses.compactMap({$0.address})
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
        group.wait(timeout: DispatchTime(uptimeNanoseconds:2000000000)) // blocks current queue so beware!
        return SimpleEntry(date: Date(), addresses: addresses ?? data.addresses, state: .success(MapSnapshot(userLocation: data.manager.location ?? CLLocation(), image: <#T##Image#>)))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), addresses: data.addresses, configuration: configuration)
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
        var addresses: [Address]? = nil
        if let coordinate = data.manager.location?.coordinate, let url = URL(string: "https://api.tomtom.com/search/2/reverseGeocode/\(coordinate.latitude),\(coordinate.longitude).json?key=FBSjYeqToGYAeG2A5txodKfGHrql38S4&radius=100") {
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                print(String(data: data, encoding: .utf8)!)
                do {
                    let newResponse = try JSONDecoder().decode(Response.self, from: data)
                    addresses = newResponse.addresses.compactMap({$0.address})
                } catch {
                    print(error.localizedDescription)
                }
            }
            task.resume()
            group.wait(timeout: DispatchTime(uptimeNanoseconds:2000000000))
            let addresses = addresses ?? data.addresses
            let timeline = Timeline(entries: [SimpleEntry(date: Date(), addresses: addresses, configuration: configuration)], policy: .after(.now + Double(60.0)*Double(22.0)))
            return timeline
        } else {
            return Timeline(entries: [SimpleEntry(date: Date(), addresses: data.addresses, configuration: configuration)], policy: .after(.now + Double(60.0)*Double(22.0)))
        }
    }

    /*func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
        return WidgetRelevances([WidgetRelevanceEntry(configuration: <#T##WidgetConfigurationIntent#>, context: RelevantContext()])
        // Generate a list containing the contexts this widget is relevant in.
    }*/
}*/

struct WhereNowWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    
    // MARK: - Config
    
    private enum Config {
        /// The size of the blue dot reflecting the user location.
        static let userLocationDotSize: CGFloat = 20
        
        static let userLocationSmallDotSize: CGFloat = 20

        /// If a user-location is older then the given time interval we assume it's outdated and therefore
        /// apply another `foregroundColor` to the dot, reflecting the user-location.
        static let validUserLocationTimeInterval: TimeInterval = 5 * 60
    }

    // MARK: - Public properties

    let mapSnapshot: MapSnapshot

    // MARK: - Private properties

    var circleFillColor: Color {
        mapSnapshot.userLocation.timestamp > Date(timeIntervalSinceNow: -Config.validUserLocationTimeInterval)
            ? .blue
            : .gray
    }

    // MARK: - Render

    var body: some View {
        switch family {
        case .systemSmall:
            HStack {
                ZStack {
                    mapSnapshot.image?
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .cornerRadius(20)
                        .clipped()
                    
                    // The map is centered on the user location, therefore we can simply draw the blue dot in the
                    // center of our view to simulate the user coordinate.
                    Circle()
                        .foregroundColor(circleFillColor)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .frame(width: Config.userLocationSmallDotSize,
                               height: Config.userLocationSmallDotSize)
                }
                .edgesIgnoringSafeArea(.all)
                .overlay(alignment: .center, content: {
                    Text(mapSnapshot.addresses?.compactMap({$0.formattedCommonWithFlag()}).joined(separator: "\n") ?? "")
                        .multilineTextAlignment(.center)
                        .lineLimit(1000)
                        .edgesIgnoringSafeArea(.all)
                        .bold()
                        .font(.caption2)
                })
            }
            .containerBackground(.background, for: .widget)
            .edgesIgnoringSafeArea(.all)
            .scaledToFill()
        case .systemMedium:
            HStack {
                ZStack {
                    mapSnapshot.image?
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(20)
                        .clipped()
                        .edgesIgnoringSafeArea(.all)
                    
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
                        .edgesIgnoringSafeArea(.all)
                }
                .edgesIgnoringSafeArea(.all)
                Text(mapSnapshot.addresses?.compactMap({$0.formattedCommonWithFlag()}).joined(separator: "\n") ?? "")
                    .multilineTextAlignment(.center)
                    .lineLimit(1000)
                    .edgesIgnoringSafeArea(.all)
                    .font(.caption)
                
            }
            .containerBackground(LinearGradient(gradient: Gradient(colors: [.pink, .purple, .indigo]), startPoint: .bottomLeading, endPoint: .topTrailing), for: .widget)
            .edgesIgnoringSafeArea(.all)
        case .systemLarge, .systemExtraLarge:
            HStack {
                ZStack {
                    mapSnapshot.image?
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .cornerRadius(20)
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
                    
                    Text("\n\n\n\n\n\n"+(mapSnapshot.addresses?.compactMap({$0.formattedCommonWithFlag()}).joined(separator: "\n") ?? ""))
                        .multilineTextAlignment(.center)
                        .lineLimit(1000)
                        .edgesIgnoringSafeArea(.all)
                        .bold()
                }
                .edgesIgnoringSafeArea(.all)
            }
            .containerBackground(.background, for: .widget)
            .edgesIgnoringSafeArea(.all)
        default:
            Text(mapSnapshot.addresses?.compactMap({$0.formattedVeryShort()}).joined(separator: "\n") ?? "")
                .multilineTextAlignment(.center)
                .lineLimit(1000)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct WhereNowWidget: Widget {
    // MARK: - Config

    private enum Config {
        /// The name shown for a widget when a user adds or edits it.
        static let displayName = "Location Widget"

        /// The description shown for a widget when a user adds or edits it.
        static let description = "This is a widget showing a location."
        /// The sizes that our widget supports.
        ///
#if os(watchOS)
        static let supportedFamilies: [WidgetFamily] = [.accessoryCircular,
                                                        .accessoryRectangular, .accessoryInline]
#else
        static let supportedFamilies: [WidgetFamily] = [.accessoryCircular,
                            .accessoryRectangular, .accessoryInline,
                            .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
#endif
    }

    // MARK: - Public properties

    let kind: String = "WhereNowWidget"

    // MARK: - Dependencies

    private let locationManager = LocationManager(locationStorageManager: UserDefaults.standard)
    private let mapSnapshotManager = SnapshotManager()

    // MARK: - Render

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: MapTimelineProvider(locationManager: locationManager,
                                                          mapSnapshotManager: mapSnapshotManager)) { entry in
            MapWidgetView(entry: entry)
                .edgesIgnoringSafeArea(.all)
                .scaledToFill()
        }
        .configurationDisplayName(Config.displayName)
        .description(Config.description)
#if os(watchOS)
        .supportedFamilies([.accessoryCircular,
                            .accessoryRectangular, .accessoryInline])
#else
        .supportedFamilies([.accessoryCircular,
                            .accessoryRectangular, .accessoryInline,
                            .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
#endif
    }
}

struct MapWidgetView: View {
    // MARK: - Public properties

    let entry: MapTimelineEntry

    // MARK: - Render

    var body: some View {
        switch entry.state {
        case let .success(mapSnapshot):
            WhereNowWidgetEntryView(mapSnapshot: mapSnapshot)
                .edgesIgnoringSafeArea(.all)
                .scaledToFill()

        case let .failure(error):
            ErrorView(errorMessage: error.localizedDescription)
                .edgesIgnoringSafeArea(.all)

        case .placeholder:
            /// The timeline provider asked for a placeholder synchronously.
            /// Therefore we simply show the `MapErrorView` without a specific `errorMessage`.
            ErrorView(errorMessage: nil)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

#if DEBUG
struct WhereNowWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let appleParkLocation = CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792)
        let mapSnapshot = MapSnapshot(userLocation: appleParkLocation,
                                      image: Image("MapApplePark"), addresses: [Address(streetName: "O'Coileain St", localName: "Hill O'Coileain")])
        
        //let mapTimelineEntry = MapTimelineEntry(date: Date(),
        //                                            state: .success(mapSnapshot))
        
        return Group {
            WhereNowWidgetEntryView(mapSnapshot: mapSnapshot)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
        }
    }
}
#endif
