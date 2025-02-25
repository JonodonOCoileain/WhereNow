//
//  WhereNowTests.swift
//  WhereNowTests
//
//  Created by Jon on 7/17/24.
//

import Testing
@testable import WhereNow

struct WhereNowTests {

    @Test func example() async throws {
        let service = USAWeatherService()
        let forecast = NWSForecast(windDirection: "East", temperature: 29, probabilityOfPrecipitation:ProbabilityOfPrecipitation(value: 30, unitCode: "percentage"), windSpeed: "33", number: 1, temperatureUnit: "F", shortForecast: "There will be rain.", isDayTime: true, name: "Name", detailedForecast: "Detailed forecast")
        let parsedForecasts = await service.parseForecastUS(periods: [forecast])
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
