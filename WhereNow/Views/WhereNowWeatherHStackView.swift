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
            VStack(alignment: .leading) {
                if let address = address {
                        Text("Weather forecast of " + address.formattedShort())
                }
                HStack(alignment: .top) {
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
                                .lineLimit(100)
                                .fixedSize(horizontal: false, vertical: true)
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
