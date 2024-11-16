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
#endif
import AVFoundation
import MapKit

struct BirdSightingsViews: View {
    @ObservedObject var birdData: BirdSightingService
    @ObservedObject var locationData: LocationDataModel
    let briefing: String
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack(alignment:.top) {
                    VStack(alignment: .leading) {
                        Text("🦅 Especially Notable Bird Reports thanks to Cornell Lab of Ornithology and the Macauley Library.")
                            .frame(width: geometry.size.width)
                            .lineLimit(5)
                        ScrollView() {
                            VStack(alignment: .leading, content: {
                                BirdSightingsContainerView(birdData: birdData, locationData: locationData, notables: true)
                                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: geometry.size.height, maxHeight: geometry.size.height)
                            }).frame(width: geometry.size.width)
                        }.frame(width: geometry.size.width)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("🐥 Avian data provided by the Lab of Ornithology and Macauley Library of Cornell University")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 1)
                            .lineLimit(3)
                        Text("🐦 Birds sighted near here recently:")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 4)
                        ScrollView {
                            Text("🐣 " + briefing)
                                .font(.caption)
                                .bold()
                                .font(.system(size: descriptionSize))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)
                                .lineLimit(1000000)
                        }
                    }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    
                    ScrollView {
                        BirdSightingsContainerView(birdData: birdData, locationData: locationData)
                            .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    }
                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 700, maxHeight: 1000)
                }
                .scrollTargetLayout()
            }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 700, maxHeight: 1000)
                .scrollTargetBehavior(.paging)
        }
    }
}





public struct BirdSightingsContainerView: View {
    @ObservedObject var birdData: BirdSightingService
    @ObservedObject var locationData: LocationDataModel
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    @State private var isFullScreen = false
    @State var notables: Bool? = false
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment:.leading, spacing: 9) {
                    let sightings = notables == true ? birdData.notableSightings : birdData.sightings
                    ForEach(sightings, id: \.self) { sighting in
                        BirdSightingView(sighting: sighting, locationData: locationData, currentLocation: locationData.currentLocation.coordinate, birdData: birdData, notables: notables)
                            .frame(width: geometry.size.width)
                    }
                }.frame(width: geometry.size.width)
            }.frame(width: geometry.size.width)
        }
    }
}

class PlayerViewModel: ObservableObject {
  var audioPlayer: AVPlayer?

  @Published var isPlaying = false
    
    init(with url: URL? = nil) {
        if let url = url {
            self.audioPlayer = AVPlayer(url: url)
        }
    }
    
    func set(url: URL) {
        self.audioPlayer = AVPlayer(url: url)
    }
    
    func play() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.play()
        isPlaying = true
    }
    
    func pause() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.pause()
        isPlaying = false
    }
    
    func stop() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.pause()
        audioPlayer.seek(to: .zero)
        isPlaying = false
    }
}

public struct BirdSightingView: View {
    @State private var isPresented: Bool = false
    @State private var selectedDetailTitle: String?
    @State private var selectedDetailSubtitle: String?
    @State private var selectedBirdData: BirdSpeciesAssetMetadata?
    #if os(iOS) || os(macOS) || os(tvOS)
    @State var route: IdentifiableRoute?
    @State var routeDestination: CLLocationCoordinate2D?
    #else
    @State var route: String?
    #endif
    @ObservedObject var player = PlayerViewModel()
    @State var sighting: BirdSighting
    @ObservedObject var locationData: LocationDataModel
    let currentLocation: CLLocationCoordinate2D?
    @ObservedObject var birdData: BirdSightingService
    private let titleSize: CGFloat = 11
    private let descriptionSize: CGFloat = 12
    @State var coordinate: CLLocationCoordinate2D?
    @State var notables: Bool? = false
    
