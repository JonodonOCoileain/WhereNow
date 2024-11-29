//
//  WhereNowView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//


import SwiftUI
import CoreLocation
import WidgetKit

struct WhereNowWatchView: View {
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var weatherData: USAWeatherService
    @EnvironmentObject var birdData: BirdSightingService
    @Environment(\.scenePhase) var scenePhase
    @State var tabViewSelected: Bool = true
    
    var body: some View {
        if ([CLAuthorizationStatus.restricted, CLAuthorizationStatus.denied].contains(where: {$0 == locationData.manager.authorizationStatus})) {
            LocationAccessDisabledView()
        } else {
                WhereNowWatchPortraitView()
            .animation(.default, value: 1)
            .task {
                if let immediateLocation = locationData.immediateLocation()?.coordinate {
                    weatherData.cacheForecasts(using: immediateLocation)
                    await birdData.asyncCacheSightings(using: immediateLocation)
                    await birdData.asyncCacheNotableSightings(using: immediateLocation)
                }
            }
            .onDisappear() {
                WidgetCenter.shared.reloadAllTimelines()
            }
            .alert(isPresented: self.$locationData.deniedStatus) {
                Alert(title: Text("Location permissions required"), message: Text("This app is about where you are! Please allow location access."), dismissButton: .default(Text("Dimiss"), action: nil))
            }
        }
    }
}
