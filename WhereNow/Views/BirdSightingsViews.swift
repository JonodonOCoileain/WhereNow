//
//  BirdsBriefView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import AVFoundation
import MapKit
import OSLog

struct BirdSightingsViews: View {
    @EnvironmentObject var birdData: BirdSightingService
    @EnvironmentObject var locationData: LocationDataModel
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    static let Distance: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 35, 40, 45, 50]
    static let DistanceCount: IntegerLiteralType = 18
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("🐥 Avian data provided by the Lab of Ornithology and Macauley Library of Cornell University")
                    .font(.system(size: titleSize))
                    .multilineTextAlignment(.leading)
                    .padding([.horizontal])
                    .lineLimit(3)
                HStack {
                    Text("Sightings search radius")
                        .font(.system(size: titleSize))
                        .multilineTextAlignment(.leading)
                    Picker(selection: $birdData.searchRadius, label: Text("Sightings search radius")
                        .font(.system(size: titleSize))
                        .multilineTextAlignment(.leading)
                        .padding(.bottom))
                    {
                        ForEach(0 ..< BirdSightingsViews.DistanceCount) {
                            index in Text("\(BirdSightingsViews.Distance[index])").tag(BirdSightingsViews.Distance[index])
                        }
                    }
                }
                Spacer()
                ScrollView(.horizontal) {
                    HStack(alignment:.top) {
                        BirdSightingsContainerView(notables: true)
                            .frame(width: geometry.size.width - 5)
                        
                        VStack(alignment: .leading) {
                            Text("🐦 Birds sighted near here recently:")
                                .font(.system(size: titleSize))
                                .multilineTextAlignment(.leading)
                                .padding([.horizontal])
                                .padding(.bottom, 4)
                            ScrollView {
                                Text("🐣 " + (birdData.birdSeenCommonDescription ?? ""))
                                    .font(.caption)
                                    .bold()
                                    .font(.system(size: descriptionSize))
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal)
                                    .lineLimit(1000000)
                            }
                        }.frame(minWidth: geometry.size.width - 5, maxWidth: geometry.size.width - 5, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize - 80: geometry.size.height - 80, maxHeight: geometry.size.height)
                        
                        BirdSightingsContainerView()
                            .frame(width: geometry.size.width - 5)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                Spacer()
            }.environmentObject(birdData)
        }
    }
}

public struct BirdSightingsContainerView: View {
    @EnvironmentObject var birdData: BirdSightingService
    @EnvironmentObject var locationData: LocationDataModel
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    @State private var isFullScreen = false
    @State var notables: Bool? = false
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading, spacing: 9) {
                let sightings = notables == true ? birdData.notableSightings : birdData.sightings
                Divider()
                    .overlay(.purple)
                    .padding(.top)
                ForEach(sightings.enumeratedArray(), id: \.element) { index, sighting in
                    BirdSightingView(index: index, sighting: sighting, notables: notables)
                        .padding([.bottom, .leading, .trailing])
                    Divider()
                        .overlay(.purple)
                }
            }
        }
        .modifier(FadingView())
    }
}

class PlayerViewModel: NSObject, ObservableObject {
    var audioPlayer: AVPlayer = AVPlayer()
    
    @Published var isPlaying = false
    @Published var duration: Double = 5
    @Published var currentTime: Double = 0
    var timer: Timer?
    
    func set(url: URL) {
        let avPlayerItem = AVPlayerItem(url: url)
        self.audioPlayer = AVPlayer(playerItem: avPlayerItem)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: self.audioPlayer.currentItem
            )
    }
    
    func play() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            print(error)
        }
        audioPlayer.play()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            if self?.audioPlayer.currentItem?.status == .readyToPlay {
                self?.duration = self?.audioPlayer.currentItem?.duration.seconds ?? 1
                self?.currentTime += 0.1
            }
        }
        isPlaying = true
    }
    
    func pause() {
        audioPlayer.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    func stop() {
        audioPlayer.pause()
        audioPlayer.seek(to: .zero)
        isPlaying = false
        timer?.invalidate()
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        isPlaying = false
        timer?.invalidate()
        currentTime = 0
    }
}

#if os(iOS) || os(macOS) || os(tvOS)
class IdentifiableRoute: Identifiable, ObservableObject {
    @Published var route: MKRoute
    let id: ObjectIdentifier
    
    init(route: MKRoute) {
        self.route = route
        self.id = ObjectIdentifier(route)
    }
}
#endif

