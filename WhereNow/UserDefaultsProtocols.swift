//
//  Objects.swift
//  WhereNow
//
//  Created by Jon on 7/29/24.
//


import MapKit
import Foundation
import CoreLocation
import SwiftUI

protocol LocationStorageManaging {
    func set(location: CLLocation, forKey key: String)
    func location(forKey key: String) -> CLLocation?
}

protocol WeatherStorageManaging {
    func set(weather: ForecastInfo, forKey key: String)
    func weather(forKey key: String) -> ForecastInfo?
}

// MARK: - Helpers
