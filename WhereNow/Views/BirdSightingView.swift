
public struct BirdSightingView: View {
    @State private var isPresented: Bool = false
    @State private var selectedDetailTitle: String?
    @State private var selectedDetailSubtitle: String?
    @State private var selectedBirdData: BirdSpeciesAssetMetadata?
    #if os(iOS)
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
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                let relatedData = birdData.speciesMedia.filter({ $0.speciesCode == sighting.speciesCode })
                let photosData = relatedData.filter({$0.assetFormatCode == "photo"})
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
#if os(watchOS)
#else
                                    Text("Uploaded by:")
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                    Text(imageData.uploadedBy)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
#endif
                                    
                                }
                                .onTapGesture {
                                    print("Tapped")
#if os(iOS)
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
                if let location = sighting.locName {
                    VStack {
#if os(iOS)
                        Text("Location: " + location)
                            .font(.system(size: descriptionSize))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .foregroundColor(UIDevice.current.systemName == "iOS" ? .blue : .primary)
#if os(iOS)
                            .onTapGesture(perform: {
                                if let locName = sighting.locName?.replacingOccurrences(of: "-", with: " "), let coordinate = coordinate {
                                    
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
                                } else if let locName = sighting.locName?.replacingOccurrences(of: "-", with: " "), let startingPoint = currentLocation, let url = URL(string:
                                                                                                                                "https://www.google.co.in/maps/dir/\(startingPoint.latitude),\(startingPoint.longitude)/\(locName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")/") {
                                    UIApplication.shared.open(url)
                                }
                            })
                            .onLongPressGesture(perform: {
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
#endif
#else
                        Text("Location: " + location)
                            .font(.system(size: descriptionSize))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
#endif
                    }
#if os(iOS)
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
#if os(watchOS)
#else
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
#if os(watchOS)
                                            .frame(width: 20, height: 20)
                                            .clipShape(.rect(cornerRadius: 4))
                                            .buttonStyle(.bordered)
#else
                                            .frame(width: 64, height: 64)
                                            .clipShape(.rect(cornerRadius: 8))
                                            .buttonStyle(.borderedProminent)
#endif
#if os(watchOS)
                                        Text(key.uploadedBy)
                                            .font(.extraSmall)
                                            .multilineTextAlignment(.center)
#else
                                        Text("Uploaded by:")
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                        Text(key.uploadedBy)
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                        #endif
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
        .padding()
    }
}
