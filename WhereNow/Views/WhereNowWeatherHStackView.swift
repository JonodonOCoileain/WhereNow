//
//  WhereNowWeatherHStackView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//

import SwiftUI

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
