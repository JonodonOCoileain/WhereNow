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
    
    var body: some View {
        if ([CLAuthorizationStatus.restricted, CLAuthorizationStatus.denied].contains(where: {$0 == data.manager.authorizationStatus})) {
            Image(systemName: "globe")
            Text("Location status disabled")
        } else {
            Group {
                #if os(watchOS)
                WhereNowPortraitView(data: data, weatherData: weatherData)
                #else
                if orientation.isPortrait {
                    WhereNowPortraitView(data: data, weatherData: weatherData)
                } else if orientation.isLandscape {
                    WhereNowLandscapeView(data: data, weatherData: weatherData)
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
    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData: USAWeatherService
    
    let timer = Timer.publish(every: WhereNowView.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0
    
    var body: some View {
        Image("LOCATION")
            .resizable(resizingMode: .stretch)
            .frame(width: 10, height: 10)
            .scaledToFit()
            .opacity(data.addressInfoIsUpdated ? 0 : 1-timeCounter)
        
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
                LazyVStack(alignment:.leading) {
                    ForEach(weatherData.timesAndForecasts, id: \.self) { element in
                        LazyVStack(alignment:.leading) {
                            Text(Fun.emojis.randomElement() ?? "")
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                            Text(element.name ?? "")
                                    .font(.caption2)
                                    .padding([.leading, .trailing])
                                    .multilineTextAlignment(.center)
                            Text(element.forecast)
                                .font(.caption2)
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
        })
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
#if os(watchOS)
#else
struct WhereNowLandscapeView: View {
    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData: USAWeatherService = USAWeatherService()
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                Text(self.data.addressesVeryLongFlag)
                    .multilineTextAlignment(.center)
                if let image = self.data.image {
                    MapSnapshotView(image: image)
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
                    LazyVStack {
                        Text(Fun.emojis.randomElement() ?? "")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                        Text(element.name ?? "")
                            .font(.caption2)
                            .padding([.top])
                            .multilineTextAlignment(.center)
                        /*Text(element.time ?? "")
                            .font(.caption2)
                            .padding([.top, .trailing])
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 120, maxWidth: 140, maxHeight: .infinity)*/
                        Text(element.forecast)
                            .font(.caption2)
                            .padding([.bottom])
                            .multilineTextAlignment(.leading)
                    }.frame(width: 200, alignment: .center)
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
