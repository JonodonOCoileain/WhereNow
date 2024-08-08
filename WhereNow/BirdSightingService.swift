//
//  BirdSightingService.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import Foundation
import SwiftUI
import CoreLocation

struct BirdSightingRequestResponse: Codable {
    let sightings: [BirdSighting]
}

struct BirdSighting: Codable, Hashable {
    let speciesCode: String?
    let comName: String?
    let sciName: String?
    let locId: String?
    let locName: String?
    let obsDt: String?
    let howMany: Int?
    let lat: Float?
    let lng: Float?
    let obsValid: Bool?
    let obsReviewed: Bool?
    let locationPrivate: Bool?
    
    func description() -> String {
        let commonName = comName ?? ""
        let sciName = sciName ?? ""
        let howMany = howMany ?? 1
        let locName = locName ?? ""
        let obsDt = obsDt ?? ""
        let locationPrivate = locationPrivate ?? false
        
        let description = "\(commonName)\n\(sciName)\nQuantity: \(howMany)\nAt Location: \(locName)\nOn Date: \(obsDt)\nIn public location: \(locationPrivate == false)"
        return description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(speciesCode)
        hasher.combine(comName)
        hasher.combine(sciName)
        hasher.combine(locId)
        hasher.combine(locName)
        hasher.combine(obsDt)
        hasher.combine(howMany)
        hasher.combine(lat)
        hasher.combine(lng)
        hasher.combine(obsValid)
        hasher.combine(obsReviewed)
        hasher.combine(locationPrivate)
    }
}

class BirdSightingService: ObservableObject {
    public static let apiKey = "4ubf1p4of0js"
    public static let BaseURLString: String = "https://api.ebird.org/v2/data/obs/geo/recent"
    
    typealias SightingsRequestCompletionHandler = (Result<[BirdSighting], Error>) -> Void
    typealias SightingsRequestResult = Result<[BirdSighting], Error>

    var sightings: [BirdSighting] = [] {
        didSet {
            birdSeenCommonDescription = sightings.compactMap({$0.comName}).joined(separator: ", ")
        }
    }
    @Published var birdSeenCommonDescription: String?
    
    init(sightings: [BirdSighting] = []) {
        self.sightings = sightings
    }
    
    func makeRequest(using coordinate: CLLocationCoordinate2D) -> URLRequest? {
        let latitudeURLQueryItem = URLQueryItem(name: "lat", value: String(coordinate.latitude))
        let longitudeURLQueryItem = URLQueryItem(name: "lng", value: String(coordinate.longitude))
        let sortingURLQueryItem = URLQueryItem(name: "sort", value: "date")
        let queryItems:[URLQueryItem] = [latitudeURLQueryItem, longitudeURLQueryItem, sortingURLQueryItem]
        guard let baseURL = URL(string:BirdSightingService.BaseURLString) else { return nil}
        let finalURL = baseURL.appending(queryItems: queryItems)
        var request = URLRequest(url: finalURL)
        request.addValue("\(BirdSightingService.apiKey)", forHTTPHeaderField: "X-eBirdApiToken")
        return request
    }
    
    func cacheSightings(using coordinate: CLLocationCoordinate2D) {
        guard let request = makeRequest(using: coordinate) else { return }
        let dataTask = URLSession(configuration: .ephemeral).dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data else {
                print(error?.localizedDescription ?? "Error retrieving forecast data")
                return
            }
            do {
                //let something = JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.sightings = decodedSightings
                }
            } catch {
                let description = error.localizedDescription
                print(description)
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 4, execute: { [weak self] in
                    let coordinate = CoreLocation.CLLocationManager().location?.coordinate ?? coordinate
                    self?.cacheSightings(using: coordinate)
                })
            }
        })
        dataTask.resume()
    }
    
    func getSightings(using coordinate: CLLocationCoordinate2D) async -> [BirdSighting] {
        guard let request = makeRequest(using: coordinate) else { return []}
        do {
            let data = try await URLSession(configuration: .ephemeral).data(for: request).0
            let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
            self.sightings = decodedSightings
            
            return sightings
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}
