//
//  ForecastInfo.swift
//  WhereNow
//
//  Created by Jon on 8/2/24.
//
import Foundation

class ForecastInfo: NSObject, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.time, forKey: "time")
        coder.encode(self.forecast, forKey: "forecast")
        coder.encode(self.shortDescription, forKey: "shortDescription")
        coder.encode(self.image, forKey: "image")
        coder.encode(self.windDirection, forKey: "windDirection")
        coder.encode(self.windSpeed, forKey: "windSpeed")
    }
    
    required init?(coder: NSCoder) {
        self.name = coder.decodeObject(forKey: "name") as? String
        self.time = coder.decodeObject(forKey: "time") as? String
        self.forecast = coder.decodeObject(forKey: "forecast") as? String ?? ""
        self.shortDescription = coder.decodeObject(forKey: "shortDescription") as? String
        self.image = coder.decodeObject(forKey: "image") as? String
        self.windDirection = coder.decodeObject(forKey: "windDirection") as? String
        self.windSpeed = coder.decodeObject(forKey: "windSpeed") as? String
    }
    
    
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
    
    /*func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(forecast)
        hasher.combine(time)
        hasher.combine(shortDescription)
        hasher.combine(image)
        hasher.combine(windSpeed)
        hasher.combine(windDirection)
    }*/
}
