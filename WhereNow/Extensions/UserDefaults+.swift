//
//  UserDefaults+.swift
//  WhereNow
//
//  Created by Jonathan Lavallee Collins on 3/21/25.
//

import Foundation
import CoreLocation
import OSLog

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

extension UserDefaults: WeatherStorageManaging {
    func set(weather: ForecastInfo, forKey key: String) {
        do {
            let encodedLocationData = try NSKeyedArchiver.archivedData(withRootObject: weather, requiringSecureCoding: true)
            set(encodedLocationData, forKey: key)
        } catch {
            "Could not store location in user-defaults: \(error.localizedDescription)".log(level: .error)
        }
    }

    func weather(forKey key: String) -> ForecastInfo? {
        guard let decodedLocationData = data(forKey: key) else {
            "Couldn't find location data for key \(key)".log(level: .error)
            return nil
        }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: ForecastInfo.self, from: decodedLocationData)
        } catch {
            "Couldn't decode location: \(error.localizedDescription)".log(level: .error)
            return nil
        }
    }
}
