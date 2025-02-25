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
        GridItem(.flexible(minimum: 40, maximum: 120)),
        GridItem(.flexible(minimum: 40, maximum: 120))
    ]
    private let audio = [
        GridItem(.flexible(minimum: 40, maximum: 60)),
        GridItem(.flexible(minimum: 40, maximum: 60)),
        GridItem(.flexible(minimum: 40, maximum: 60))
    ]
    @State private var isPresented: Bool = false
    @State private var selectedDetailTitle: String?
    @State private var selectedDetailSubtitle: String?
    @State private var selectedBirdData: BirdSpeciesAssetMetadata?
    
    @State var route: String?
    @ObservedObject var player = PlayerViewModel()
    @State var sighting: BirdSighting
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var birdData: BirdSightingService
    private let titleSize: CGFloat = 14
    private let descriptionSize: CGFloat = 12
    private let smallSize: CGFloat = 7
    @State var coordinate: CLLocationCoordinate2D?
    @State var notables: Bool? = false
    let width: CGFloat
    @State var relatedData: [BirdSpeciesAssetMetadata] = []
    
    public var body: some View {
        VStack(alignment: .leading) {
            let photosData = relatedData.filter({$0.assetFormatCode == "photo"})
            Text("Sighting:")
                .font(.system(size: titleSize))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: width)
            if let commonName = sighting.comName {
                Text(commonName)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: width)
            }
            if let name = sighting.sciName {
                Text(name)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: width)
            }
            if let location = sighting.locName {
                Text("Location:")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: width)
                Text("\(location)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: width)
            }
            if let date = sighting.obsDt {
                Text("Date: " + date)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: width)
            }
            if let quantity = sighting.howMany {
                Text("Quantity: \(quantity)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: width)
            }
            if let userName = sighting.userDisplayName {
                Text("Seen by: \(userName)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: width)
            }
            if let locationPrivate = sighting.locationPrivate {
                Text(locationPrivate == true ? "In private location" : "In public location")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: width)
            }
            let audioData = relatedData.filter({$0.assetFormatCode == "audio"})
            
            if relatedData.count > 0 {
                Text("Relevant media:")
                    .font(.system(size: titleSize))
                    .padding(.top)
            }
            if photosData.count > 0 {
                Text("Photos")
                    .font(.system(size: descriptionSize))
                    .padding([.leading])
                    .frame(maxWidth: width)
                
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
                                .frame(maxWidth: width)
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
                .frame(width: width - 2, height: 100)
                .padding(.bottom)
            }
            //Audio files
            if audioData.count > 0 {
                    Text("Audio")
                        .font(.system(size: descriptionSize))
                        .padding([.leading])
                        .frame(maxWidth: width)
                    LazyVGrid(columns: audio, alignment: .center, spacing: 1) {
                        ForEach(audioData) { key in
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
                                Text(key.uploadedBy.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: " ", with: "\n"))
                                    .font(.system(size: smallSize))
                                    .lineLimit(5)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: width / 3)
                            })
                        }
                    }.frame(maxWidth: width)
            }
        }
        .frame(width: width - 3)
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
            
            
            let relatedData = birdData.speciesMedia.filter({ $0.speciesCode == sighting.speciesCode })
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
