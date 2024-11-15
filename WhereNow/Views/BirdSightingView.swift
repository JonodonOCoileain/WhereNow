//
//  BirdSightingView.swift
//  WhereNow
//
//  Created by Jon on 11/12/24.
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

public struct WatchBirdSightingView: View {
    private let flexible = [
        GridItem(.flexible(minimum: 30, maximum: 120)),
        GridItem(.flexible(minimum: 30, maximum: 120))
    ]
    let geometry: GeometryProxy
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
    private let smallSize: CGFloat = 6
    @State var coordinate: CLLocationCoordinate2D?
    @State var notables: Bool? = false
    public var body: some View {
        VStack(alignment: .leading) {
            let relatedData = birdData.speciesMedia.filter({ $0.speciesCode == sighting.speciesCode })
            let photosData = relatedData.filter({$0.assetFormatCode == "photo"}).filter({ $0.comName == sighting.comName }).filter({ $0.sciName == sighting.sciName })
            if photosData.count > 0 {
                LazyHGrid(rows: flexible, alignment: .top, spacing: 4, content: {
                    ForEach(photosData, id: \.self) { imageData in
                        VStack {
                            if let URL = URL(string: imageData.url) {
                                AsyncImage(url: URL) { result in
                                    result.image?
                                        .resizable()
                                        .scaledToFill()
                                }
                                .frame(width: 28, height: 28)
                            }
                            Text(imageData.uploadedBy.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: " ", with: "\n"))
                                .lineLimit(2)
                                .font(.system(size: smallSize))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .clipped()
                        .onTapGesture {
                            selectedDetailTitle = sighting.sciName
                            selectedDetailSubtitle = sighting.comName
                            selectedBirdData = imageData
                            isPresented.toggle()
                        }
                    }
                })
                .frame(width: geometry.size.width - 4, height: 90)
                .padding(.bottom)
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
                    LazyHGrid(rows: flexible) {
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
                                    Image(systemName: "play.circle")
                                        .frame(width: 4, height: 4)
                                    Text(key.uploadedBy.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: " ", with: "\n"))
                                        .font(.system(size: smallSize))
                                        .lineLimit(3)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 15, height: 15)
                            })
                        }
                    }
                }.frame(minWidth: geometry.size.width - 4, minHeight: 20, maxHeight: 40)
            }
            Spacer()
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
