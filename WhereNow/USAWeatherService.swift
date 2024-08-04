//
//  USAWeatherService.swift
//  WhereNow
//
//  Created by Jon on 8/2/24.
//

import Foundation
import SwiftUI
import CoreLocation
import NationalWeatherService

class USAWeatherService: ObservableObject {

    typealias ForecastRequestCompletionHandler = (Result<[ForecastInfo], Error>) -> Void
    typealias ForecastRequestResult = Result<[ForecastInfo], Error>
    
    let nws = NationalWeatherService(userAgent: "(WhereNow, jontwlc@gmail.com)")
    
    @Published var timesAndForecasts: [ForecastInfo] = []
    
    func getWeather(of location: CLLocationCoordinate2D) {
        // Gets the forecast, organized into time periods (such as Afternoon, Evening, etc).
        nws.forecast(for: location) { result in
            switch result {
            case .success(let forecast):
                let dateIntervals = forecast.periods.compactMap({$0.date})
                let allDetails = forecast.periods.compactMap({$0.detailedForecast})
                
                let times = dateIntervals.compactMap({ $0.start.description() + " - " + ($0.start.addingTimeInterval($0.duration).description()) })
                var timesAndForecasts: [ForecastInfo] = []
                for (index, element) in times.enumerated() {
                    let detailsString = allDetails[index]
                    var details = detailsString.split(separator:" ")
                    for (index, detailElement) in details.enumerated() {
                        if index < (details.count - 1), details[index+1].contains("km") {
                            let mph = Int(round((Float(detailElement) ?? 0) * 0.621371))
                            details[index] = "\(mph)"
                            let addPeriod = details[index+1].contains(".")
                            details[index+1] = "miles per hour" + (addPeriod ? "." : "")
                            if details[index-1] == "to" {
                                let otherMph = Int(round((Float(details[index-2]) ?? 0) * 0.621371))
                                details[index-2] = "\(otherMph)"
                            }
                        } else if  index < (details.count - 2), details[index+1].contains("cm") {
                            let inches = round((Float(detailElement) ?? 0) * 0.393701 * 10) / 10
                            details[index] = "\(inches)"
                            details[index+1] = "inches"
                            if details[index-1] == "to" {
                                let otherInches = round((Float(details[index-2]) ?? 0) * 0.393701 * 10) / 10
                                details[index-2] = "\(otherInches)"
                            }
                        } else if index > 0, details[index - 1] == "near" || details[index - 1] == "around" || (details[index - 1] == "as" && details[index - 2] == "high") {
                            let cleanedDetails = detailElement.components(separatedBy: CharacterSet.decimalDigits.inverted)
                            for cleanedDetail in cleanedDetails.filter({$0.count>0}) {
                                let temp = Int(round(Double(cleanedDetail)?.celsiusToFahrenheit() ?? 0))
                                let hadComma = detailElement.contains(",")
                                let hadPeriod = detailElement.contains(".")
                                let hadSemicolon = detailElement.contains(";")
                                let hadColon = detailElement.contains(":")
                                details[index] = "\(temp)°F" + (hadComma ? "," : "") + (hadPeriod ? "." : "") + (hadSemicolon ? ";" : "") + (hadColon ? ":" : "")
                            }
                        } else if detailElement.contains("pm"), detailElement.components(separatedBy: CharacterSet.decimalDigits.inverted).count > 1 {
                            let regex = try! NSRegularExpression(pattern: "([0-9])pm")
                            let range = NSMakeRange(0, detailElement.count)
                            let modString = regex.stringByReplacingMatches(in: String(detailElement), options: [], range: range, withTemplate: "$1PM")
                            details[index] = "\(modString)"
                        } else if detailElement.contains("am"), detailElement.components(separatedBy: CharacterSet.decimalDigits.inverted).count > 1 {
                            let regex = try! NSRegularExpression(pattern: "([0-9])am")
                            let range = NSMakeRange(0, detailElement.count)
                            let modString = regex.stringByReplacingMatches(in: String(detailElement), options: [], range: range, withTemplate: "$1AM")
                            details[index] = "\(modString)"
                        }
                    }
                    timesAndForecasts.append(ForecastInfo(time: element, forecast: details.joined(separator: " ")))
                }
                DispatchQueue.main.async {
                    self.timesAndForecasts = timesAndForecasts
                }
            case .failure(let error):     print(error)
            }
        }
    }
    
