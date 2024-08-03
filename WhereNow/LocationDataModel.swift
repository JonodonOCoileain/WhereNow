//
//  LocationDataModel.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//

import SwiftUI
import CoreLocation

class LocationDataModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
#if os(watchOS)
#else
    //let weatherData = USAWeatherService()
    var snapshotManager: MapSnapshotManager = MapSnapshotManager()
    #endif
    @Published var image: Image?
    var readyForUpdate:Bool = true
    var timer: Timer?
    var counter: Int = 0
    @objc func fireTimer() {
        counter += 2
        self.readyForUpdate = true
#if os(watchOS)
#else
        /*if !(weatherData.timesAndForecasts.isEmpty || counter > 60*60*5) {
            let currentLocation = currentLocation.coordinate
            let location = CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            counter = 0
            weatherData.getWeather(of: location)
        }*/
#endif
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
                #if os(watchOS)
                #else
                /*if wasNotUpdated {
                    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                        self?.weatherData.getWeather(of: CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude))
                    }
                }*/
                #endif
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
