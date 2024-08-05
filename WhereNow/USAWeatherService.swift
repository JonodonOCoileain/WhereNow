//
//  USAWeatherService.swift
//  WhereNow
//
//  Created by Jon on 8/2/24.
//

import Foundation
import SwiftUI
import CoreLocation

struct NWSForecastResponse: Codable {
    var properties: NWSProperties?
}

struct NWSProperties: Codable {
    var generatedAt: String?
    var updateTime: String?
    var elevation: NWSElevation?
    var periods: [NWSForecast]?
    var units: String?
}

struct NWSElevation: Codable {
    var value: Double?
    var unitCode: String?
}

struct NWSForecast: Codable {
    var windDirection: String?
    var temperature: Int64?
    var probabilityOfPrecipitation: ProbabilityOfPrecipitation?
    var windSpeed: String?
    var startTime: String?
    var endTime: String?
    var number: Int64?
    var temperatureUnit: String?
    var icon: String?
    var shortForecast: String?
    var isDayTime: Bool?
    var name: String?
    var detailedForecast: String?
}

struct ProbabilityOfPrecipitation: Codable {
    var value: Int64?
    var unitCode: String?
}

struct ForecastOffice: Codable {
    let name: String?
    let responsibleCounties: [String]?
    let approvedObservationStations: [String]?
    let address: ForecastOfficeAddress?
    let parentOrganization: String?
    let email: String?
    let responsibleFireZones: [String]?
    let responsibleForecastZones: [String]?
    let nwsRegion: String?
    let faxNumber: String?
    let id: String?
    
    func description() -> String {
        let name = name ?? ""
        let address = address?.description() ?? ""
        let email = email ?? ""
        let parentURL = parentOrganization ?? ""
        return name + "\n" + address + "\n" + "Email address: " + email + "\n" + "Parent organization: \(parentURL)"
    }
}

struct ForecastOfficeAddress: Codable {
    let postalCode: String?
    let addressLocality: String?
    let addressRegion: String?
    let streetAddress: String?
    let telphoneNumber: String?
    
    func description() -> String {
        let streetAddress = streetAddress ?? ""
        let addressLocality = addressLocality ?? ""
        let addressRegion = addressRegion ?? ""
        let postalCode = postalCode ?? ""
        let telphoneNumber = telphoneNumber ?? ""
        return streetAddress + "\n" + addressLocality + ", " + addressRegion + " " + postalCode + "\n" + "Phone number:" + telphoneNumber
    }
}

class USAWeatherService: ObservableObject {

    typealias ForecastRequestCompletionHandler = (Result<[ForecastInfo], Error>) -> Void
    typealias ForecastRequestResult = Result<[ForecastInfo], Error>
    
    public static let BaseURL: URL = URL(string: "https://api.weather.gov/")!
    
    @Published var timesAndForecasts: [ForecastInfo] = []
    var forecastOfficeURL: String? {
        didSet {
            guard let urlString = forecastOfficeURL, let url = URL(string: urlString) else {
                return
            }
            var request = URLRequest(url: url)
            request.addValue("(WhereNow, jontwlc@gmail.com)", forHTTPHeaderField: "User-Agent")
            
            let task = URLSession(configuration: .ephemeral).dataTask(with: request) { [weak self] data, _, error in
                if let data = data {
                    DispatchQueue.main.async { [weak self] in
                        do {
                            self?.forecastOffice = try JSONDecoder().decode(ForecastOffice.self, from: data)
                        } catch {
                            print(error)
                        }
                    }
                }
                
                if let error = error {
                    print(error.localizedDescription)
                }
            }

            task.resume()
        }
    }

    
    @Published var forecastOffice: ForecastOffice?

