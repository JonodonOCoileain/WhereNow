//
//  WhereNowPortraitView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//

import SwiftUI
import MapKit

struct WhereNowPortraitView: View {
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var weatherData: USAWeatherService
    @EnvironmentObject var birdData: BirdSightingService
    
    let timer = Timer.publish(every: WhereNowView.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0
    
    @State var showLocation: Bool = true
    @State var showLocationTime: Double = Date().timeIntervalSince1970
    @State var hideLocationTime: Double = 0.0
    @State var showBirdData: Bool = true
    @State var showBirdDataTime: Double = Date().timeIntervalSince1970
    @State var hideBirdDataTime: Double = 0.0
    @State var showWeatherData: Bool = true
    @State var showWeatherDataTime: Double = Date().timeIntervalSince1970
    @State var hideWeatherDataTime: Double = 0.0
    @State var appNameTapped: Bool = false
    
    private let smallFont: Font = .system(size: 20)
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if !locationData.addressInfoIsUpdated {
                    Image("LOCATION")
                        .resizable(resizingMode: .stretch)
                        .frame(width: 7, height: 7)
                        .scaledToFit()
                        .opacity(locationData.addressInfoIsUpdated ? 0 : 1-timeCounter)
                }
                
                ScrollView() {
                    LazyVStack {
#if os(watchOS)
                        Text("WHERE NOW!")
                            .font(smallFont)
                            .modifier(UpdatedSpinnable(tapToggler: $appNameTapped, tapActionNotification: ""))
#endif
                        Group {
                            if birdData.birdSeenCommonDescription != nil {
                                HeaderView(isPresenting: $showBirdData, showTimeTracker: $showBirdDataTime,  hideTimeTracker: $hideBirdDataTime, title: "Hear now!")
                                BirdSightingsViews()
                                    .frame(minHeight: showBirdData ? 700 : 0, maxHeight: showBirdData ? 1000 : 0)
                                    .scaleEffect(showBirdData ? 1 : 0)
                                    .animation(.easeInOut, value: showBirdData)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Group {
                            HeaderView(isPresenting: $showLocation, showTimeTracker: $showLocationTime,  hideTimeTracker: $hideLocationTime, title: "Here now!")
                                .frame(maxWidth: .infinity)
                            
                            VStack {
                                Text(self.locationData.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                                    .multilineTextAlignment(.center)
                                if let coordinate = locationData.currentLocation?.coordinate {
                                    Map {
                                        Marker("Here", coordinate: coordinate)
                                    }
                                }
                            }
                            .scaleEffect(showLocation ? 1 : 0)
                            .offset(y: hideLocationTime > showLocationTime ? -200 * (Date().timeIntervalSince1970 - hideLocationTime)/0.35 : (hideLocationTime < showLocationTime && showLocationTime >= 0.35+Date().timeIntervalSince1970  ? -10 * (showLocationTime - Date().timeIntervalSince1970)/0.35 : 0))
                            .frame(maxHeight: showLocationTime < Date().timeIntervalSince1970 - 0.35 && showLocationTime > hideLocationTime ? .infinity : Date().timeIntervalSince1970 > hideLocationTime + 0.35 && hideLocationTime > showLocationTime ? 0 : Date().timeIntervalSince1970 < hideLocationTime + 0.35 && Date().timeIntervalSince1970 > hideLocationTime ? 500 * (Date().timeIntervalSince1970 - hideLocationTime)/0.35 : .infinity)
                            .animation(.easeInOut, value: showLocation)
                        }
                        
                        Group {
                            HeaderView(isPresenting: $showWeatherData, showTimeTracker: $showWeatherDataTime,  hideTimeTracker: $hideWeatherDataTime, title: String.weatherNowTitle, spinningText: String.andLaterTitle)
                            VStack(alignment:.center) {
                                ForEach(weatherData.timesAndForecasts, id: \.self) { element in
                                    VStack(alignment:.center) {
                                        Text(Fun.emojis.randomElement() ?? "")
                                            .font(.title)
                                            .multilineTextAlignment(.center)
                                        Text(element.name ?? "")
                                            .font(.subheadline)
                                            .padding([.leading, .trailing])
                                            .multilineTextAlignment(.center)
                                            .bold()
                                        Text(element.forecast)
                                            .font(.subheadline)
                                            .padding([.leading, .trailing, .bottom])
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                
                                Text("Weather data provided by the National Weather Service, part of the National Oceanic and Atmospheric Administration (NOAA)")
                                    .multilineTextAlignment(.center)
                                    .font(.caption2)
                                    .padding()
                                Text(weatherData.forecastOffice?.description() ?? "")
                                    .multilineTextAlignment(.center)
                                    .font(.caption2)
                            }
                            .scaleEffect(showWeatherData ? 1 : 0)
                            .animation(.easeInOut, value: showWeatherData)
                            .frame(maxHeight: showWeatherData ? .infinity : 0)
                        }
                    }
                }
                .onReceive(timer) { input in
                    if timeCounter >= 2.0 {
                        timeCounter = 0
                    }
                    timeCounter = timeCounter + WhereNowView.countTime * 2
                    
                }
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                        if let locationCoordinate = locationData.immediateLocation()?.coordinate {
                            weatherData.cacheForecasts(using: locationCoordinate)
                            birdData.cacheNotableSightings(using: locationCoordinate)
                        }
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                        if let locationCoordinate = locationData.immediateLocation()?.coordinate {
                            birdData.cacheSightings(using: locationCoordinate)
                        }
                    })
                }
            }
        }.animation(.default, value: 1)
    }
}
