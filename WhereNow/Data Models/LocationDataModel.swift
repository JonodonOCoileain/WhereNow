//
//  LocationDataModel.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//

import SwiftUI
import CoreLocation

class LocationDataModel: NSObject, ObservableObject, Observable, CLLocationManagerDelegate {
    
    #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
    var snapshotManager: MapSnapshotManager = MapSnapshotManager()
    #endif
    @Published var image: Image?
    var readyForUpdate:Bool = true
    var timer: Timer?
    var counter: Int = 0
    @Published var deniedStatus: Bool = false
    @objc func fireTimer() {
        counter += 5
        self.readyForUpdate = true
    }
    @Published var currentLocation: CLLocation? = nil
    {
        didSet {
            guard let currentLocation = currentLocation else { return }
#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
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
            
            let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                guard let self = self, let data = data else {
                    guard let self = self else {
                        return
                    }
                    CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: {(placemarks, error) -> Void in
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
                    CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: {(placemarks, error) -> Void in
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
    @Published var manager: CLLocationManager = CLLocationManager()
    @Published var addressInfoIsUpdated: Bool = false
    @Published var flag: String = ""
    @Published var addresses: [Address] = [] {
        didSet {
            guard let address = addresses.first else { return }
            DispatchQueue.main.async {
                self.flag = ""
                if let countryCode = address.countryCode {
                    let base : UInt32 = 127397
                    for v in countryCode.unicodeScalars {
                        self.flag.unicodeScalars.append(UnicodeScalar(base + v.value)!)
                    }
                }
            }
            DispatchQueue.main.async {
                self.addressesVeryLongFlag = self.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n")
            }
        }
    }
    @Published var addressesVeryLongFlag: String = ""
    let locationManager: LocationManager = LocationManager(locationStorageManager: UserDefaults.standard)
    init(timer: Bool = true) {
        super.init()
        
        if timer {
            self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        }
        if let location = locationManager.immediateLocation() ?? manager.location {
            self.currentLocation = location
        }
        
        manager.delegate = self
    }
    
    func immediateLocation() -> CLLocation? {
        let location = self.locationManager.immediateLocation() ?? manager.location
        return location
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func start() {
        print("authorization status: \(manager.authorizationStatus)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:  // Location services are available.
            DispatchQueue.main.async {
                self.deniedStatus = false
            }
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
#if os(tvOS)
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
#else
            manager.startUpdatingLocation()
#endif
            break
            
        case .restricted, .denied:  // Location services currently unavailable.
            DispatchQueue.main.async {
                self.deniedStatus = true
            }
            break
            
        case .notDetermined:        // Authorization not determined yet.
            DispatchQueue.main.async {
                self.deniedStatus = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                self?.manager.requestWhenInUseAuthorization()
            })
            break
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("CLLocationManager did update locations")
        for location in locations {
            print(location.coordinate.latitude, location.coordinate.longitude)
        }
        print("Total locations: \(locations.count)")
        if readyForUpdate {
            print("Ready for update")
            if let currentLocation = locations.first, currentLocation != self.currentLocation {
                DispatchQueue.global(qos: .background).async {
                    UserDefaults.standard.setValue("\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)", forKey: LocationManager.Config.latLongStorageKey)
                }
                DispatchQueue.main.async {
                    self.currentLocation = currentLocation
                    self.readyForUpdate = false
                    self.addressInfoIsUpdated = true
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) {
            self.start()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error.localizedDescription)
    }
    
    func stop() {
        manager.stopUpdatingLocation()
    }
    
    static func getCoordinate( addressString : String, lat: Float?, lng: Float?,
            completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        
        let geocoder = CLGeocoder()
        let newOrder = addressString.split(separator: "--").reversed().joined(separator: ", ")
        geocoder.geocodeAddressString(newOrder) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                        
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
            print("\(addressString), new order: \(newOrder), is not a valid address according to Apple\nTrying lat and lng")
            let newGeocoder = CLGeocoder()
            guard let lat = lat, let lng = lng else {
                completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
                return
            }
            newGeocoder.reverseGeocodeLocation(CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))) { (placemarks, error) in
                if error == nil {
                    if let placemark = placemarks?[0] {
                        let location = placemark.location!
                            
                        completionHandler(location.coordinate, nil)
                        return
                    }
                }
                completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
            }
        }
    }
}

extension Date {
    public func description() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha EEEE"
        return formatter.string(from: self)
    }
    
    public func longDescription() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
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
            print(error.localizedDescription)
            return []
        }
    }
}
