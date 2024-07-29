//
//  LocationDataModel.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//

import CoreLocation

class LocationDataModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    var readyForUpdate:Bool = true
    var timer: Timer?
    @objc func fireTimer() {
        self.readyForUpdate = true
    }
    @Published var currentLocation: CLLocation? {
        didSet {
            guard let coordinate = currentLocation?.coordinate, let url = URL(string: "https://api.tomtom.com/search/2/reverseGeocode/\(coordinate.latitude),\(coordinate.longitude).json?key=FBSjYeqToGYAeG2A5txodKfGHrql38S4&radius=100") else { return }
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                print(String(data: data, encoding: .utf8)!)
                do {
                    let newResponse = try JSONDecoder().decode(Response.self, from: data)
                    self.addresses = newResponse.addresses.compactMap({$0.address})
                } catch {
                    print(error.localizedDescription)
                }
            }
            task.resume()
            
            /* Apple only allows 1 request per minute of geocoding (ridiculous)
             * This code has been deprecated using TomTom
            currentLocation?.getPlaces(with: { placemarks in
                if let placemarks = placemarks {
                    self.placemarks = placemarks
                    self.placemarkInfo = placemarks.compactMap({$0.makeAddressString()})
                    self.addressInfoIsUpdated = true
                } else {
                    self.addressInfoIsUpdated = false
                }
            })*/
        }
    }
    var countries: [String:String] = [:]
    var manager: CLLocationManager = CLLocationManager()
    //@Published var placemarks: [CLPlacemark] = []
    //@Published var placemarkInfo: [String] = [""]
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
                flag = String(s) //Flag update
            }
        }
    }
    
    init(timer: Bool = true, start: Bool = false) {
        super.init()
        if timer {
            self.timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
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
    
    func getFlag(of placemark:CLPlacemark) {
        var countries: [String:String] = [:]
        for code in NSLocale.isoCountryCodes {
            let id: String = Locale.identifier(fromComponents: [
                NSLocale.Key.countryCode.rawValue : code
            ])
            guard let name = (Locale.current as NSLocale).displayName(forKey: .identifier, value: id) else { continue }
            countries[code] = name
        }
        if let countryCode = countries.keys.first(where: { countries[$0] == placemark.country }) {
            let base : UInt32 = 127397
            var s = ""
            for v in countryCode.unicodeScalars {
                s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
            self.flag = String(s)
        }
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
        print("Total of locations: \(locations.count)")
        if readyForUpdate {
            currentLocation = locations.first
            readyForUpdate = false
        }
        print(locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error.localizedDescription)
    }
    
    func stop() {
        manager.stopUpdatingLocation()
    }
}

struct Response: Codable {
    var summary: Summary?
    var addresses: [AddressPair]
}

struct AddressPair: Codable {
    var address: Address
}

struct Summary: Codable {
    var queryTime: Int?
    var numResults: Int?
}

struct Addresses: Codable {
    var address: Address?
}

struct Address: Codable {
    var buildingNumber: String?
    var streetNumber: String?
    var routeNumbers: [String]?
    var street: String?
    var streetName: String?
    var streetNameAndNumber: String?
    var countryCode: String?
    var countrySubdivision: String?
    var countrySecondarySubdivision: String?
    var municipality:String?
    var postalCode: String?
    var neighborhood: String?
    var country: String?
    var countryCodeISO3: String?
    var freeformAddress: String?
    var boundingBox: BoundingBox?
    var extendedPostalCode:String?
    var countrySubdivisionName:String? //State
    var countrySubdivisionCode:String?
    var localName: String? //Town
}

struct BoundingBox: Codable {
    var northEast: String?
    var southWest: String?
    var entity: String?
}
