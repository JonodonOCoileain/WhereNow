//
//  SnapshotManager.swift
//  WhereNow
//
//  Created by Jon on 7/30/24.
//
import SwiftUI
import MapKit
import WidgetKit

final class SnapshotManager {
    // MARK: - Types

    typealias SnapshotCompletionHandler = (Result<Image, Error>) -> Void

    enum SnapshotError: Error {
        case noSnapshotImage
        case noAddresses
        case wrongOS
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
        #if os(watchOS)
        completionHandler(.failure(SnapshotError.wrongOS))
        #else
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
    #endif
    }
}