    /*func returnWeather(of location: CLLocationCoordinate2D) async -> ForecastRequestResult {
        // Gets the forecast, organized into time periods (such as Afternoon, Evening, etc).
        let result = await nws.forecast(for: location) { result in
            switch result {
            case .success(let forecast):
                let dateIntervals = forecast.periods.compactMap({$0.date})
                let allDetails = forecast.periods.compactMap({$0.detailedForecast})
                
                let times = dateIntervals.compactMap({ $0.start.description() + " - " + ($0.start.addingTimeInterval($0.duration).description()) })
                var timesAndForecasts: [ForecastInfo] = []
                for (index, element) in times.enumerated() {
                    let detailsString = allDetails[index]
                    var details = detailsString.split(separator:" ")
                    for (index, detailElement) in details.enumerated() {
                        if index < (details.count - 1), details[index+1].contains("km") {
                            let mph = Int(round((Float(detailElement) ?? 0) * 0.621371))
                            details[index] = "\(mph)"
                            let addPeriod = details[index+1].contains(".")
                            details[index+1] = "miles per hour" + (addPeriod ? "." : "")
                            if details[index-1] == "to" {
                                let otherMph = Int(round((Float(details[index-2]) ?? 0) * 0.621371))
                                details[index-2] = "\(otherMph)"
                            }
                        } else if  index < (details.count - 2), details[index+1].contains("cm") {
                            let inches = round((Float(detailElement) ?? 0) * 0.393701 * 10) / 10
                            details[index] = "\(inches)"
                            details[index+1] = "inches"
                            if details[index-1] == "to" {
                                let otherInches = round((Float(details[index-2]) ?? 0) * 0.393701 * 10) / 10
                                details[index-2] = "\(otherInches)"
                            }
                        } else if index > 0, details[index - 1] == "near" || details[index - 1] == "around" || (details[index - 1] == "as" && details[index - 2] == "high") {
                            let cleanedDetails = detailElement.components(separatedBy: CharacterSet.decimalDigits.inverted)
                            for cleanedDetail in cleanedDetails.filter({$0.count>0}) {
                                let temp = Int(round(Double(cleanedDetail)?.celsiusToFahrenheit() ?? 0))
                                let hadComma = detailElement.contains(",")
                                let hadPeriod = detailElement.contains(".")
                                let hadSemicolon = detailElement.contains(";")
                                let hadColon = detailElement.contains(":")
                                details[index] = "\(temp)°F" + (hadComma ? "," : "") + (hadPeriod ? "." : "") + (hadSemicolon ? ";" : "") + (hadColon ? ":" : "")
                            }
                        } else if detailElement.contains("pm"), detailElement.components(separatedBy: CharacterSet.decimalDigits.inverted).count > 1 {
                            let regex = try! NSRegularExpression(pattern: "([0-9])pm")
                            let range = NSMakeRange(0, detailElement.count)
                            let modString = regex.stringByReplacingMatches(in: String(detailElement), options: [], range: range, withTemplate: "$1PM")
                            details[index] = "\(modString)"
                        } else if detailElement.contains("am"), detailElement.components(separatedBy: CharacterSet.decimalDigits.inverted).count > 1 {
                            let regex = try! NSRegularExpression(pattern: "([0-9])am")
                            let range = NSMakeRange(0, detailElement.count)
                            let modString = regex.stringByReplacingMatches(in: String(detailElement), options: [], range: range, withTemplate: "$1AM")
                            details[index] = "\(modString)"
                        }
                    }
                    timesAndForecasts.append(ForecastInfo(time: element, forecast: details.joined(separator: " ")))
                }
                return .success(timesAndForecasts)//self.timesAndForecasts = timesAndForecasts
            case .failure(let error):     return .failure(ErrorCases.Described("From NOAA: " + error.localizedDescription))
            }
        }
    }*/
}
// Gets the forecast, organized into hours.
/*nws.hourlyForecast(for: location) { result in
 switch result {
 case .success(let forecast):
 let allDetails = forecast.periods.compactMap({$0.detailedForecast})
 DispatchQueue.main.async {
 self.detailedForecasts = allDetails
 }
 //print(forecast)
 //self.hourlyForecast = forecast
 case .failure(let error):     print(error)
 }
 }*/

// Gets the current condition.
/*nws.currentCondition(for: location) { result in
 switch result {
 case .success(let period):
 break
 //print(period)
 //self.forecastPeriod = period
 case .failure(let error):     print(error)
 }
 }*/

