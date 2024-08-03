//
//  MapSnapshotManager.swift
//  WhereNow
//
//  Created by Jon on 7/31/24.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

final class MapSnapshotManager {
    // MARK: - Types

    typealias SnapshotCompletionHandler = (Result<Image, Error>) -> Void
    typealias SnapshotResult = Result<Image, Error>

    enum SnapshotError: Error {
        case noSnapshotImage
    }

    // MARK: - Config

    private enum Config {
        /// The coordinate span to use when rendering the map.
        ///
        /// - SeeAlso: https://developer.apple.com/documentation/mapkit/mkcoordinatespan
        static let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.005,
                                                     longitudeDelta: 0.005)
    }

    // MARK: - Public methods
    
    func snapshot(at centerCoordinate: CLLocationCoordinate2D,
                  completionHandler: @escaping SnapshotCompletionHandler) {
        //iOS 7.0+
        //iPadOS 7.0+
        //Mac Catalyst 13.1+
        //macOS 10.9+
        //tvOS 9.2+
        //visionOS 1.0+
        let coordinateRegion = MKCoordinateRegion(center: centerCoordinate,
                                                  span: Config.coordinateSpan)
        
        let options = MKMapSnapshotter.Options()
        options.region = coordinateRegion
        MKMapSnapshotter(options: options).start { snapshot, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completionHandler(.failure(SnapshotError.noSnapshotImage))
                return
            }
            
            let image = Image(uiImage: snapshot.image)
            completionHandler(.success(image))
        }
    }
    
    func snapshot(of coordinate: CLLocationCoordinate2D) async -> SnapshotResult {
        //iOS 7.0+
        //iPadOS 7.0+
        //Mac Catalyst 13.1+
        //macOS 10.9+
        //tvOS 9.2+
        //visionOS 1.0+
        let coordinateRegion = MKCoordinateRegion(center: coordinate,
                                                  span: Config.coordinateSpan)
        
        let options = MKMapSnapshotter.Options()
        options.region = coordinateRegion
        do {
            let result: MKMapSnapshotter.Snapshot = try await MKMapSnapshotter(options: options).start()
            let uiImage: UIImage = result.image
            let image = Image(uiImage: uiImage)
            return .success(image)
        } catch {
            return .failure(error)
        }
        
    }
}
