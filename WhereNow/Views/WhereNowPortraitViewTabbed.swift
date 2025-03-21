//
//  WhereNowPortraitViewTabbed.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//

import SwiftUI

struct WhereNowPortraitViewTabbed: View {
#if os(watchOS)
    let reversePadding = true
#else
    let reversePadding = false
#endif
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var weatherData: USAWeatherService
    @EnvironmentObject var birdData: BirdSightingService
    
    let timer = Timer.publish(every: WhereNowView.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0
    
    var body: some View {
        TabView {
            BirdSightingsViews()
                .tabItem {
                    Label("Hear Now!", systemImage: "bird")
                }
                .accessibilityIdentifier("Hear Now!")
            
            LocationViewTab()
                .tabItem {
                    Label("Here Now!", systemImage: "mappin.and.ellipse")
                }
                .accessibilityIdentifier("Here Now!")
            
            WeatherViewTab()
                .tabItem {
                    Label("Weather Now!", systemImage: "sun.min")
                }
                .accessibilityIdentifier("Weather Now!")
            
            GameView()
                .tabItem {
                    Label("Game Now!", systemImage: "gamecontroller")
                }
                .accessibilityIdentifier("Game Now!")
        }
        .accessibilityIdentifier("Tab View")
        .padding([.top, .bottom], reversePadding ? -25 : 0)
        .onReceive(timer) { input in
            if timeCounter >= 2.0 {
                timeCounter = 0
            }
            timeCounter = timeCounter + WhereNowView.countTime * 2
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                if let locationCoordinate = locationData.currentLocation?.coordinate {
                    weatherData.cacheForecasts(using: locationCoordinate)
                    birdData.cacheNotableSightings(using: locationCoordinate)
                }
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                if let locationCoordinate = locationData.currentLocation?.coordinate {
                    birdData.cacheSightings(using: locationCoordinate)
                }
            })
        }
    }
}
