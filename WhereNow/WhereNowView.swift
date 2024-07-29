//
//  ContentView.swift
//  WhereAmI Watch App
//
//  Created by Jon on 7/10/24.
//

import SwiftUI
import WidgetKit
import CoreLocation

struct WhereNowView: View {
    static var countTime:Double = 0.1
    @EnvironmentObject var data: LocationDataModel
    @State var placemarkInfo: String = ""
    
    let timer = Timer.publish(every: WhereNowView.countTime, on: .main, in: .common).autoconnect()
    @State var timeCounter:Double = 0.0

    var body: some View {
        VStack {
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
                if self.data.addresses.count > 1 {
                    ScrollView() {
                        VStack {
                            Text(self.data.addresses.compactMap({$0.freeformAddress}).joined(separator: "\n\n"))
                                    .multilineTextAlignment(.center)
                        }
                    }
                }else {
                    //if #available(iOS, *) {
                    Text(self.data.addresses.compactMap({$0.freeformAddress}).joined(separator: "\n\n"))
                            .multilineTextAlignment(.center)
                    //} else
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
    }
}

#Preview {
    WhereNowView()
}
