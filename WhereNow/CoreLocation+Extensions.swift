//
//  CL+Extensions.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//
import CoreLocation
extension CLLocation {
    func getPlaces(with completion: @escaping ([CLPlacemark]?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(self) { placemarks, error in
            
            guard error == nil else {
                print("*** Error in \(#function): \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemarks = placemarks else {
                print("*** Error in \(#function): placemarks is nil")
                completion(nil)
                return
            }
            
            completion(placemarks)
        }
    }
}
/* Deprecated using TomTom
extension CLPlacemark {
    func makeAddressString() -> String {
        var countries: [String:String] = [:]
        var flag: String? = nil
        for code in NSLocale.isoCountryCodes {
            let id: String = Locale.identifier(fromComponents: [
                NSLocale.Key.countryCode.rawValue : code
            ])
            guard let name = (Locale.current as NSLocale).displayName(forKey: .identifier, value: id) else { continue }
            countries[code] = name
        }
        if let countryCode = countries.keys.first(where: { countries[$0] == country }) {
            let base : UInt32 = 127397
            var s = ""
            for v in countryCode.unicodeScalars {
                s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
            flag = String(s)
        }
        //UserDefaults.standard.setValue(self.thoroughfares(), forKey: "thoroughfares")
        //UserDefaults.standard.setValue(self.localityAndAdministrativeArea(), forKey: "localityAndAdministrative")
        UserDefaults.standard.setValue(self.streetAndTown(), forKey: "Street_and_Town")
        return [flag,[subThoroughfare, thoroughfare].compactMap({ $0 }).joined(separator:" "), [locality, administrativeArea].compactMap({ $0 }).joined(separator:", "), postalCode, (country ?? "")]
            .compactMap({ $0 })
            .joined(separator: "\n")
    }
    
    func thoroughfares() -> String {
        return [subThoroughfare, thoroughfare].compactMap({ $0 }).joined(separator:" ")
    }
    
    func localityAndAdministrativeArea() -> String {
        return [locality, administrativeArea].compactMap({ $0 }).joined(separator:", ")
    }
    
    func streetAndTown() -> String {
        var streetInfoArray = thoroughfare?.split(separator:" ")
        
        if streetInfoArray?.count ?? 0 > 1 {
            _ = streetInfoArray?.popLast()
        }
        let streetInfo = streetInfoArray?.joined(separator: " ") ?? ""
        
        return[streetInfo.trimmingCharacters(in: .whitespacesAndNewlines), locality?.trimmingCharacters(in: .whitespacesAndNewlines)].compactMap({ $0 }).joined(separator:",")
    }
    
    func numberStreetAndTown() -> String {
        return[subThoroughfare?.trimmingCharacters(in: .whitespacesAndNewlines), thoroughfare?.trimmingCharacters(in: .whitespacesAndNewlines), locality?.trimmingCharacters(in: .whitespacesAndNewlines)].compactMap({ $0 }).joined(separator:" ")
    }
    
    func thoroughfaresAndLocality() -> String {
        return [subThoroughfare, thoroughfare, locality].compactMap({ $0 }).joined(separator:" ")
    }
    
    func codeAndCountry() -> String {
        return [postalCode, (country ?? "")]
            .compactMap({ $0 }).joined(separator: " ")
    }
}*/
