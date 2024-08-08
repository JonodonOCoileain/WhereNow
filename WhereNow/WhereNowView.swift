//
//  ContentView.swift
//  WhereAmI Watch App
//
//  Created by Jon on 7/10/24.
//

import SwiftUI
import WidgetKit
import CoreLocation
import UIKit

struct WhereNowView: View {
#if os(watchOS)
#else
    @State private var orientation = UIDeviceOrientation.portrait
#endif
    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel = LocationDataModel()
    @ObservedObject var weatherData: USAWeatherService = USAWeatherService()
    @ObservedObject var birdData: BirdSightingService = BirdSightingService()
    
    var body: some View {
        if ([CLAuthorizationStatus.restricted, CLAuthorizationStatus.denied].contains(where: {$0 == data.manager.authorizationStatus})) {
            Image(systemName: "globe")
            Text("Location status disabled")
        } else {
            Group {
                #if os(watchOS)
                WhereNowPortraitView(data: data, weatherData: weatherData, birdData: birdData)
                #else
                if orientation.isPortrait {
                    WhereNowPortraitView(data: data, weatherData: weatherData, birdData: birdData)
                } else if orientation.isLandscape {
                    WhereNowLandscapeView(data: data, weatherData: weatherData, birdData: birdData)
                }
                #endif
            }
            .onAppear() {
                data.start()
            }
            .onDisappear() {
                data.stop()
                WidgetCenter.shared.reloadAllTimelines()
            }
            #if os(iOS)
            .onRotate { newOrientation in
                if !newOrientation.isFlat {
                    orientation = newOrientation
                } else if orientation == .unknown {
                    orientation = .portrait
                }
            }
            #endif
        }
    }
}
#if os(iOS)
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}


extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
#endif

struct WhereNowPortraitView: View {
    #if os(watchOS)
        let reversePadding = true
    #else
        let reversePadding = false
    #endif
    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData: USAWeatherService
    @ObservedObject var birdData: BirdSightingService
    let timer = Timer.publish(every: WhereNowView.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            if !data.addressInfoIsUpdated {
                Image("LOCATION")
                    .resizable(resizingMode: .stretch)
                    .frame(width: 7, height: 7)
                    .scaledToFit()
                    .opacity(data.addressInfoIsUpdated ? 0 : 1-timeCounter)
                    .padding([.top,.bottom], reversePadding ? -25 : 0)
            }
            
            ScrollView() {
                VStack {
                    Text(self.data.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                        .multilineTextAlignment(.center)
#if os(watchOS)
#else
                    if let image = self.data.image {
                        MapSnapshotView(image: image)
                    }
#endif
                    if let birdSeenCommonDescription = birdData.birdSeenCommonDescription {
                        BirdsBriefView(birdData: birdData, briefing: birdSeenCommonDescription)
                            .frame(minHeight:140, maxHeight: (geometry.size.height ?? 0) > 140 ? (geometry.size.height ?? 140) : 140 )
                    }
                    
                    LazyVStack(alignment:.leading) {
                        ForEach(weatherData.timesAndForecasts, id: \.self) { element in
                            LazyVStack(alignment:.center) {
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
                    }
                    
                    Text("Weather data provided by the National Weather Service, part of the National Oceanic and Atmospheric Administration (NOAA)")
                        .multilineTextAlignment(.center)
                        .font(.caption2)
                    Text(weatherData.forecastOffice?.description() ?? "")
                        .multilineTextAlignment(.center)
                        .font(.caption2)
                }
            }
            .onChange(of: data.currentLocation, { oldValue, newValue in
                if weatherData.timesAndForecasts.count == 0 {
                    weatherData.cacheForecasts(using: newValue.coordinate)
                }
                if birdData.sightings.count == 0 {
                    birdData.cacheSightings(using: newValue.coordinate)
                }
            })
            .padding([.top, .bottom], reversePadding ? -25 : 0)
            .onReceive(timer) { input in
                if timeCounter >= 2.0 {
                    timeCounter = 0
                }
                timeCounter = timeCounter + WhereNowView.countTime * 2
            }
#if os(watchOS)
            Spacer()
#else
#endif
        }
    }
}
#if os(watchOS)
#else
struct WhereNowLandscapeView: View {
    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData: USAWeatherService = USAWeatherService()
    @ObservedObject var birdData: BirdSightingService = BirdSightingService()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                LazyHStack {
                    Text(self.data.addressesVeryLongFlag)
                        .multilineTextAlignment(.center)
                    if let image = self.data.image {
                        MapSnapshotView(image: image)
                    }
                    
                    if let birdSeenCommonDescription = birdData.birdSeenCommonDescription {
                        BirdsBriefView(birdData: birdData, briefing: birdSeenCommonDescription)
                            .frame(minHeight:140, maxHeight: (geometry.size.height ?? 0) > 140 ? (geometry.size.height ?? 140) : 140 )
                    }
                    
                    WhereNowWeatherHStackView(data: data, weatherData: weatherData)
                    
                    VStack {
                        Spacer()
                        Text("Weather data provided by the National Weather Service, part of the National Oceanic and Atmospheric Administration (NOAA)")
                            .font(.caption2)
                            .multilineTextAlignment(.leading)
                        Text(weatherData.forecastOffice?.description() ?? "")
                            .multilineTextAlignment(.leading)
                            .font(.caption2)
                    }
                }
            }
            .onChange(of: data.currentLocation, { oldValue, newValue in
                if birdData.sightings.count == 0 {
                    birdData.cacheSightings(using: newValue.coordinate)
                }
            })
        }
    }
}
#endif

struct WhereNowWeatherHStackView: View {
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData = USAWeatherService()
    var body: some View {
        Group {
            LazyHStack(alignment: .center) {
                ForEach(weatherData.timesAndForecasts, id: \.self) { element in
                    LazyVStack() {
                        Text(Fun.emojis.randomElement() ?? "")
                            .font(.title)
                            .multilineTextAlignment(.center)
                        Text(element.name ?? "")
                            .font(.subheadline)
                            .padding([.top])
                            .multilineTextAlignment(.center)
                        /*Text(element.time ?? "")
                            .font(.caption2)
                            .padding([.top, .trailing])
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 120, maxWidth: 140, maxHeight: .infinity)*/
                        Text(element.forecast)
                            .font(.subheadline)
                            .padding([.bottom])
                            .multilineTextAlignment(.leading)
                    }.frame(width: 250, alignment: .center)
                }
            }
        }
        .onChange(of: data.currentLocation, { oldValue, newValue in
            if weatherData.timesAndForecasts.count == 0 {
                weatherData.cacheForecasts(using: newValue.coordinate)
            }
        })
    }
}
#if os(watchOS)
#else
struct MapSnapshotView: View {
    var image: Image
    var body: some View {
        ZStack {
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .cornerRadius(20)
                .clipped()
                .padding()
            
            // The map is centered on the user location, therefore we can simply draw the blue dot in the
            // center of our view to simulate the user coordinate.
            Circle()
                .foregroundColor(.blue)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .frame(width: 15,
                       height: 15)
        }.padding()
    }
}
#endif

#if DEBUG
struct WhereNowView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            WhereNowView()
        }
    }
}
#endif
