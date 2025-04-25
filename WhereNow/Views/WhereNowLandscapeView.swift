//
//  WhereNowLandscapeView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//

import SwiftUI
import MapKit

struct WhereNowLandscapeView: View {
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var weatherData: USAWeatherService
    @EnvironmentObject var birdData: BirdSightingService
    
    @State var showLocation: Bool = true
    @State var showLocationTime: Double = 0.0
    @State var hideLocationTime: Double = 0.0
    @State var showBirdData: Bool = true
    @State var showBirdDataTime: Double = 0.0
    @State var hideBirdDataTime: Double = 0.0
    @State var showWeatherData: Bool = true
    @State var showWeatherDataTime: Double = 0.0
    @State var hideWeatherDataTime: Double = 0.0
    @State var tapViewSelected: Bool = false
    var body: some View {
        GeometryReader { geometry in
            VStack (alignment: .center) { Text("WHERE NOW!")
                    .padding([.bottom],10)
            ScrollView(.horizontal) {
                    HStack(alignment: .top) {
                        if birdData.birdSeenCommonDescription != nil {
                            VStack(spacing: 0) {
                                HeaderView(isPresenting: $showBirdData, showTimeTracker: $showBirdDataTime,  hideTimeTracker: $hideBirdDataTime, title: "Hear now!")
                                if $showBirdData.wrappedValue {
                                    BirdSightingsViews()
                                        .frame(minWidth: 500, minHeight: 700, maxHeight: 1000)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        VStack {
                            HeaderView(isPresenting: $showLocation, showTimeTracker: $showLocationTime,  hideTimeTracker: $hideLocationTime, title: "Here now!")
                            HStack {
                                if let coordinate = locationData.currentLocation?.coordinate {
                                    Map() {
                                        Marker("Here", systemImage: "location", coordinate: coordinate)
                                    }
                                    .scaleEffect(showLocation ? 1 : 0)
                                    .animation(.easeInOut, value: showLocation)
                                    .frame(width: 240, height: 240)
                                }
                                Text(self.locationData.addressesVeryLongFlag)
                                    .multilineTextAlignment(.center)
                                    .scaleEffect(showLocation ? 1 : 0)
                                    .animation(.easeInOut, value: showLocation)
                            }
                        }
                        
                        VStack {
                            HeaderView(isPresenting: $showWeatherData, showTimeTracker: $showWeatherDataTime,  hideTimeTracker: $hideWeatherDataTime, title: String.weatherNowTitle, spinningText: String.andLaterTitle)
                            VStack(alignment: .center) {
                                WhereNowWeatherHStackView(data: locationData, weatherData: weatherData)
                                
                                Text("Weather data provided by the National Weather Service, part of the National Oceanic and Atmospheric Administration (NOAA)")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                Text(weatherData.forecastOffice?.description() ?? "")
                                    .multilineTextAlignment(.center)
                                    .font(.caption2)
                            }
                            .scaleEffect(showWeatherData ? 1 : 0)
                            .animation(.easeInOut, value: showWeatherData)
                            .frame(maxWidth: showWeatherData ? .infinity : 0)
                        }
                    }
                }
            }
        }
    }
}
