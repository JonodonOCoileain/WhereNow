//
//  ContentView.swift
//  WhereAmI Watch App
//
//  Created by Jon on 7/10/24.
//

import SwiftUI
import CoreLocation
#if os(iOS) || os(macOS)
import UIKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WhereNowView: View {
    @State private var orientation = UIDeviceOrientation.portrait
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var weatherData: USAWeatherService
    @EnvironmentObject var birdData: BirdSightingService
    @Environment(\.scenePhase) var scenePhase
    @State var tabViewSelected: Bool = true
    
    var body: some View {
        if ([CLAuthorizationStatus.restricted, CLAuthorizationStatus.denied].contains(where: {$0 == locationData.manager.authorizationStatus})) {
            LocationAccessDisabledView()
        } else {
            Group {
#if os(macOS)
                WhereNowPortraitViewTabbed()
#elseif os(iOS)
                if orientation.isPortrait {
                    VStack {
                        Text("WHERE NOW!")
                            .modifier(UpdatedSpinnable(tapToggler: $tabViewSelected, tapActionNotification: ($tabViewSelected.wrappedValue ? "Portait mode tabview selected" : "Portrait mode long scrollView selected")))
                            .padding([.bottom],10)
                        if tabViewSelected {
                            WhereNowPortraitViewTabbed()
                        } else {
                            WhereNowPortraitView()
                        }
                    }
                } else if orientation.isLandscape {
                    WhereNowLandscapeView()
                }
#endif
            }
            .animation(.default, value: 1)
            .task {
                if let immediateLocation = locationData.immediateLocation()?.coordinate {
                    weatherData.cacheForecasts(using: immediateLocation)
                    await birdData.asyncCacheSightings(using: immediateLocation)
                    await birdData.asyncCacheNotableSightings(using: immediateLocation)
                }
            }
#if canImport(WidgetKit)
            .onDisappear() {
                WidgetCenter.shared.reloadAllTimelines()
            }
#endif
#if os(iOS)
            .alert(isPresented: self.$locationData.deniedStatus) {
                Alert(
                    title: Text("Location permissions required"),
                    message: Text("This app is about where you are! Please allow location access."),
                    primaryButton: .cancel(Text("Cancel")),
                    secondaryButton: .default(Text("Settings"), action: {
                        
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                        
                    }))
            }
#else
            .alert(isPresented: self.$locationData.deniedStatus) {
                Alert(title: Text("Location permissions required"), message: Text("This app is about where you are! Please allow location access."), dismissButton: .default(Text("Dismiss")))
            }
#endif
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

