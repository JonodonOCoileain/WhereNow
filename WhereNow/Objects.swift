//
//  Objects.swift
//  WhereNow
//
//  Created by Jon on 7/29/24.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit
import WidgetKit

public enum AnError: Error {
    case Unknown
}

public struct LocationInformation {
    /// The resolved user location.
    let userLocation: CLLocation

    /// The map-snapshot image for the resolved user location.
    let image: Image?
    
    /// Location metadata from TomTom
    var addresses: [Address]?
}


struct LocationInformationEntry: TimelineEntry {
    // MARK: - Types

    enum State {
        /// The timeline provider asked for a placeholder.
        case placeholder

        /// We resolved a user-location and successfully created the map-snapshot.
        case success(LocationInformation)

        /// An error occurred.
        case failure(Error)
    }

    // MARK: - Public properties

    /// The date to display the widget. This property is required by the protocol `TimelineEntry`.
    let date: Date

    /// The current state of our entry.
    let state: State
    
    var shortDescription: String {
        switch self.state {
        case .placeholder:
            return "Planet Earth, Milky Way Galaxy"
        case .success(let locationInformation):
            let shortAddressArray: [String] = locationInformation.addresses?.compactMap({$0.formattedVeryShort()}) ?? ["Planet Earth, Milky Way Galaxy"]
            return shortAddressArray.joined(separator: "\n")
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

public struct ErrorView: View {
    // MARK: - Config

    private enum Config {
        /// The color to use as a background in case we have an invalid map image.
        static let fallbackColor = Color(red: 225 / 255,
                                         green: 239 / 255,
                                         blue: 210 / 255)
    }

    // MARK: - Public properties

    let errorMessage: String?

    // MARK: - Render

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            Config.fallbackColor
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .padding()
            }
        }
    }
}


protocol LocationStorageManaging {
    func set(location: CLLocation, forKey key: String)
    func location(forKey key: String) -> CLLocation?
}

/// Based on <https://stackoverflow.com/a/29987303/3532505> and <https://stackoverflow.com/a/27848617/3532505>.
extension UserDefaults: LocationStorageManaging {
    func set(location: CLLocation, forKey key: String) {
        do {
            let encodedLocationData = try NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: true)
            set(encodedLocationData, forKey: key)
        } catch {
            "Could not store location in user-defaults: \(error.localizedDescription)".log(level: .error)
        }
    }

    func location(forKey key: String) -> CLLocation? {
        guard let decodedLocationData = data(forKey: key) else {
            "Couldn't find location data for key \(key)".log(level: .error)
            return nil
        }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: decodedLocationData)
        } catch {
            "Couldn't decode location: \(error.localizedDescription)".log(level: .error)
            return nil
        }
    }
}

// MARK: - Helpers



//
//  String+Log.swift
//  MapWidget
//
//  Created by Felix Mau on 15.10.20.
//  Copyright © 2020 Felix Mau. All rights reserved.
//
/// Based on: https://gist.github.com/fxm90/08a187c5d6b365ce2305c194905e61c2
extension String {
    // MARK: - Types

    enum LogLevel {
        case info
        case error
    }

    // MARK: - Private properties

    /// The formatter we use to prefix the log output with the current date and time.
    private static let logDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"

        return dateFormatter
    }()

    // MARK: - Public methods

    func log(level: LogLevel, file: String = #file, function _: String = #function, line: UInt = #line) {
        #if DEBUG
            let logIcon: Character
            switch level {
            case .info:
                logIcon = "ℹ️"

            case .error:
                logIcon = "⚠️"
            }

            let formattedDate = Self.logDateFormatter.string(from: Date())
            let filename = URL(fileURLWithPath: file).lastPathComponent

            print("\(logIcon) – \(formattedDate) – \(filename):\(line) \(self)")
        #endif
    }
}

