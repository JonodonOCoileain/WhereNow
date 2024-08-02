//
//  LocationDataModel.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//

import SwiftUI
import CoreLocation
#if os(watchOS)
#else
import NationalWeatherService
#endif

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

class LocationDataModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
#if os(watchOS)
#else
    let nws = NationalWeatherService(userAgent: "(WhereNow, jontwlc@gmail.com)")
    var snapshotManager: MapSnapshotManager = MapSnapshotManager()
    @Published var timesAndForecasts: [ForecastInfo] = [] {
        didSet {
            gotWeather = true
        }
    }
    #endif
    @Published var image: Image?
    var readyForUpdate:Bool = true
    var timer: Timer?
    var gotWeather: Bool = false
    var counter: Int = 0
    @objc func fireTimer() {
        counter += 2
        self.readyForUpdate = true
        if !gotWeather {
            self.getWeather()
        }
        if counter > 60*60*5 {
            gotWeather = false
        }
    }
    @Published var currentLocation: CLLocation = CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792)
    {
        didSet {
#if os(watchOS)
#else
            snapshotManager.snapshot(at: currentLocation.coordinate) { snapshotResult in
                switch snapshotResult {
                case .success(let newImageResult):
                    DispatchQueue.main.async {
                        self.image = newImageResult
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
#endif
            
            let coordinate = currentLocation.coordinate
            guard let url = URL(string: "https://api.tomtom.com/search/2/reverseGeocode/\(coordinate.latitude),\(coordinate.longitude).json?key=FBSjYeqToGYAeG2A5txodKfGHrql38S4&radius=100") else { return }
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else {
                    CLGeocoder().reverseGeocodeLocation(self.currentLocation, completionHandler: {(placemarks, error) -> Void in
                        guard error == nil else {
                            print("Reverse geocoder failed with error" + (error?.localizedDescription ?? "undescribed error"))
                            return
                        }
                        guard placemarks?.count ?? 0 > 0 else {
                            print("Problem with the data received from geocoder")
                            return
                        }
                        
                        if let newAddresses = placemarks?.compactMap({$0.asAddress()}), self.addresses != newAddresses {
                            print("saving new addresses")
                            DispatchQueue.main.async {
                                self.addresses = newAddresses
                            }
                        }
                        })
                    return
                }
                //print(String(data: data, encoding: .utf8)!)
                do {
                    let newResponse = try JSONDecoder().decode(Response.self, from: data)
                    let newAddresses = newResponse.addresses.compactMap({$0.address})
                    if self.addresses != newAddresses {
                        DispatchQueue.main.sync {
                            self.addresses = newAddresses
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                    CLGeocoder().reverseGeocodeLocation(self.currentLocation, completionHandler: {(placemarks, error) -> Void in
                        guard error == nil else {
                            print("Reverse geocoder failed with error" + (error?.localizedDescription ?? "undescribed error"))
                            return
                        }
                        guard placemarks?.count ?? 0 > 0 else {
                            print("Problem with the data received from geocoder")
                            return
                        }
                        
                        if let newAddresses = placemarks?.compactMap({$0.asAddress()}), self.addresses != newAddresses {
                            print("saving new addresses")
                            DispatchQueue.main.async {
                                self.addresses = newAddresses
                            }
                        }
                        })
                }
            }
            task.resume()
        }
    }
    var manager: CLLocationManager = CLLocationManager()
    @Published var addressInfoIsUpdated: Bool = false
    @Published var flag: String = ""
    @Published var addresses: [Address] = [] {
        didSet {
            guard let address = addresses.first else { return }
            flag = ""
            if let countryCode = address.countryCode {
                let base : UInt32 = 127397
                for v in countryCode.unicodeScalars {
                    flag.unicodeScalars.append(UnicodeScalar(base + v.value)!)
                }
            }
            self.addressesVeryLongFlag = self.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n")
        }
    }
    @Published var addressesVeryLongFlag: String = ""
    
    init(timer: Bool = true) {
        super.init()
        if timer {
            self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        }
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func start() {
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("Total of locations: \(locations.count)")
        if readyForUpdate {
            if let currentLocation = locations.first, currentLocation != self.currentLocation {
                let wasNotUpdated = self.currentLocation == CLLocation(latitude: 37.333424329435715, longitude: -122.00546584232792)
                self.currentLocation = currentLocation
                readyForUpdate = false
                addressInfoIsUpdated = true
                if wasNotUpdated {
                    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                        self?.getWeather()
                    }
                }
            }
        }
        print(locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error.localizedDescription)
        addressInfoIsUpdated = false
    }
    
    func stop() {
        manager.stopUpdatingLocation()
    }
    
    func getWeather() {
#if os(watchOS)
#else
        let location = CLLocationCoordinate2D(latitude:round(currentLocation.coordinate.latitude*1000)/1000,longitude:round(currentLocation.coordinate.longitude*1000)/1000)
        
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
#endif
    }
}

extension Date {
    public func description() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha EEEE"
        return formatter.string(from: self)
    }
}

extension String {
    func matchesForRegexInText(regex: String!) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSMakeRange(0, nsString.length))
            return results.compactMap( { nsString.substring(with: $0.range)} )
        } catch {
            print(error)
            return []
        }
    }
}

extension Double {
    func celsiusToFahrenheit() -> Double {
        return (self * 9/5) + 32
    }
}
