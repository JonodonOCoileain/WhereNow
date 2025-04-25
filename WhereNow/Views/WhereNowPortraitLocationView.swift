//
//  WhereNowPortraitLocationView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//
import SwiftUI
import MapKit

struct WhereNowPortraitLocationView: View {
#if os(watchOS)
    let reversePadding = true
#else
    let reversePadding = false
#endif
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var birdData: BirdSightingService
    
    var body: some View {
        ScrollView() {
            VStack {
                Text(self.locationData.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                    .multilineTextAlignment(.center)
                if let coordinate = locationData.currentLocation?.coordinate {
                    Map() {
                        Marker("Here", coordinate: coordinate)
                        
                        ForEach(self.birdData.sightings) { sighting in
                            if let lat = sighting.lat, let lng = sighting.lng {
                                Marker(sighting.comName ?? "bird", systemImage: "bird.fill", coordinate: CLLocationCoordinate2D(latitude: Double(lat), longitude: Double(lng)))
                            }
                        }
                    }.frame(minHeight: 300)
                }
            }
        }
    }
}
