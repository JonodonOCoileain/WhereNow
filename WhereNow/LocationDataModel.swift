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
    var snapshotManager: MapSnapshotManager = MapSnapshotManager()
    #endif
    @Published var image: Image?
    var readyForUpdate:Bool = true
    var timer: Timer?
    @objc func fireTimer() {
        self.readyForUpdate = true
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
    var countries: [String:String] = [:]
    var manager: CLLocationManager = CLLocationManager()
    @Published var addressInfoIsUpdated: Bool = false
    @Published var flag: String = ""
    @Published var addresses: [Address] = [] {
        didSet {
            guard let address = addresses.first else { return }
            if let countryCode = countries.keys.first(where: { countries[$0] == address.country }) {
                let base : UInt32 = 127397
                var s = ""
                for v in countryCode.unicodeScalars {
                    s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
                }
                if flag != String(s) {
                    flag = String(s) //Flag update
                }
            }
        }
    }
    
    init(timer: Bool = true, start: Bool = false) {
        super.init()
        if timer {
            self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        }
        if start {
            self.start(slowly: true)
        }
        
        for code in NSLocale.isoCountryCodes {
            let id: String = Locale.identifier(fromComponents: [
                NSLocale.Key.countryCode.rawValue : code
            ])
            guard let name = (Locale.current as NSLocale).displayName(forKey: .identifier, value: id) else { continue }
            countries[code] = name
        }
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func start(slowly: Bool? = nil) {
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.startUpdatingLocation()
        
        if slowly == true {
            self.timer?.invalidate()
            self.timer = nil
            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(Float(60) * Float(19.2)), target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("Total of locations: \(locations.count)")
        if readyForUpdate {
            if let currentLocation = locations.first, currentLocation != self.currentLocation {
                self.currentLocation = currentLocation
                readyForUpdate = false
                addressInfoIsUpdated = true
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