struct FullScreenModalView: View {
    @Environment(\.dismiss) var dismiss
    @State var data: BirdSpeciesAssetMetadata
    var body: some View {
        VStack {
#if os(macOS)
            if let image = data.image, let nsImage = NSImage(data: image) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                
            } else {
                let urlString = data.url
                if let url = URL(string: urlString) {
                    AsyncImage(url: url) { result in
                        result.image?
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
#else
            if let image = data.image, let uiImage = UIImage(data: image) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                
            } else {
                let urlString = data.url
                if let url = URL(string: urlString) {
                    AsyncImage(url: url) { result in
                        result.image?
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
#endif
            
            if let sciName = data.sciName {
                Text(sciName)
            }
            
            if let comName = data.comName {
                Text(comName)
            }
            
            let uploadedBy = data.uploadedBy.replacingOccurrences(of: "\"", with: "")
            if uploadedBy.count > 0 {
                Text("Uploaded by:")
                Text(uploadedBy.replacingOccurrences(of: "\"", with: ""))
            }
            
            if let description = data.description, description.count > 0 {
                Text("Description:")
                Text(description)
            }
            if let url = URL(string: data.generatedUrl) {
                Link(url.absoluteString, destination: url)
            }
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            dismiss()
        }
    }
}
#if os(iOS) || os(macOS) || os(tvOS)
struct FullScreenModalDirectionsView: View {
    @Environment(\.dismiss) var dismiss
    let destination: CLLocationCoordinate2D
    let transport: MKDirectionsTransportType
    @State var route: IdentifiableRoute
    @ObservedObject var newRoute: IdentifiableRoute
    @State var sighting: BirdSighting
    @ObservedObject var locationData: LocationDataModel
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @State var timePassed: Bool = false
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                RouteSummaryView(route: route, transport: transport)
                Spacer()
                RouteMapView(route: route, newRoute: newRoute)
                
                Spacer()
                RouteStepsView(steps: route.route.steps, newRoute: newRoute)
                
                
                if let locName = sighting.locName?.replacingOccurrences(of: "--", with: ", ").replacingOccurrences(of: "-", with: " "), let startingPoint = locationData.immediateLocation()?.coordinate, let url = URL(string:
                                                                                                                                                                                                                            "https://www.google.co.in/maps/dir/\(startingPoint.latitude),\(startingPoint.longitude)/\(locName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")/") {
                    Spacer()
                    Button(action: {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #else
                        UIApplication.shared.open(url)
                        #endif
                    }, label: { Text("Open in Google Maps") })
#if os(iOS) || os(macOS)
                    Spacer()
                    Button(action: { self.openMapForPlace(latitude: destination.latitude, longitude: destination.longitude, name: locName) }, label: { Text("Open in Apple Maps") })
#endif
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                dismiss()
            }
            .onReceive(timer) { input in
                timePassed = true
            }
        }
        .onChange(of: locationData.currentLocation) { oldValue, newValue in
            
            // Coordinate to use as a starting point for the example
            guard let startingPoint = newValue?.coordinate else { return }
            
            // Create and configure the request
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: self.destination))
            request.transportType = transport
            // Get the directions based on the request
            Task {
                let directions = MKDirections(request: request)
                do {
                    let response = try await directions.calculate()
                    guard let route = response.routes.first else { return }
                    
                    self.newRoute.route = route
                } catch {
                    print(error)
                }
            }
        }
    }
#if os(iOS) || os(macOS)
    func openMapForPlace(latitude: CLLocationDegrees, longitude: CLLocationDegrees, name: String) {
        let regionDistance:CLLocationDistance = 1000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)

        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
#endif
}

extension TimeInterval {
    func spellOut() -> String {
        return Duration.seconds(self).formatted(.units(
            allowed: [.days, .hours, .minutes, .seconds],
            width: .wide
        ))
    }
}

struct RouteSummaryView: View {
    @ObservedObject var route: IdentifiableRoute
    let transport: MKDirectionsTransportType
    var body: some View {
        Text((transport == .walking ? "Pedestrian " : "Driving ") + "directions to \(route.route.name)").font(.title)
            .padding([.vertical])
            .lineLimit(2)
            .multilineTextAlignment(.center)
        Text("Expected travel time: \(route.route.expectedTravelTime.spellOut())").font(.caption)
        if Locale.current.usesMetricSystem == true {
            let distance = String(format: "%.1f", Double(round(route.route.distance.inKilometers()*Double(10)))/Double(10))
            Text("Distance: \(distance) kilometers").font(.caption)
        } else {
            let imperialDistance = String(format: "%.2f", Double(round(route.route.distance.inMiles()*Double(100)))/Double(100))
            Text("Distance: \(imperialDistance) miles").font(.caption)
        }
        if !route.route.advisoryNotices.isEmpty {
            Text("Advisory Notices:").font(.caption)
            ForEach(route.route.advisoryNotices, id: \.self) { notice in
                Text(notice).font(.caption)
            }
        }
    }
}

struct RouteMapView: View {
    @ObservedObject var route: IdentifiableRoute
    @ObservedObject var newRoute: IdentifiableRoute
    
    var body: some View {
        Map(interactionModes: [.rotate], content: {
            MapPolyline(route.route)
                .stroke(Color(red: 0.68, green: 0.85, blue: 0.9), lineWidth: 4)
            MapPolyline(route.route)
                .stroke(.blue, lineWidth: 5)
            
        })
        .frame(maxWidth: .infinity, minHeight: 450, maxHeight: 450)
    }
}

struct RouteStepsView: View {
    let steps: [MKRoute.Step]
    @ObservedObject var newRoute: IdentifiableRoute
    
    var body: some View {
        ScrollView {
            VStack {
                let steps: [MKRoute.Step] = steps.filter({ $0.instructions != "" })
                ForEach(steps, id: \.self) { step in
                    let newSteps: [MKRoute.Step] = newRoute.route.steps.filter({ $0.instructions != "" })
                    if newSteps.first?.instructions ?? "" == step.instructions {
                        Text(step.instructions).font(.subheadline).foregroundStyle(.blue)
                    } else {
                        Text(step.instructions).font(.subheadline)
                    }
                    if Locale.current.usesMetricSystem == true {
                        let distance = String(format: "%.1f", Double(round(step.distance.inKilometers()*10))/10)
                        Text("\(distance) kilometers").font(.caption)
                    } else {
                        let imperialDistance = String(format: "%.2f", Double(round(step.distance.inMiles()*100))/100)
                        Text("\(imperialDistance) miles").font(.caption)
                    }
                    
                    Text(step.notice ?? "").font(.caption)
                }
            }
        }
    }
}

extension CLLocationDistance {
    func inMiles() -> Double {
        return Double(self)*Double(0.00062137)
    }

    func inKilometers() -> Double {
        return Double(self)/Double(1000)
    }
}

extension UnitLength {
    static var preciseMiles: UnitLength {
        return UnitLength(symbol: "mile",
                          converter: UnitConverterLinear(coefficient: 1609.344))
    }
}

public extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)

        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

        return coords
    }
}
#endif
