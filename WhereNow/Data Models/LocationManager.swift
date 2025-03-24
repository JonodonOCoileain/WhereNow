//
//  LocationManager.swift
//  WhereNow
//
//  Created by Jon on 7/31/24.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject {
    // MARK: - Config

    public enum Config {
        /// The type of user activity associated with the location updates.
        static let activityType: CLActivityType = .otherNavigation

        /// The accuracy of the location data we want to receive.
        static let desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        /// The key we use to store the last known user location.
        static let storageKey = "lastKnownUserLocation"
        
        static let latLongStorageKey = "latLongStorageKey"
    }

    // MARK: - Types

    typealias RequestLocationCompletionHandler = (Result<CLLocation, Error>) -> Void

    // MARK: - Private properties

    private var requestLocationCompletionHandlers = [RequestLocationCompletionHandler]()

    // MARK: - Dependencies

    public var locationManager: CLLocationManager?
    private let locationStorageManager: LocationStorageManaging

    // MARK: - Initializer

    init(locationStorageManager: LocationStorageManaging) {
        self.locationStorageManager = locationStorageManager

        super.init()

        setupLocationManager()
    }

    // MARK: - Public methods

    func requestLocation(_ completionHandler: @escaping RequestLocationCompletionHandler) async {
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
    
    func immediateLocation() -> CLLocation? {
        guard let locationManager = locationManager else {
            "Expect to have a valid `locationManager` instance at this point!"
                .log(level: .error)
            
            return locationStorageManager.location(forKey: Config.storageKey)
        }
        if locationManager.authorizationStatus.isAuthorized {
            locationManager.requestLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        return locationManager.location ?? locationStorageManager.location(forKey: Config.storageKey)
    }
    
    static func locationFrom(postalCode: String) async -> CLPlacemark? {
        let geoCoder = CLGeocoder()
        do {
            let location = try await geoCoder.geocodeAddressString(postalCode).first
            return location
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func locationFrom(address: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address, in: nil, preferredLocale: Locale.current) { placemarks, error in
            if let placemarks = placemarks, let location = placemarks.first?.location {
                self.locationStorageManager.set(location: location, forKey: Config.storageKey)
                UserDefaults.standard.set("\(location.coordinate.latitude),\(location.coordinate.longitude)", forKey: Config.latLongStorageKey)
            } else if let error = error {
                print(error)
            }
        }
    }

    // MARK: - Private properties

    private func setupLocationManager() {
        // We have to explicitly make sure to intialize the location manger on the main thread.
        // This is not happening per default when instantiating the widget.
        DispatchQueue.main.async {
            let locationManager = CLLocationManager()
            self.locationManager = locationManager
#if os(tvOS)
#else
            locationManager.activityType = Config.activityType
#endif
            locationManager.desiredAccuracy = Config.desiredAccuracy
            locationManager.delegate = self
            self.locationManager?.requestWhenInUseAuthorization()
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
            // Ignore authorization changes where we lose access to location data.
            return
        }

        guard !requestLocationCompletionHandlers.isEmpty else {
            // Ignore changes where we don't have any pending completion handlers.
            return
        }
#if os(tvOS)
#else
        self.locationManager?.startUpdatingLocation()
#endif
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
        #if os(macOS)
        self == .authorizedAlways
        #else
        self == .authorizedAlways || self == .authorizedWhenInUse
        #endif
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
