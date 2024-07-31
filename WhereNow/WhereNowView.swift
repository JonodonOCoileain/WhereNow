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
import WeatherKit

struct WhereNowView: View {
    static var countTime:Double = 0.1
    @ObservedObject var data: LocationDataModel = LocationDataModel()
    @State var placemarkInfo: String = ""
    var weatherInfo: WeatherService = WeatherService()
    
    let timer = Timer.publish(every: WhereNowView.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0

    var body: some View {
            if ([CLAuthorizationStatus.restricted, CLAuthorizationStatus.denied].contains(where: {$0 == data.manager.authorizationStatus})) {
                Image(systemName: "globe")
                Text("Location status disabled")
            } else {
                Image("LOCATION")
                    .resizable(resizingMode: .stretch)
                    .frame(width: 10, height: 10)
                    .scaledToFit()
                    .opacity(data.addressInfoIsUpdated ? 0 : 1-timeCounter)
                
                Text(self.data.flag)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20))
                    ScrollView() {
                        VStack {
                            Text(self.data.addresses.compactMap({$0.formattedCommonLong()}).joined(separator: "\n\n"))
                                    .multilineTextAlignment(.center)
                            if let image = self.data.image {
                                ZStack {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .edgesIgnoringSafeArea(.all)
                                        .cornerRadius(20)
                                        .clipped()
                                    
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
                                }
                            }
                        }
                    }
                    .onAppear() {
                        data.start()
                        WidgetCenter.shared.reloadTimelines(ofKind: "WhereNowWidget")
                    }
                    .onDisappear() {
                        data.stop()
                    }
                    .onReceive(timer) { input in
                        if timeCounter >= 2.0 {
                            timeCounter = 0
                        }
                        timeCounter = timeCounter + WhereNowView.countTime * 2
                    }
#if os(watchOS)
                    Spacer()
#endif
            }
        
    }
}

#if DEBUG
struct WhereNowView_Previews: PreviewProvider {
    static var previews: some View {
        
        return Group {
            WhereNowView()
        }
    }
}
#endif
