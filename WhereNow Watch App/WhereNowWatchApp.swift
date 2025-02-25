//
//  WhereNowApp.swift
//  WhereNow Watch App
//
//  Created by Jon on 7/17/24.
//

import SwiftUI

@main
struct WhereNow_Watch_App: App {
    @StateObject var locationData: LocationDataModel = LocationDataModel()
    @StateObject var weatherData: USAWeatherService = USAWeatherService()
    @StateObject var birdData: BirdSightingService = BirdSightingService()
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some Scene {
        WindowGroup {
            WhereNowWatchView()
                .environment(locationData)
                .environment(weatherData)
                .environment(birdData)
                .onAppear {
                    print("App appeared")
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                                if newPhase == .active {
                                    DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.01, execute: {
                                        locationData.start()})
                                    print("Active")
                                   
                                    birdData.resetRequestHistory()
                                    birdData.sightings.removeAll()
                                    if let location = locationData.immediateLocation() {
                                        weatherData.cacheForecasts(using: location.coordinate)
                                        birdData.cacheNotableSightings(using: location.coordinate)
                                        #if os(tvOS) || os(macOS) || os(iOS)
                                        birdData.cacheSightings(using: location.coordinate)
                                        #endif
                                    }
                                } else if newPhase == .inactive {
                                    print("Inactive")
                                    locationData.stop()
                                    self.birdData.resetMetadata()
                                    self.birdData.resetRequestHistory()
                                    self.birdData.resetData()
                                    self.weatherData.timesAndForecasts = []
                                } else if newPhase == .background {
                                    print("Background")
                                    locationData.stop()
                                    self.birdData.resetMetadata()
                                    self.birdData.resetRequestHistory()
                                    self.weatherData.timesAndForecasts = []
                                } else {
                                    locationData.start()
                                }
                }
        }
    }
}
