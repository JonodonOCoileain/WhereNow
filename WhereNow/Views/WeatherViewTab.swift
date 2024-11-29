//
//  WeatherViewTab.swift
//  WhereNow
//
//  Created by Jon on 11/15/24.
//

import SwiftUI

struct WeatherViewTab: View {
    @EnvironmentObject var weatherData: USAWeatherService
    var body: some View {
        ScrollView() {
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
        }
    }
}
