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
                    .onChange(of: data.currentLocation, { oldValue, newValue in
                        if weatherData.timesAndForecasts.count == 0 {
                            weatherData.cacheForecasts(using: newValue.coordinate)
                        }
                        if birdData.sightings.count == 0 {
                            birdData.cacheSightings(using: newValue.coordinate)
                        }
                        if birdData.notableSightings.count < 2 {
                            birdData.cacheNotableSightings(using: newValue.coordinate)
                        }
                    })
                #else
                if orientation.isPortrait {
                    WhereNowPortraitView(data: data, weatherData: weatherData, birdData: birdData)
                        .onChange(of: data.currentLocation, { oldValue, newValue in
                            if weatherData.timesAndForecasts.count == 0 {
                                weatherData.cacheForecasts(using: newValue.coordinate)
                            }
                            if birdData.sightings.count == 0 {
                                birdData.cacheSightings(using: newValue.coordinate)
                            }
                            if birdData.notableSightings.count < 2 {
                                birdData.cacheNotableSightings(using: newValue.coordinate)
                            }
                        })
                } else if orientation.isLandscape {
                    WhereNowLandscapeView(data: data, weatherData: weatherData, birdData: birdData)
                        .onChange(of: data.currentLocation, { oldValue, newValue in
                            if weatherData.timesAndForecasts.count == 0 {
                                weatherData.cacheForecasts(using: newValue.coordinate)
                            }
                            if birdData.sightings.count == 0 {
                                birdData.cacheSightings(using: newValue.coordinate)
                            }
                            if birdData.notableSightings.count < 2 {
                                birdData.cacheNotableSightings(using: newValue.coordinate)
                            }
                        })
                }
                #endif
            }
            .animation(.default, value: 1)
            .onAppear() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.01, execute: {
                    data.start()
                })
            }
            .onDisappear() {
                data.stop()
                WidgetCenter.shared.reloadAllTimelines()
            }
            .alert(isPresented: self.$data.deniedStatus) {
                Alert(
                    title: Text("Location permissions required"),
                    message: Text("This app is about where you are! Please allow location access."),
                    primaryButton: .cancel(Text("Cancel")),
                    secondaryButton: .default(Text("Settings"), action: {
#if os(iOS)
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
#endif
                    }))
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
    
    @State var showLocation: Bool = true
    @State var showLocationTime: Double = Date().timeIntervalSince1970
    @State var hideLocationTime: Double = 0.0
    @State var showBirdData: Bool = true
    @State var showBirdDataTime: Double = Date().timeIntervalSince1970
    @State var hideBirdDataTime: Double = 0.0
    @State var showWeatherData: Bool = true
    @State var showWeatherDataTime: Double = Date().timeIntervalSince1970
    @State var hideWeatherDataTime: Double = 0.0
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
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
                        Text("HERE NOW!")
                            .modifier(Spinnable())
                            .padding([.bottom],10)
                        
                        HeaderView(isPresenting: $showLocation, showTimeTracker: $showLocationTime,  hideTimeTracker: $hideLocationTime, title: "Where now!")
                            .frame(maxWidth: .infinity)

                        VStack {
                            Text(self.data.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                                .multilineTextAlignment(.center)
#if os(watchOS)
#else
                            if let image = self.data.image {
                                MapSnapshotView(image: image)
                            }
#endif
                        }
                        .scaleEffect(showLocation ? 1 : 0)
                        .offset(y: hideLocationTime > showLocationTime ? -200 * (Date().timeIntervalSince1970 - hideLocationTime)/0.35 : (hideLocationTime < showLocationTime && showLocationTime >= 0.35+Date().timeIntervalSince1970  ? -10 * (showLocationTime - Date().timeIntervalSince1970)/0.35 : 0))
                        .frame(maxHeight: showLocationTime < Date().timeIntervalSince1970 - 0.35 && showLocationTime > hideLocationTime ? .infinity : Date().timeIntervalSince1970 > hideLocationTime + 0.35 && hideLocationTime > showLocationTime ? 0 : Date().timeIntervalSince1970 < hideLocationTime + 0.35 && Date().timeIntervalSince1970 > hideLocationTime ? 500 * (Date().timeIntervalSince1970 - hideLocationTime)/0.35 : .infinity)
                        .animation(.easeInOut, value: showLocation)
                        
                        if let birdSeenCommonDescription = birdData.birdSeenCommonDescription {
                            HeaderView(isPresenting: $showBirdData, showTimeTracker: $showBirdDataTime,  hideTimeTracker: $hideBirdDataTime, title: "Hear now!")
                            BirdSightingsViews(birdData: birdData, locationData: data, briefing: birdSeenCommonDescription)
                                .frame(minHeight: 550, maxHeight: 900)
                                .scaleEffect(showBirdData ? 1 : 0)
                                .animation(.easeInOut, value: showBirdData)
                        }
                        
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
                .padding([.top, .bottom], reversePadding ? -25 : 0)
                .onReceive(timer) { input in
                    if timeCounter >= 2.0 {
                        timeCounter = 0
                    }
                    timeCounter = timeCounter + WhereNowView.countTime * 2
                    
                }
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                        let locationCoordinate = data.currentLocation.coordinate
                        weatherData.cacheForecasts(using: locationCoordinate)
                        birdData.cacheSightings(using: locationCoordinate)
                        birdData.cacheNotableSightings(using: locationCoordinate)
                    })
                }
