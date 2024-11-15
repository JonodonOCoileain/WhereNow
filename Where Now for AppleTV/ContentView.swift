//
//  ContentView.swift
//  Where Now for AppleTV
//
//  Created by Jon on 11/15/24.
//

import SwiftUI

struct WhereNowTV: View {
    let reversePadding = false

    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel = LocationDataModel()
    @ObservedObject var weatherData: USAWeatherService = USAWeatherService()
    @ObservedObject var birdData: BirdSightingService = BirdSightingService()
    let timer = Timer.publish(every: WhereNowTV.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            TabView {
                LocationViewTab(locationData: data)
                .tabItem {
                    Label("Here Now!", systemImage: "mappin.and.ellipse")
                }
                
                BirdSightingsViews(birdData: birdData, locationData: data, briefing: birdData.birdSeenCommonDescription ?? "")
                    .tabItem {
                        Label("Hear Now!", systemImage: "bird")
                    }
                
                WeatherViewTab(weatherData: weatherData)
                .tabItem {
                    Label("Weather Now!", systemImage: "sun.min")
                }
            }
            .padding([.top, .bottom], reversePadding ? -25 : 0)
            .onReceive(timer) { input in
                if timeCounter >= 2.0 {
                    timeCounter = 0
                }
                timeCounter = timeCounter + WhereNowTV.countTime * 2
            }
            .onAppear() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                    let locationCoordinate = data.currentLocation.coordinate
                    weatherData.cacheForecasts(using: locationCoordinate)
                    birdData.cacheSightings(using: locationCoordinate)
                    birdData.cacheNotableSightings(using: locationCoordinate)
                })
            }
            
        }
    }
}

#Preview {
    WhereNowTV()
}