    func cacheForecasts(using coordinate: CLLocationCoordinate2D) {
        let url = USAWeatherService.BaseURL
            .appendingPathComponent("points")
            .appendingPathComponent("\(coordinate.latitude),\(coordinate.longitude)")
        var request = URLRequest(url: url)
        request.addValue("(Where Now! iOS App Store Sep 2024, by Jonathan Lavallee Collins: jontwlc@gmail.com)", forHTTPHeaderField: "User-Agent")
        request.addValue("application/geo+json", forHTTPHeaderField: "Accept")
        let dataTask = URLSession(configuration: .ephemeral).dataTask(with: request, completionHandler: { [weak self] data, _, error in
            let pointInfo = data?.convertToDictionary()
            if let properties = pointInfo?["properties"] as? [String:Any], let forecastURL = properties["forecast"] as? String, let URL = URL(string: forecastURL) {
                DispatchQueue.main.async { [weak self] in
                    self?.forecastOfficeURL = properties["forecastOffice"] as? String
                }
                var components = URLComponents(url: URL, resolvingAgainstBaseURL: false)!
                let units: String = "si"//"us" //"si" is the other option
                components.queryItems = [
                    URLQueryItem(name: "units", value: units)
                ]
                var forecastRequest = URLRequest(url: components.url!)
                forecastRequest.addValue("(WhereNow, jontwlc@gmail.com)", forHTTPHeaderField: "User-Agent")
                let forecastTask = URLSession(configuration: .ephemeral).dataTask(with: forecastRequest) { [weak self] data, _, error in
                    guard let data = data else {
                        print(error?.localizedDescription ?? "Error retrieving forecast data")
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(NWSForecastResponse.self, from: data)
                        if let periods = response.properties?.periods {
                            DispatchQueue.main.async { [weak self] in
                                self?.timesAndForecasts = self?.syncParseForecast(periods: periods) ?? []
                            }
                        }
                    } catch {
                        let description = error.localizedDescription
                        print(description)
                    }
                }
                forecastTask.resume()
            }
        })
        dataTask.resume()
    }
    
    func getForecasts(using coordinate: CLLocationCoordinate2D) async -> [ForecastInfo] {
        let url = USAWeatherService.BaseURL
            .appendingPathComponent("points")
            .appendingPathComponent("\(coordinate.latitude),\(coordinate.longitude)")
        var request = URLRequest(url: url)
        request.addValue("(WhereNow, jontwlc@gmail.com)", forHTTPHeaderField: "User-Agent")
        request.addValue("application/geo+json", forHTTPHeaderField: "Accept")
        do {
            let dataResponse = try await URLSession(configuration: .ephemeral).data(for: request)
            let pointInfo = dataResponse.0.convertToDictionary()
            if let properties = pointInfo?["properties"] as? [String:Any], let forecastURL = properties["forecast"] as? String, let URL = URL(string: forecastURL) {
                self.forecastOfficeURL = properties["forecastOffice"] as? String
                var components = URLComponents(url: URL, resolvingAgainstBaseURL: false)!
                let units: String = "si"//"us" //the other option is 'si'
                components.queryItems = [
                    URLQueryItem(name: "units", value: units)
                ]
                
                var forecastRequest = URLRequest(url: components.url!)
                forecastRequest.addValue("(WhereNow, jontwlc@gmail.com)", forHTTPHeaderField: "User-Agent")
                let forecastResponse = try  await URLSession(configuration: .ephemeral).data(for: forecastRequest)
                
                let response = try JSONDecoder().decode(NWSForecastResponse.self, from: forecastResponse.0)
                let periods = response.properties?.periods ?? []
                
                return await parseForecast(periods: periods)
            } else {
                return []
            }
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    func parseForecast(periods: [NWSForecast]) async -> [ForecastInfo] {
        let names = periods.compactMap({$0.name})
        let allDetails = periods.compactMap({$0.detailedForecast})
        let shortDescriptions = periods.compactMap({$0.shortForecast})
        let windDirections = periods.compactMap({$0.windDirection})
        let windSpeeds = periods.compactMap({$0.windSpeed})
        
        var timesAndForecasts: [ForecastInfo] = []
        for (index, element) in names.enumerated() {
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
            timesAndForecasts.append(ForecastInfo(name: element, forecast: details.joined(separator: " "), shortDescription: shortDescriptions[index], windSpeed: windSpeeds[index], windDirection: windDirections[index]))
        }
        return timesAndForecasts
    }
    
    func syncParseForecast(periods: [NWSForecast]) -> [ForecastInfo] {
        let names = periods.compactMap({$0.name})
        let allDetails = periods.compactMap({$0.detailedForecast})
        let shortDescriptions = periods.compactMap({$0.shortForecast})
        let windDirections = periods.compactMap({$0.windDirection})
        let windSpeeds = periods.compactMap({$0.windSpeed})
        
        var timesAndForecasts: [ForecastInfo] = []
        for (index, element) in names.enumerated() {
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
            timesAndForecasts.append(ForecastInfo(name: element, forecast: details.joined(separator: " "), shortDescription: shortDescriptions[index], windSpeed: windSpeeds[index], windDirection: windDirections[index]))
        }
        return timesAndForecasts
    }
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