#if os(watchOS)
                Spacer()
#else
#endif
            }
        }.animation(.default, value: 1)
    }
}
#if os(watchOS)
#else
struct WhereNowLandscapeView: View {
    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData: USAWeatherService = USAWeatherService()
    @ObservedObject var birdData: BirdSightingService = BirdSightingService()
    
    @State var showLocation: Bool = true
    @State var showLocationTime: Double = 0.0
    @State var hideLocationTime: Double = 0.0
    @State var showBirdData: Bool = true
    @State var showBirdDataTime: Double = 0.0
    @State var hideBirdDataTime: Double = 0.0
    @State var showWeatherData: Bool = true
    @State var showWeatherDataTime: Double = 0.0
    @State var hideWeatherDataTime: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack {
                    Text("HERE NOW!")
                        .modifier(Spinnable())
                        .padding([.bottom],10)
                    
                    HeaderView(isPresenting: $showLocation, showTimeTracker: $showLocationTime,  hideTimeTracker: $hideLocationTime, title: "Where now!")
                    Text(self.data.addressesVeryLongFlag)
                        .multilineTextAlignment(.center)
                        .scaleEffect(showLocation ? 1 : 0)
                        .animation(.easeInOut, value: showLocation)
                    if let image = self.data.image {
                        MapSnapshotView(image: image)
                            .scaleEffect(showLocation ? 1 : 0)
                            .animation(.easeInOut, value: showLocation)
                    }
                    
                    if let birdSeenCommonDescription = birdData.birdSeenCommonDescription {
                        HeaderView(isPresenting: $showBirdData, showTimeTracker: $showBirdDataTime,  hideTimeTracker: $hideBirdDataTime, title: "Hear now!")
                        if $showBirdData.wrappedValue {
                            BirdSightingsViews(birdData: birdData, locationData: data, briefing: birdSeenCommonDescription)
                                .frame(minHeight: 550, maxHeight: 900)
                        }
                    }
                    
                    HeaderView(isPresenting: $showWeatherData, showTimeTracker: $showWeatherDataTime,  hideTimeTracker: $hideWeatherDataTime, title: String.weatherNowTitle, spinningText: String.andLaterTitle)
                    VStack(alignment: .center) {
                        WhereNowWeatherHStackView(data: data, weatherData: weatherData)
                    
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
            .onChange(of: data.currentLocation, { oldValue, newValue in
                if birdData.sightings.count == 0 {
                    birdData.cacheSightings(using: newValue.coordinate)
                }
                if birdData.notableSightings.count == 0 {
                    birdData.cacheNotableSightings(using: newValue.coordinate)
                }
            })
        }
    }
}
#endif

struct HeaderView: View {
    @Binding var isPresenting: Bool
    @Binding var showTimeTracker: Double
    @Binding var hideTimeTracker: Double
    let title: String
    var spinningText: String? = nil
    @State private var textIsSpinning = 0.0
    var body: some View {
        HStack(content: {
            Text(title)
                .font(.title)
            if let spinningText = spinningText {
                Text(spinningText)
                    .font(.caption)
                    .rotationEffect(.degrees(textIsSpinning))
                    .onAppear {
                        withAnimation(.linear(duration: 1)
                            .speed(0.1).repeatForever(autoreverses: false)) {
                                textIsSpinning = 360.0
                            }
                    }
            }
            Spacer()
            Image(systemName: "chevron.compact.down")
                .foregroundColor(.gray)
                .rotationEffect(.degrees(isPresenting ? 0 : 180))
                .animation(Animation.easeInOut(duration: 0.3), value: isPresenting)
        })
        .padding()
        .background()
        .onTapGesture {
            isPresenting.toggle()
            if isPresenting {
                showTimeTracker = Date().timeIntervalSince1970
            } else {
                hideTimeTracker = Date().timeIntervalSince1970
            }
        }
    }
}

struct WhereNowWeatherHStackView: View {
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData = USAWeatherService()
    var body: some View {
        Group {
            HStack(alignment: .center) {
                ForEach(weatherData.timesAndForecasts, id: \.self) { element in
                    VStack() {
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
                .frame(maxWidth: 400, maxHeight: 400)
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