extension CoreLocation.CLLocation {
    func getAddresses() async -> [Address] {
        let coordinate = self.coordinate
        guard let url = URL(string: "https://api.tomtom.com/search/2/reverseGeocode/\(coordinate.latitude),\(coordinate.longitude).json?key=FBSjYeqToGYAeG2A5txodKfGHrql38S4&radius=100") else { return [] }
        var addresses: [Address] = []
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let newResponse = try JSONDecoder().decode(Response.self, from: data)
            let newAddresses = newResponse.addresses.compactMap({$0.address})
            addresses = newAddresses
        } catch {
            print(error.localizedDescription)
            do {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(self)
                
                let newAddresses = placemarks.compactMap({$0.asAddress()})
                addresses = newAddresses
            } catch {
                print(error.localizedDescription)
            }
        }
        return addresses
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
    func flag() -> String {
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
        return flag
    }
    
    func formattedLarge() -> String {
        let addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ",") ?? ""].joined(separator: " "),[municipality ?? "",countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: " "),[extendedPostalCode ?? postalCode ?? "",country ?? ""].joined(separator: " ")]
        return addressInfo.joined(separator: "\n")
    }
    
    func formattedCommonLong() -> String {
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
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),municipality ?? "",[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
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
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[municipality ?? "",countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        if flag.isEmpty {
            return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return (addressInfo.joined(separator: "\n") + " " + flag).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func checkNumeric(S: String) -> Bool {
       return Double(S) != nil
    }
    
    func formattedVeryShort() -> String {
        if var streetArray = streetName?.components(separatedBy: " ") as? [String] {
            if streetArray.last?.count == 2, streetArray.count > 1 {
                streetArray.removeLast()
            }
            if streetArray.last?.count == 2, let number = streetArray.first, checkNumeric(S: number) {
                streetArray.removeFirst()
            }
            if let streetName = streetName, localName?.contains(streetName) != true {
                return streetArray.joined(separator: " ") + ", " + (localName ?? municipality ?? "")
            } else {
                return streetArray.joined(separator: " ") + ", " + (municipality ?? "")
            }
        } else {
            if (streetName?.count ?? 0) >= 1 {
                if let streetName = streetName, localName?.contains(streetName) != true {
                    return (streetName ?? "") + ", " + (localName ?? municipality ?? "")
                } else {
                    return (streetName ?? "") + ", " + (municipality ?? "")
                }
            } else {
                return localName ?? municipality ?? ""
            }
        }
    }
    
    func formattedCommonLongFlag() -> String {
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
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),municipality ?? "",[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        if flag.isEmpty {
            return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return (flag + "\n" + addressInfo.joined(separator: "\n")).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func formattedCommonVeryLongFlag() -> String {
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
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),municipality ?? "", countrySecondarySubdivision ?? "", countrySubdivision ?? "",postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivision ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        addressInfo.removeAll(where: { $0 == "" })
        if flag.isEmpty {
            return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return (flag + "\n" + addressInfo.joined(separator: "\n")).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

struct BoundingBox: Codable, Equatable {
    var northEast: String?
    var southWest: String?
    var entity: String?
}

extension CLPlacemark {
    func asAddress() -> Address {
        print("starting conversion")
        let address = Address(buildingNumber: nil, streetNumber: self.subThoroughfare, routeNumbers: nil, street: self.thoroughfare, streetName: self.addressDictionary?["Street"] as? String, streetNameAndNumber: (self.subThoroughfare ?? "") + " " + (self.thoroughfare ?? ""), countryCode: self.isoCountryCode, countrySubdivision: self.administrativeArea, countrySecondarySubdivision: self.subAdministrativeArea, municipality: self.locality ?? self.addressDictionary?["City"] as? String, postalCode: self.postalCode, neighborhood: self.subLocality, country: self.country, countryCodeISO3: self.isoCountryCode, freeformAddress: (self.addressDictionary?["FormattedAddressLines"] as? [String])?.joined(separator: ","), boundingBox: nil, extendedPostalCode: nil, countrySubdivisionName: self.region?.description ?? "", countrySubdivisionCode: nil, localName: self.name ?? self.addressDictionary?["Name"] as? String)
        print("completed conversion")
        return address
    }
}
