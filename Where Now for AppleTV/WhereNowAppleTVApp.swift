//
//  Where_Now_for_AppleTVApp.swift
//  Where Now for AppleTV
//
//  Created by Jon on 11/15/24.
//

import SwiftUI

@main
struct Where_Now_for_AppleTVApp: App {
    @StateObject var locationData: LocationDataModel = LocationDataModel()
    @StateObject var weatherData: USAWeatherService = USAWeatherService()
    @StateObject var birdData: BirdSightingService = BirdSightingService()
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some Scene {
        WindowGroup {
            VStack {
                WhereNowTV()
                    .environment(locationData)
                    .environment(weatherData)
                    .environment(birdData)
                    .onAppear {
                        print("App appeared")
                    }
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                                    if newPhase == .active {
                                        print("Active")
                                        birdData.resetRequestHistory()
                                        birdData.sightings.removeAll()
                                        if let location = locationData.immediateLocation() {
                                            weatherData.cacheForecasts(using: location.coordinate)
                                            birdData.cacheNotableSightings(using: location.coordinate)
                                            birdData.cacheSightings(using: location.coordinate)
                                        }
                                    } else if newPhase == .inactive {
                                        print("Inactive")
                                        //self.birdData.resetData()
                                    } else if newPhase == .background {
                                        print("Background")
                                        //self.birdData.resetData()
                                    }
                    }
            }
        }
    }
}
