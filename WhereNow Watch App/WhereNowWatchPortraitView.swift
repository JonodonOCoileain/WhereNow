//
//  WhereNowPortraitView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//



import SwiftUI

struct LocationAccessDisabledWatchView: View {
    static var countTime:Double = 0.1
    
    let timer = Timer.publish(every: WhereNowWatchView.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0
    
    var body: some View {
        Image("LOCATION")
            .resizable(resizingMode: .stretch)
            .frame(width: 7, height: 7)
            .scaledToFit()
            .opacity(1-timeCounter)
            .padding([.top,.bottom], -25)
            .onReceive(timer) { input in
                if timeCounter >= 2.0 {
                    timeCounter = 0
                }
                timeCounter = timeCounter + WhereNowWatchView.countTime * 2
                
            }
    }
}

struct WhereNowWatchPortraitView: View {
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var weatherData: USAWeatherService
    @EnvironmentObject var birdData: BirdSightingService
    
    let timer = Timer.publish(every: WhereNowWatchView.countTime, on: .main, in: .common).autoconnect()
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
                    LocationAccessDisabledWatchView()
                }
                
                ScrollView() {
                    LazyVStack {
                        Text("WHERE NOW!")
                            .font(smallFont)
                            .modifier(UpdatedSpinnable(tapToggler: $appNameTapped, tapActionNotification: ""))

                        Group {
                            HeaderView(isPresenting: $showLocation, showTimeTracker: $showLocationTime,  hideTimeTracker: $hideLocationTime, title: "Here now!")
                                .frame(maxWidth: .infinity)
                            
                            VStack {
                                Text(self.locationData.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                                    .multilineTextAlignment(.center)
/*#if os(watchOS)
#else
                                if let image = self.locationData.image {
                                    MapSnapshotView(image: image)
                                }
#endif*/
                            }
                            .scaleEffect(showLocation ? 1 : 0)
                            .animation(.easeInOut, value: showLocation)
                        }
                        Group {
                            if birdData.birdSeenCommonDescription != nil {
                                HeaderView(isPresenting: $showBirdData, showTimeTracker: $showBirdDataTime,  hideTimeTracker: $hideBirdDataTime, title: "Hear now!")
                                WatchBirdSightingsViews(width: geometry.size.width)
                                    .frame(minHeight: showBirdData ? 300 : 0, maxHeight: showBirdData ? 750 : 0)
                                    .scaleEffect(showBirdData ? 1 : 0)
                                    .animation(.easeInOut, value: showBirdData)

                            }
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
                .padding([.top, .bottom], -25)
                .onReceive(timer) { input in
                    if timeCounter >= 2.0 {
                        timeCounter = 0
                    }
                    timeCounter = timeCounter + WhereNowWatchView.countTime * 2
                    
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
                Spacer()
            }.animation(.default, value: 1)
        }
    }
}
