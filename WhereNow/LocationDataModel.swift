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
            currentLocation = locations.first
            readyForUpdate = false
            addressInfoIsUpdated = currentLocation != nil
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

struct Address: Codable, Equatable {
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
    
    func formattedLarge() -> String {
        let addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ",") ?? ""].joined(separator: " "),[municipality ?? "",countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: " "),[extendedPostalCode ?? postalCode ?? "",country ?? ""].joined(separator: " ")]
        return addressInfo.joined(separator: "\n")
    }
    
    func formattedCommon() -> String {
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[localName ?? municipality ?? "",countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        return addressInfo.joined(separator: "\n")
    }
    
    func formattedCommonWithFlag() -> String {
        var countries: [String:String] = [:]
        for code in NSLocale.isoCountryCodes {
            let id: String = Locale.identifier(fromComponents: [
                NSLocale.Key.countryCode.rawValue : code
            ])
            guard let name = (Locale.current as NSLocale).displayName(forKey: .identifier, value: id) else { continue }
            countries[code] = name
        }
        
        var flag: String = ""
        if let countryCode = countries.keys.first(where: { countries[$0] == self.country }) {
            let base : UInt32 = 127397
            var s = ""
            for v in countryCode.unicodeScalars {
                s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
            if flag != String(s) {
                flag = String(s) //Flag update
            }
        }
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[localName ?? municipality ?? "",countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        if flag.isEmpty {
            return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return (addressInfo.joined(separator: "\n") + " " + flag).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func formattedVeryShort() -> String {
        if var streetArray = streetName?.components(separatedBy: " ") as? [String] {
            if streetArray.last?.count == 2, streetArray.count > 1 {
                streetArray.removeLast()
            }
            return streetArray.joined(separator: " ") + ", " + (localName ?? municipality ?? "")
        } else {
            if (streetName?.count ?? 0) >= 1 {
                return (streetName ?? "") + ", " + (localName ?? municipality ?? "")
            } else {
                return localName ?? municipality ?? ""
            }
        }
    }
}

struct BoundingBox: Codable, Equatable {
    var northEast: String?
    var southWest: String?
    var entity: String?
}
