//
//  BirdSightingView.swift
//  WhereNow
//
//  Created by Jonathan Lavallee Collins on 3/21/25.
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
import OSLog

public struct BirdSightingView: View, Identifiable {
    public let id = UUID()
    public let index: Int
    @State private var isPresented: Bool = false
    @State private var selectedDetailTitle: String?
    @State private var selectedDetailSubtitle: String?
    @State private var selectedBirdData: BirdSpeciesAssetMetadata?
    #if os(iOS) || os(macOS) || os(tvOS)
    @State var route: IdentifiableRoute?
    @State var transport: MKDirectionsTransportType? = nil
    @State var routeDestination: CLLocationCoordinate2D?
    #else
    @State var route: String?
    #endif
    @ObservedObject var player = PlayerViewModel()
    @State var sighting: BirdSighting
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var birdData: BirdSightingService
    #if os(tvOS)
    private let titleSize: CGFloat = 11
    private let descriptionSize: CGFloat = 36
    #else
    private let titleSize: CGFloat = 11
    private let descriptionSize: CGFloat = 12
    #endif
    @State var coordinate: CLLocationCoordinate2D?
    @State var notables: Bool? = false
    @State var relatedData: [BirdSpeciesAssetMetadata] = []
    public var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                
                HStack {
                    if let commonName = sighting.comName {
                        Text(commonName + ",")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    if let name = sighting.sciName {
                        Text(name)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    Spacer()
                }.padding([.top, .bottom])
                
                let photosData = relatedData.filter({$0.assetFormatCode == "photo"})
                if photosData.count > 0 {
                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .center) {
                            ForEach(photosData, id: \.self) { imageData in
                                Button(action: {
                                    selectedDetailTitle = sighting.sciName
                                    selectedDetailSubtitle = sighting.comName
                                    selectedBirdData = imageData
                                    isPresented.toggle()
                                }, label: {
                                    VStack {
                                        if let URL = URL(string: imageData.url) {
                                            ZStack {
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
                                        }
#if os(iOS) || os(macOS) || os(tvOS)
                                        Text("Uploaded by:")
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                        Text(imageData.uploadedBy.replacingOccurrences(of: "\"", with: ""))
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
#endif
                                        
                                    }
                                })
                            }
                        }
                    }
                } else {
                    Text(Fun.eBirdjis.randomElement() ?? "")
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                }
                
                //Audio files
                let audioData = relatedData.filter({$0.assetFormatCode == "audio"})
                if audioData.count > 0 {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(audioData.filter({ $0.comName == sighting.comName }).filter({ $0.sciName == sighting.sciName })) { key in
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
                                            .buttonStyle(.automatic)
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
                
                if let location = sighting.locName?.replacingOccurrences(of: "--", with: ", ").replacingOccurrences(of: "-", with: " ") {
#if os(iOS) || os(macOS)
                    HStack(alignment: .center, spacing: 20) {
                        Button(action: {
                            if let coordinate = coordinate {
                                self.route = nil
                                guard let startingPoint = locationData.immediateLocation()?.coordinate else { return }
                                let request = MKDirections.Request()
                                request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
                                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                                request.transportType = .walking
                                transport = .walking
                                routeDestination = coordinate
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
                            } else if let locName = sighting.locName?.replacingOccurrences(of: "--", with: ", ").replacingOccurrences(of: "-", with: " "), let startingPoint = locationData.immediateLocation()?.coordinate, let url = URL(string:
                                                                                                                                                                                                                "https://www.google.co.in/maps/dir/\(startingPoint.latitude),\(startingPoint.longitude)/\(locName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")/") {
                                UIApplication.shared.open(url)
                            }
                        }, label: {
                            Text("Location: " + location + " 🚶🏿‍♀️")
                                .font(.system(size: descriptionSize))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .foregroundColor(UIDevice.current.systemName == "watchOS" ? .primary : .purple)
                            
                        })
                        
                        Button(action: {
                            if let locName = sighting.locName?.replacingOccurrences(of: "-", with: " "), let coordinate = coordinate {
                                
                                self.route = nil
                                
                                // Coordinate to use as a starting point for the example
                                guard let startingPoint = locationData.immediateLocation()?.coordinate else { return }
                                
                                // Create and configure the request
                                let request = MKDirections.Request()
                                request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
                                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                                request.transportType = .automobile
                                transport = .automobile
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
                            } else if let locName = sighting.locName?.replacingOccurrences(of: "-", with: " "), let startingPoint = locationData.immediateLocation()?.coordinate, let url = URL(string:
                                                                                                                                                                    "https://www.google.co.in/maps/dir/\(startingPoint.latitude),\(startingPoint.longitude)/\(locName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")/") {
                                UIApplication.shared.open(url)
                            }
                        }, label: {
                            Text("Driving directions 🚗")
                                .font(.system(size: descriptionSize))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .foregroundColor(UIDevice.current.systemName == "watchOS" ? .primary : .red)
                        })
                    }
                    .sheet(item: $route, content: { route in
                        FullScreenModalDirectionsView(destination: routeDestination ?? CLLocationCoordinate2D(), transport: $transport.wrappedValue ?? .walking, route: route, newRoute: route, sighting: sighting, locationData: locationData)
                    })
#else
                    Text("Location: " + location)
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
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
                    Text("In \(locationPrivate ? "private" : "public") location")
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
#if  os(iOS) || os(macOS)
                HStack {
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
                }
#endif
            }
            .sheet(item: $selectedBirdData, content: { data in
                FullScreenModalView(data: data)
            })
            .task(id: sighting.id) {
                if let locName = sighting.locName {
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.05, execute: {
                        LocationDataModel.getCoordinate(addressString: locName, lat: sighting.lat, lng: sighting.lng) { coordinate, error in
                            if let error = error {
                                print(error.localizedDescription)
                                return
                            } else {
                                self.coordinate = coordinate
                            }}
                    })
                }
                
                if let speciesCode = sighting.speciesCode, self.relatedData.count == 0 {
                    do {
                        self.relatedData = try await birdData.asyncRequestWebsiteAssetMetadataO(speciesCode: speciesCode, comName: sighting.comName ?? "", sciName: sighting.sciName ?? "", subId: sighting.subId ?? "")
                    } catch {
                        print("error")
                    }
                }
            }
                
    }
}
