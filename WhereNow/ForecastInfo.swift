//
//  ForecastInfo.swift
//  WhereNow
//
//  Created by Jon on 8/2/24.
//
import Foundation

class ForecastInfo: Hashable {
    let name: String?
    let time: String?
    let forecast: String
    let shortDescription: String?
    let image: String?
    let windDirection: String?
    let windSpeed: String?
    
    init(name: String? = nil, time: String? = nil, forecast: String, shortDescription: String? = nil, image: String? = nil, windSpeed: String? = nil, windDirection: String? = nil) {
        self.name = name
        self.time = time
        self.forecast = forecast
        self.shortDescription = shortDescription
        self.image = image
        self.windSpeed = windSpeed
        self.windDirection = windDirection
    }
    
    static func == (lhs: ForecastInfo, rhs: ForecastInfo) -> Bool {
        return lhs.time == rhs.time && lhs.forecast == rhs.forecast && lhs.name == rhs.name
        && lhs.shortDescription == rhs.shortDescription
        && lhs.image == rhs.image
        && lhs.windSpeed == rhs.windSpeed
        && lhs.windDirection == rhs.windDirection

    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(forecast)
        hasher.combine(time)
        hasher.combine(shortDescription)
        hasher.combine(image)
        hasher.combine(windSpeed)
        hasher.combine(windDirection)
    }
}
