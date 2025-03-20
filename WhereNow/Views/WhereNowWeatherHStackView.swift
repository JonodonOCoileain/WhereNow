//
//  WhereNowWeatherHStackView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//

import SwiftUI
import CoreLocation

struct WhereNowWeatherHStackView: View {
    @ObservedObject var data: LocationDataModel
    @ObservedObject var weatherData = USAWeatherService()
    @State var address: Address? = nil
    var body: some View {
        Group {
            VStack {
                if let address = address {
                    VStack(alignment: .leading) {
                        Text("Weather forecast of")
                        Text(address.formattedShort())
                    }
                }
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
                            Text(element.forecast)
                                .font(.subheadline)
                                .padding([.bottom])
                                .multilineTextAlignment(.leading)
                        }.frame(width: 250, alignment: .center)
                    }
                }
            }
        }
        .onChange(of: data.currentLocation, { oldValue, newValue in
            guard let newValue = newValue else { return }
            weatherData.cacheForecasts(using: newValue.coordinate)
        })
        .task(id: weatherData.locationOfCachedData){
            if let newValue = weatherData.locationOfCachedData {
                address = await newValue.getAddresses().first
            }
        }
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.longitude && rhs.latitude == lhs.latitude
    }
}