    public var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                let relatedData = birdData.speciesMedia.filter({ $0.speciesCode == sighting.speciesCode })
                let photosData = relatedData.filter({$0.assetFormatCode == "photo"}).filter({ $0.comName == sighting.comName }).filter({ $0.sciName == sighting.sciName })
                if photosData.count > 0 {
                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .center) {
                            ForEach(photosData, id: \.self) { imageData in
                                VStack {
                                    if let URL = URL(string: imageData.url) {
                                        AsyncImage(url: URL) { result in
                                            result.image?
                                                .resizable()
                                                .scaledToFill()
                                        }
#if os(watchOS)
                                        .frame(width: 30, height: 30)
#else
                                        .frame(width: 64, height: 64)
#endif
                                    }
#if os(iOS) || os(macOS) || os(tvOS)
                                    Text("Uploaded by:")
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                    Text(imageData.uploadedBy.replacingOccurrences(of: "\"", with: ""))
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
#endif
                                    
                                }
                                .onTapGesture {
                                    print("Tapped")
#if os(iOS) || os(macOS)
                                    if let citationUrl = selectedBirdData?.citationUrl {
                                        UIApplication.shared.open(URL(string: citationUrl)!)
                                    }
#endif
                                }
                                .onLongPressGesture(perform: {
                                    selectedDetailTitle = sighting.sciName
                                    selectedDetailSubtitle = sighting.comName
                                    selectedBirdData = imageData
                                    isPresented.toggle()
                                })
                            }
                        }
                    }
                } else {
                    Text(Fun.eBirdjis.randomElement() ?? "")
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                }
                
                if let commonName = sighting.comName {
                    Text(commonName)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                if let name = sighting.sciName {
                    Text(name)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                if let location = sighting.locName?.replacingOccurrences(of: "--", with: ", ").replacingOccurrences(of: "-", with: " ") {
                    HStack(alignment: .center, spacing: 20) {
#if os(iOS) || os(macOS) || os(tvOS)
                        Text("Location: " + location + " 🚶🏿‍♀️")
                            .font(.system(size: descriptionSize))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .foregroundColor(UIDevice.current.systemName == "watchOS" ? .primary : .purple)
                            .onTapGesture(perform: {
                                if let coordinate = coordinate {
                                    
                                    self.route = nil
                                    
                                    // Coordinate to use as a starting point for the example
                                    guard let startingPoint = currentLocation else { return }
                                    
                                    // Create and configure the request
                                    let request = MKDirections.Request()
                                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
                                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                                    request.transportType = .walking
                                    routeDestination = coordinate
                                    // Get the directions based on the request
                                    Task {
                                        let directions = MKDirections(request: request)
                                        do {
                                            let response = try await directions.calculate()
                                            guard let route = response.routes.first else { return }
                                            
                                            self.route = IdentifiableRoute(route: route)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } else if let locName = sighting.locName?.replacingOccurrences(of: "--", with: ", ").replacingOccurrences(of: "-", with: " "), let startingPoint = currentLocation, let url = URL(string:
                                                                                                                                "https://www.google.co.in/maps/dir/\(startingPoint.latitude),\(startingPoint.longitude)/\(locName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")/") {
                                    UIApplication.shared.open(url)
                                }
                            })
                            
                        Text("Driving directions 🚗")
                            .font(.system(size: descriptionSize))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .foregroundColor(UIDevice.current.systemName == "watchOS" ? .primary : .red)
                            .onTapGesture(perform: {
                            if let locName = sighting.locName?.replacingOccurrences(of: "-", with: " "), let coordinate = coordinate {
                                
                                self.route = nil
                                
                                // Coordinate to use as a starting point for the example
                                guard let startingPoint = currentLocation else { return }
                                
                                // Create and configure the request
                                let request = MKDirections.Request()
                                request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
                                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                                request.transportType = .automobile
                                routeDestination = coordinate
                                // Get the directions based on the request
                                Task {
                                    let directions = MKDirections(request: request)
                                    do {
                                        let response = try await directions.calculate()
                                        guard let route = response.routes.first else { return }
                                        
                                        self.route = IdentifiableRoute(route: route)
                                    } catch {
                                        print(error)
                                    }
                                }
                            } else if let locName = sighting.locName?.replacingOccurrences(of: "-", with: " "), let startingPoint = currentLocation, let url = URL(string:
                                                                                                                                                                    "https://www.google.co.in/maps/dir/\(startingPoint.latitude),\(startingPoint.longitude)/\(locName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")/") {
                                UIApplication.shared.open(url)
                            }
                        })
#else
                        Text("Location: " + location)
                            .font(.system(size: descriptionSize))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
#endif
                    }
#if os(iOS) || os(macOS) || os(tvOS)
                    .sheet(item: $route, content: { route in
                        FullScreenModalDirectionsView(destination: routeDestination ?? CLLocationCoordinate2D(), route: route, newRoute: route, sighting: sighting, locationData: locationData)
                    })
#endif
                }
                if let date = sighting.obsDt {
                    Text("Date: " + date)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                if let quantity = sighting.howMany {
                    Text("Quantity: \(quantity)")
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                if let userName = sighting.userDisplayName?.replacingOccurrences(of: "\"", with: "") {
                    Text("Seen by: \(userName)")
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                if let locationPrivate = sighting.locationPrivate {
                    Text("In public location: \(locationPrivate == false)")
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
#if  os(iOS) || os(macOS) || os(tvOS)
                if let name = sighting.comName, let nameURLString = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string:"https://www.youtube.com/results?search_query=\(nameURLString)") {
                    Link("📺 YouTube", destination: url)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .padding([.top, .bottom], 4)
                }
                if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://media.ebird.org/catalog?taxonCode=\(speciesURLString)&mediaType=photo") {
                    Link("🖼️ Photos", destination: url)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .padding([.bottom], 4)
                }
                if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://media.ebird.org/catalog?taxonCode=\(speciesURLString)&mediaType=audio") {
                    Link("🎼🔊 Recordings", destination: url)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .padding([.bottom], 4)
                }
                //https://ebird.org/species/baleag
                if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://ebird.org/species/\(speciesURLString)") {
                    Link("Species Overview", destination: url)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                }
#endif
                //Audio files
                if relatedData.count > 0 {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(relatedData.filter({$0.assetFormatCode == "audio"}).filter({ $0.comName == sighting.comName }).filter({ $0.sciName == sighting.sciName })) { key in
                                Button(action:{
                                    if let url = URL(string: key.url) {
                                        self.player.set(url: url)
                                        if self.player.isPlaying {
                                            self.player.pause()
                                        } else {
                                            self.player.play()
                                        }
                                    }
                                },label:{
                                    VStack(alignment: .center, spacing: 2) {
                                        Image(systemName: "play.circle.fill")
#if os(watchOS)
                                            .frame(width: 20, height: 20)
                                            .clipShape(.rect(cornerRadius: 4))
                                            .buttonStyle(.bordered)
#else
                                            .frame(width: 64, height: 64)
                                            .clipShape(.rect(cornerRadius: 8))
                                            .buttonStyle(.borderedProminent)
#endif
                                            
                                        Text("Uploaded by:")
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                        Text(key.uploadedBy.replacingOccurrences(of: "\"", with: ""))
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                    }.onLongPressGesture {
#if os(iOS)
                                        UIApplication.shared.open(URL(string: key.citationUrl)!)
#endif
                                    }
                                })
                            }
                        }.padding()
                    }
                }
            }
            .sheet(item: $selectedBirdData, content: { data in
                FullScreenModalView(data: data)
            })
            .onAppear(perform:  {
                let relatedData = birdData.speciesMedia.filter({ $0.speciesCode == sighting.speciesCode })
                if [nil,0].contains(relatedData.count){
                    birdData.requestWebsiteAssetMetadataOf(sighting: sighting)
                }
                guard let locName = sighting.locName else { return }
                LocationDataModel.getCoordinate(addressString: locName, lat: sighting.lat, lng: sighting.lng) { coordinate, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    } else {
                        self.coordinate = coordinate
                    }}})
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
    @State var route: IdentifiableRoute
    @ObservedObject var newRoute: IdentifiableRoute
    @State var sighting: BirdSighting
    @ObservedObject var locationData: LocationDataModel
    
    var body: some View {
        VStack {
            Spacer()
            RouteSummaryView(route: route)
            Spacer()
            RouteMapView(route: route, newRoute: newRoute)
            
            Spacer()
            RouteStepsView(steps: route.route.steps, newRoute: newRoute)
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            dismiss()
        }
        .onChange(of: locationData.currentLocation) { oldValue, newValue in
            
            // Coordinate to use as a starting point for the example
            let startingPoint = locationData.currentLocation.coordinate
            
            // Create and configure the request
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: self.destination))
            request.transportType = .walking
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
    var body: some View {
        Text("Directions to \(route.route.name)").font(.title)
            .padding([.vertical])
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
        .frame(maxWidth: .infinity, maxHeight: 450)
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
/* audio asset example
 "asset": {
 "ageSex": {},
 "assetFormatCode": "audio",
 "assetId": 549106,
 "assetRestricted": true,
 "assetState": "committed",
 "assetTagCodes": ["call", "production"],
 "assetValid": true,
 "catalogDt": "2020-12-11T00:00:00",
 "catalogUserId": "USER16990",
 "citable": true,
 "citationName": "ML 92022701",
                 "citationUrl": "https://macaulaylibrary.org/audio/92022701",
                 "comName": "Bald Eagle",
                 "countryCode": "US",
                 "countryName": "United States",
                 "createDt": "2020-12-02T18:03:02.057",
                 "createQueued": 1,
                 "cutLength": 28536,
                 "digitizeDt": "2020-11-17T00:00:00",
                 "digitizeUserId": "USER16990",
                 "ebirdChecklistUrl": "https://ebird.org/ebird/view/checklist/S44087605",
                 "ebirdSpeciesUrl": "https://ebird.org/species/baleag",
                 "hasAgeSexData": false,
                 "lastEditedDt": "2024-06-15T22:53:59.216701",
                 "latitude": 28.2299949,
                 "licenseId": "LICENSE4",
                 "locId": "L857180",
                 "locName": "River Lakes Conservation Area--Moccasin Island",
                 "longitude": -80.8110523,
                 "mediaEditDt": "2020-11-17T00:00:00",
                 "mediaEditUserId": "USER16990",
                 "mediaFileName": "Bald Eagle Q4 C US-FL-009 ML92022701 Edit.wav",
                 "mediaFileSize": 1,
                 "mimeType": "audio/wav",
                 "mlBaseDownloadUrl": "https://cdn.download.ams.birds.cornell.edu/api/v1/asset/",
                 "obsDay": 30,
                 "obsDt": "2018-03-30",
                 "obsDtDisplay": "30 Mar 2018",
                 "obsMonth": 3,
                 "obsReviewed": false,
                 "obsValid": true,
                 "obsYear": 2018,
                 "parentAssetId": 92022701,
                 "parentAssetRestricted": false,
                 "projId": "ML",
                 "projectId": 1000043,
                 "quality": 3,
                 "ratingAverage": 3.0,
                 "ratingCount": 4,
                 "ratingRank": 2.5733333333333333,
                 "renditionTypes": ["audio", "poster", "spectrogram_small"],
                 "sciName": "Haliaeetus leucocephalus",
                 "source": "ml",
                 "speciesCode": "baleag",
                 "subId": "S44087605",
                 "subjects": [{
                     "speciesCode": "baleag",
                     "subjectTagCodes": ["call"]
                 }],
                 "subnational1Code": "US-FL",
                 "subnational1Name": "Florida",
                 "subnational2Code": "US-FL-009",
                 "subnational2Name": "Brevard",
                 "taxonCategoryCode": "species",
                 "taxonReportAs": "baleag",
                 "taxonomicSort": 8187.0,
                 "userDisplayName": "Paul Marvin",
                 "userId": "USER640979"
 }
 
 "asset": {
                 "ageSex": {
                     "juvenileUnknownCount": 1
                 },
                 "assetFormatCode": "photo",
                 "assetId": 306062831,
                 "assetRestricted": false,
                 "assetReviewed": false,
                 "assetState": "committed",
                 "assetTagCodes": ["flying_flight"],
                 "assetValid": true,
                 "citable": true,
                 "citationName": "ML 255379201",
                 "citationUrl": "https://macaulaylibrary.org/photo/255379201",
                 "comName": "Bald Eagle",
                 "countryCode": "US",
                 "countryName": "United States",
                 "createDt": "2020-08-13T20:38:53",
                 "createQueued": 1,
                 "ebirdChecklistUrl": "https://ebird.org/ebird/view/checklist/S72372921",
                 "ebirdSpeciesUrl": "https://ebird.org/species/baleag",
                 "groupId": "G5618064",
                 "hasAgeSexData": true,
                 "lastEditedDt": "2024-04-28T22:47:13.358345",
                 "latitude": 41.7642459,
                 "licenseId": "LICENSE4",
                 "locId": "L612903",
                 "locName": "Erie Marsh Preserve/Gun Club (no access Sep 1-Dec 15)",
                 "longitude": -83.4719821,
                 "mediaFileName": "127A3865.jpg",
                 "mediaFileSize": 257992,
                 "mimeType": "image/jpeg",
                 "mlBaseDownloadUrl": "https://cdn.download.ams.birds.cornell.edu/api/v1/asset/",
                 "obsDay": 13,
                 "obsDt": "2020-08-13T10:13",
                 "obsDtDisplay": "13 Aug 2020",
                 "subId": "OBS967491788",
                 "obsMonth": 8,
                 "obsReviewed": false,
                 "obsTime": 1013,
                 "obsValid": true,
                 "obsYear": 2020,
                 "parentAssetId": 255379201,
                 "parentAssetRestricted": false,
                 "ratingAverage": 4.111111111111111,
                 "ratingCount": 27,
                 "ratingRank": 3.62269366222544,
                 "renditionTypes": ["160", "320", "480", "640", "900", "1200", "1800", "2400"],
                 "sciName": "Haliaeetus leucocephalus",
                 "source": "bna",
                 "speciesCode": "baleag",
                 "subId": "S72372921",
                 "subjects": [{
                     "speciesCode": "baleag",
                     "subjectTagCodes": ["flying_flight"]
                 }],
                 "subnational1Code": "US-MI",
                 "subnational1Name": "Michigan",
                 "subnational2Code": "US-MI-115",
                 "subnational2Name": "Monroe",
                 "taxonCategoryCode": "species",
                 "taxonReportAs": "baleag",
                 "taxonomicSort": 8187.0,
                 "updateUserId": "USER789364",
                 "userDisplayName": "Benjamin Hack",
                 "userId": "USER789364"
             },
             "caption": "Juveniles have a brown body with brown and white mottled wings. The tail is also mottled with a dark band at the tip.",
             "captionLocale": "en",
             "captionsMap": {
                 "en": {
                     "localeCode": "en",
                     "localeText": "Juveniles have a brown body with brown and white mottled wings. The tail is also mottled with a dark band at the tip."
                 }
             },
             "displayOrder": 2,
             "title": "Juvenile",
             "titleLocale": "en",
             "titlesMap": {
                 "af": {
                     "localeCode": "af",
                     "localeText": "Juvenile"
                 },
                 "da": {
                     "localeCode": "da",
                     "localeText": "Juvenil"
                 },
                 "de": {
                     "localeCode": "de",
                     "localeText": "juvenil"
                 },
                 "en": {
                     "localeCode": "en",
                     "localeText": "Juvenile"
                 },
                 "es": {
                     "localeCode": "es",
                     "localeText": "Juvenil"
                 },
                 "fr": {
                     "localeCode": "fr",
                     "localeText": "Juvénile"
                 },
                 "he": {
                     "localeCode": "he",
                     "localeText": "צעיר"
                 },
                 "id": {
                     "localeCode": "id",
                     "localeText": "Juvenil"
                 },
                 "ja": {
                     "localeCode": "ja",
                     "localeText": "幼鳥"
                 },
                 "ko": {
                     "localeCode": "ko",
                     "localeText": "어린새"
                 },
                 "ml": {
                     "localeCode": "ml",
                     "localeText": "Juvenile"
                 },
                 "mr": {
                     "localeCode": "mr",
                     "localeText": "Juvenile"
                 },
                 "pt": {
                     "localeCode": "pt",
                     "localeText": "Juvenil"
                 },
                 "ru": {
                     "localeCode": "ru",
                     "localeText": "Молодая птица"
                 },
                 "th": {
                     "localeCode": "th",
                     "localeText": "นกเด็ก"
                 },
                 "tr": {
                     "localeCode": "tr",
                     "localeText": "genç"
                 },
                 "uk": {
                     "localeCode": "uk",
                     "localeText": "Ювенільний птах"
                 },
                 "zh": {
                     "localeCode": "zh",
                     "localeText": "幼鳥"
                 },
                 "zu": {
                     "localeCode": "zu",
                     "localeText": "Esencane"
                 },
                 "zh_CN": {
                     "localeCode": "zh_CN",
                     "localeText": "幼鸟"
                 }
             }
         }, {
             "asset": {
                 "ageSex": {},
                 "assetFormatCode": "photo",
                 "assetId": 306063031,
                 "assetRestricted": false,
                 "assetReviewed": true,
                 "assetState": "committed",
                 "assetValid": true,
                 "citable": true,
                 "citationName": "ML 143694961",
                 "citationUrl": "https://macaulaylibrary.org/photo/143694961",
                 "comName": "Bald Eagle",
                 "countryCode": "US",
                 "countryName": "United States",
                 "createDt": "2019-03-04T09:58:21",
                 "createQueued": 1,
                 "ebirdChecklistUrl": "https://ebird.org/ebird/view/checklist/S52314531",
                 "ebirdSpeciesUrl": "https://ebird.org/species/baleag",
                 "groupId": "G3822514",
                 "hasAgeSexData": false,
                 "lastEditedDt": "2022-07-02T17:47:12.33178",
                 "latitude": 42.549821,
                 "licenseId": "LICENSE4",
                 "locId": "L8546048",
                 "locName": "199 River Rd, Deerfield US-MA (42.5498,-72.5621)",
                 "longitude": -72.562109,
                 "mediaFileName": "LY2A0856.jpg",
                 "mediaFileSize": 5185447,
                 "mimeType": "image/jpeg",
                 "mlBaseDownloadUrl": "https://cdn.download.ams.birds.cornell.edu/api/v1/asset/",
                 "obsComments": "*high. Careful single scan count. Possibly a 9th. All imm",
                 "obsDay": 2,
                 "obsDt": "2019-02-02T11:08",
                 "obsDtDisplay": "02 Feb 2019",
                 "subId": "OBS705921647",
                 "obsMonth": 2,
                 "obsReviewed": true,
                 "obsTime": 1108,
                 "obsValid": true,
                 "obsYear": 2019,
                 "parentAssetId": 143694961,
                 "parentAssetRestricted": false,
                 "ratingAverage": 4.793103448275862,
                 "ratingCount": 29,
                 "ratingRank": 4.293360545786059,
                 "renditionTypes": ["160", "320", "480", "640", "900", "1200", "1800", "2400"],
                 "sciName": "Haliaeetus leucocephalus",
                 "source": "bna",
                 "speciesCode": "baleag",
                 "subId": "S52314531",
                 "subjects": [{
                     "speciesCode": "baleag"
                 }],
                 "subnational1Code": "US-MA",
                 "subnational1Name": "Massachusetts",
                 "subnational2Code": "US-MA-011",
                 "subnational2Name": "Franklin",
                 "taxonCategoryCode": "species",
                 "taxonReportAs": "baleag",
                 "taxonomicSort": 8187.0,
                 "updateUserId": "USER1056900",
                 "userDisplayName": "Jonathan Eckerson",
                 "userId": "USER532483"
             }
 */
