//
//  ForecastInfo.swift
//  WhereNow
//
//  Created by Jon on 8/2/24.
//


class ForecastInfo: Hashable {
    let time: String
    let forecast: String
    
    init(time: String, forecast: String) {
        self.time = time
        self.forecast = forecast
    }
    
    static func == (lhs: ForecastInfo, rhs: ForecastInfo) -> Bool {
        return lhs.time == rhs.time && lhs.forecast == rhs.forecast
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(time)
        hasher.combine(forecast)
    }
}