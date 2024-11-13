//
//  BirdSightingView.swift
//  WhereNow
//
//  Created by Jon on 11/12/24.
//


import SwiftUI
import WidgetKit
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import MapKit

public struct WatchBirdSightingView: View {
    @State private var isPresented: Bool = false
    @State private var selectedDetailTitle: String?
    @State private var selectedDetailSubtitle: String?
    @State private var selectedBirdData: BirdSpeciesAssetMetadata?
    
    @State var route: String?
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
        NavigationView {
            VStack(alignment: .leading) {
                
                let relatedData = birdData.speciesMedia.filter({ $0.speciesCode == sighting.speciesCode })
                let photosData = relatedData.filter({$0.assetFormatCode == "photo"})
                if photosData.count > 0 {
                    LazyHStack(alignment: .center) {
                        ForEach(photosData, id: \.self) { imageData in
                            VStack {
                                if let URL = URL(string: imageData.url) {
                                    AsyncImage(url: URL) { result in
                                        result.image?
                                            .resizable()
                                            .scaledToFill()
                                    }
                                    .frame(width: 30, height: 30)
                                }
                            }
                            .clipped()
                            .onTapGesture {
                                print("Tapped")
                                
                            }
                            .onLongPressGesture(perform: {
                                selectedDetailTitle = sighting.sciName
                                selectedDetailSubtitle = sighting.comName
                                selectedBirdData = imageData
                                isPresented.toggle()
                            })
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
                if let location = sighting.locName {
                    Text("Location: \(location)")
                        .font(.system(size: descriptionSize))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
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
                if let userName = sighting.userDisplayName {
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

                //Audio files
                if relatedData.count > 0 {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(relatedData.filter({$0.assetFormatCode == "audio"})) { key in
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
                                            .frame(width: 10, height: 10)
                                            .clipShape(.rect(cornerRadius: 2))
                                        Text(key.uploadedBy.replacingOccurrences(of: "\"", with: ""))
                                            .font(.caption2)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(width: 50, height: 80)
                                })
                            }
                        }
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
}

public struct BirdSightingsHorizontalContainerView: View {
    @ObservedObject var birdData: BirdSightingService
    @ObservedObject var locationData: LocationDataModel
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    @State private var isFullScreen = false
    @State var notables: Bool? = false
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top) {
                    let sightings = notables == true ? birdData.notableSightings : birdData.sightings
                    ForEach(sightings, id: \.self) { sighting in
                        WatchBirdSightingView(sighting: sighting, locationData: locationData, currentLocation: locationData.currentLocation.coordinate, birdData: birdData, notables: notables)
                            .frame(width: geometry.size.width)
                    }
                }
            }.frame(width: geometry.size.width)
                .scrollTargetLayout()
                .scrollTargetBehavior(.paging)
        }
    }
}

struct NotableBirdSightingsViewsOnly: View {
    @ObservedObject var birdData: BirdSightingService
    @ObservedObject var locationData: LocationDataModel
    let briefing: String
    let titleSize: CGFloat = 11
    let smallSize: CGFloat = 6
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Text("🦅 Especially Notable Bird Reports thanks to Cornell Lab of Ornithology and the Macauley Library.")
                    .font(.system(size: smallSize))
                    .frame(width: geometry.size.width)
                    .lineLimit(2)
                BirdSightingsHorizontalContainerView(birdData: birdData, locationData: locationData, notables: true)
                    .scrollTargetBehavior(.paging)
                    .scrollTargetLayout()
                    .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width)
        }
        .scrollTargetLayout()
    }
}
