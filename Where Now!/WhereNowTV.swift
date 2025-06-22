//
//  ContentView.swift
//  Where Now for AppleTV
//
//  Created by Jon on 11/15/24.
//

import SwiftUI
import CoreLocation

struct WhereNowTV: View {
    let reversePadding = false
    static var countTime:Double = 0.1
    let locationManager: LocationManager = LocationManager(locationStorageManager: UserDefaults.standard)
    @StateObject var locationData: LocationDataModel = LocationDataModel()
    @StateObject var weatherData: USAWeatherService = USAWeatherService()
    @StateObject var birdData: BirdSightingService = BirdSightingService()
    let timer = Timer.publish(every: WhereNowTV.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0
    @State var addressInfo: String = "" {
        didSet {
            locationManager.locationFrom(address: self.addressInfo)
            
            if let locationCoordinate = locationData.immediateLocation()?.coordinate {
                weatherData.cacheForecasts(using: locationCoordinate)
                birdData.cacheSightings(using: locationCoordinate)
                birdData.cacheNotableSightings(using: locationCoordinate)
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                TabView {
                    LocationViewTab()
                        .tabItem {
                            Label("Here Now!", systemImage: "mappin.and.ellipse")
                        }
                    
                    TVBirdSightingsViews()
                        .tabItem {
                            Label("Hear Now!", systemImage: "bird")
                        }
                    
                    WeatherViewTab()
                        .tabItem {
                            Label("Weather Now!", systemImage: "sun.min")
                        }
                    
                    /*VStack {
                        Text("For location services, enter your location below:")
                        TextField("Location (exempli gratia: address)", text: $addressInfo).padding([.horizontal, .bottom])
                    }
                    .tabItem {
                        Label("Settings Now!", systemImage: "gear")
                    }*/
                }
                .padding([.top, .bottom], reversePadding ? -25 : 0)
                .onReceive(timer) { input in
                    if timeCounter >= 2.0 {
                        timeCounter = 0
                    }
                    timeCounter = timeCounter + WhereNowTV.countTime * 2
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        locationData.start()})
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        guard let locationCoordinate = locationData.currentLocation?.coordinate else { return }
                        weatherData.cacheForecasts(using: locationCoordinate)
                        birdData.cacheSightings(using: locationCoordinate)
                        birdData.cacheNotableSightings(using: locationCoordinate)
                    })
                }
                .onDisappear {
                    locationData.stop()
                }
            }
        }
    }
}

struct TVBirdSightingsViews: View {
    @EnvironmentObject var birdData: BirdSightingService
    @EnvironmentObject var locationData: LocationDataModel
    let titleSize: CGFloat = 20
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Text("🦅 Especially Notable Bird Reports thanks to Cornell Lab of Ornithology and the Macauley Library.")
                    .multilineTextAlignment(.leading)
                    .frame(width: geometry.size.width)
                    .lineLimit(5)
                    .font(.system(size: titleSize))
                    .fixedSize(horizontal: true, vertical: false)
                HStack {
                    Text("Sightings search radius")
                        .font(.system(size: titleSize))
                        .multilineTextAlignment(.leading)
                        .padding([.vertical])
                        .lineLimit(3)
                    Picker(selection: $birdData.searchRadius, label: Text("Sightings search radius")
                        .font(.system(size: titleSize))
                        .multilineTextAlignment(.leading)
                        .padding([.vertical]))
                                        {
                                            ForEach(0 ..< BirdSightingsViews.Distance.count) {
                                                index in Text("\(BirdSightingsViews.Distance[index])").tag(BirdSightingsViews.Distance[index])
                                            }
                                        }
                }
                ScrollView(.vertical) {
                    VStack(alignment: .center, content: {
                        ForEach(birdData.notableSightings.enumeratedArray(), id: \.element) { index, sighting in
                            #if os(tvOS)
                            TVOSBirdSightingView(index: index, sighting: sighting, notables: true)
                                .frame(width: geometry.size.width - 100)
                            #else
                            BirdSightingView(index: index, sighting: sighting, notables: true)
                                .frame(width: geometry.size.width - 100)
                            #endif
                        }
                    })
                    .frame(minWidth: 100, maxWidth: geometry.size.width - 100, minHeight: 250)
                }
                .frame(minWidth: 100, maxWidth: geometry.size.width - 100)
            }
            .onAppear() {
                print("NotableBirdSightingsViews appeared")
            }
        }
    }
}

public struct TVBirdSightingView: View {
    private let flexible = [
        GridItem(.flexible(minimum: 100, maximum: 220)),
        GridItem(.flexible(minimum: 100, maximum: 220))
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
    @ObservedObject var birdData: BirdSightingService
    private let titleSize: CGFloat = 11
    private let descriptionSize: CGFloat = 12
    private let smallSize: CGFloat = 6
    @State var coordinate: CLLocationCoordinate2D?
    @State var notables: Bool? = false
    @State var relatedData: [BirdSpeciesAssetMetadata] = []
    
    public var body: some View {
        VStack(alignment: .leading) {
            let photosData = relatedData.filter({$0.assetFormatCode == "photo"})
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
                                .frame(width: 100, height: 100)
                            }
                            Text(imageData.uploadedBy.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: " ", with: "\n"))
                                .lineLimit(2)
                                .font(.system(size: smallSize))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(width: 200, height: 200)
                        .clipped()
                        .onTapGesture {
                            selectedDetailTitle = sighting.sciName
                            selectedDetailSubtitle = sighting.comName
                            selectedBirdData = imageData
                            isPresented.toggle()
                        }
                    }
                })
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
                Text("In \(locationPrivate ? "private" : "public") location")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            //Audio files
            if relatedData.count > 0 {
                ScrollView(.horizontal) {
                    LazyHGrid(rows: flexible) {
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


#Preview {
    WhereNowTV()
}
