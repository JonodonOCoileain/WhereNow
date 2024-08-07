//
//  LocationInformation.swift
//  WhereNow
//
//  Created by Jon on 8/6/24.
//


import Foundation
import CoreLocation
import SwiftUI

public struct LocationInformation {
    /// The resolved user location.
    let userLocation: CLLocation

    /// The map-snapshot image for the resolved user location.
    let image: Image?
    
    /// Location metadata from TomTom
    var addresses: [Address]?
    /// Weather data from NOAA
    var weather: [ForecastInfo]?
}