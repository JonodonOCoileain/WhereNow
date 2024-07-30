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

public struct MapSnapshot {
    /// The resolved user location.
    let userLocation: CLLocation

    /// The map-snapshot image for the resolved user location.
    let image: Image?
    
    /// Location metadata from TomTom
    var addresses: [Address]?
}


struct SimpleEntry: TimelineEntry {
    // MARK: - Types

    enum State {
        /// The timeline provider asked for a placeholder.
        case placeholder

        /// We resolved a user-location and successfully created the map-snapshot.
        case success(MapSnapshot)

        /// An error occurred.
        case failure(Error)
    }

    // MARK: - Public properties

    /// The date to display the widget. This property is required by the protocol `TimelineEntry`.
    let date: Date

    /// The current state of our entry.
    let state: State
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

final class LocationManager: NSObject {
    // MARK: - Config

    private enum Config {
        /// The type of user activity associated with the location updates.
        static let activityType: CLActivityType = .otherNavigation

        /// The accuracy of the location data we want to receive.
        static let desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        /// The key we use to store the last known user location.
        static let storageKey = "MapWidgetExample.lastKnownUserLocation"
    }

    // MARK: - Types

    typealias RequestLocationCompletionHandler = (Result<CLLocation, Error>) -> Void

    // MARK: - Private properties

    private var requestLocationCompletionHandlers = [RequestLocationCompletionHandler]()

    // MARK: - Dependencies

    private var locationManager: CLLocationManager?
    private let locationStorageManager: LocationStorageManaging

    // MARK: - Initializer

    init(locationStorageManager: LocationStorageManaging) {
        self.locationStorageManager = locationStorageManager

        super.init()

        setupLocationManager()
    }

    // MARK: - Public methods

    func requestLocation(_ completionHandler: @escaping RequestLocationCompletionHandler) {
        requestLocationCompletionHandlers.append(completionHandler)

        guard let locationManager = locationManager else {
            "Expect to have a valid `locationManager` instance at this point!"
                .log(level: .error)

            return
        }

        if locationManager.authorizationStatus.isAuthorized {
            locationManager.requestLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Private properties

    private func setupLocationManager() {
        // We have to explicitly make sure to intialize the location manger on the main thread.
        // This is not happening per default when instantiating the widget.
        DispatchQueue.main.async {
            let locationManager = CLLocationManager()
            self.locationManager = locationManager

            locationManager.activityType = Config.activityType
            locationManager.desiredAccuracy = Config.desiredAccuracy
            locationManager.delegate = self
        }
    }

    private func resolveRequestLocationCompletionHandlers(with result: Result<CLLocation, Error>) {
        requestLocationCompletionHandlers.forEach { $0(result) }
        requestLocationCompletionHandlers.removeAll()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus.isAuthorized else {
            // Ignore authorization changes where we loose access to location data.
            return
        }

        guard !requestLocationCompletionHandlers.isEmpty else {
            // Ignore changes where we don't have any pending completion handlers.
            return
        }

        locationManager?.requestLocation()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // We explicitly ask for the `first` location here, as with `requestLocation()` only one location fix is reported to the delegate.
        // https://developer.apple.com/documentation/corelocation/cllocationmanager/1620548-requestlocation
        guard let userLocation = locations.first else {
            return
        }

        locationStorageManager.set(location: userLocation, forKey: Config.storageKey)

        resolveRequestLocationCompletionHandlers(with: .success(userLocation))
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == CLError.Code.locationUnknown {
            // > If the location service is unable to retrieve a location right away, it reports a `CLError.Code.locationUnknown` error and
            // > keeps trying. In such a situation, you can simply ignore the error and wait for a new event.
            // https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423786-locationmanager
            return
        }

        if let lastKnownUserLocation = locationStorageManager.location(forKey: Config.storageKey) {
            // We've previously resolved a location, and therefore use it as a fallback.
            resolveRequestLocationCompletionHandlers(with: .success(lastKnownUserLocation))
        } else {
            resolveRequestLocationCompletionHandlers(with: .failure(error))
        }
    }
}

// MARK: - Helpers

private extension CLAuthorizationStatus {
    /// Boolean flag whether we're authorized to access location data.
    var isAuthorized: Bool {
        self == .authorizedAlways || self == .authorizedWhenInUse
    }
}


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
