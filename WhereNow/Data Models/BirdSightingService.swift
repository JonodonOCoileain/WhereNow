//
//  BirdSightingService.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import Foundation
import SwiftUI
import CoreLocation
import AVFoundation

class BirdSpeciesAssetMetadata: Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var id: Int { identifier }
    
    let identifier: Int
    let expectedIndex: Int
    let speciesCode: String
    let assetFormatCode: String
    let url: String
    let uploadedBy: String
    let citationUrl: String
    var baseURL: String? = nil
    var comName: String? = nil
    var sciName: String? = nil
    var description: String? = nil
    @Published var image: Data? = nil
    
    enum ChildKeys: CodingKey {
        case id, description, identifier, expectedIndex, speciesCode, assetFormatCode, url, uploadedBy, citationUrl, baseURL, comName, sciName, image
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ChildKeys.self)
        self.identifier = try container.decode(Int.self, forKey: .identifier)
        self.expectedIndex = try container.decodeIfPresent(Int.self, forKey: .expectedIndex) ?? 0
        self.speciesCode = try container.decodeIfPresent(String.self, forKey: .speciesCode) ?? ""
        self.assetFormatCode = try container.decodeIfPresent(String.self, forKey: .assetFormatCode) ?? ""
        self.url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.uploadedBy = try container.decodeIfPresent(String.self, forKey: .uploadedBy) ?? ""
        self.citationUrl = try container.decodeIfPresent(String.self, forKey: .citationUrl) ?? ""
        self.baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL)
        self.comName = try container.decodeIfPresent(String.self, forKey: .comName)
        self.sciName = try container.decodeIfPresent(String.self, forKey: .sciName)
        self.image = try container.decodeIfPresent(Data.self, forKey: .image)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ChildKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encodeIfPresent(self.expectedIndex, forKey: .expectedIndex)
        try container.encodeIfPresent(self.speciesCode, forKey: .speciesCode)
        try container.encodeIfPresent(self.assetFormatCode, forKey: .assetFormatCode)
        try container.encodeIfPresent(self.url, forKey: .url)
        try container.encodeIfPresent(self.uploadedBy, forKey: .uploadedBy)
        try container.encodeIfPresent(self.citationUrl, forKey: .citationUrl)
        try container.encodeIfPresent(self.baseURL, forKey: .baseURL)
        try container.encodeIfPresent(self.comName, forKey: .comName)
        try container.encodeIfPresent(self.sciName, forKey: .sciName)
        try container.encodeIfPresent(self.image, forKey: .image)
        try container.encodeIfPresent(self.description, forKey: .description)
    }
    
    init(identifier: Int, expectedIndex: Int, speciesCode: String, assetFormatCode: String, url: String, uploadedBy: String, citationUrl: String, baseURL: String? = nil, comName: String? = nil, sciName: String? = nil, image: Data? = nil, description: String? = nil) {
        self.identifier = identifier
        self.expectedIndex = expectedIndex
        self.speciesCode = speciesCode
        self.assetFormatCode = assetFormatCode
        self.url = url
        self.uploadedBy = uploadedBy
        self.citationUrl = citationUrl
        self.baseURL = baseURL
        self.comName = comName
        self.sciName = sciName
        self.image = image
        self.description = description
    }
    
    var generatedUrl: String {
        if let baseURL = baseURL?.replacingOccurrences(of: "\"", with: "") {
            return baseURL + "\(identifier)"
        } else {
            return url
        }
    }
    
    func retrieveImageData() {
        if image == nil, let url = URL(string: url) {
            
            let request = URLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                self?.image = data
            }
            task.resume()
        }
    }
    
    static func == (lhs: BirdSpeciesAssetMetadata, rhs: BirdSpeciesAssetMetadata) -> Bool {
        lhs.identifier == rhs.identifier &&
        lhs.expectedIndex == rhs.expectedIndex &&
        lhs.speciesCode == rhs.speciesCode &&
        lhs.assetFormatCode == rhs.assetFormatCode &&
        lhs.url == rhs.url &&
        lhs.uploadedBy == rhs.uploadedBy &&
        lhs.citationUrl == rhs.citationUrl &&
        lhs.baseURL == rhs.baseURL &&
        lhs.comName == rhs.comName &&
        lhs.sciName == rhs.sciName &&
        lhs.image == rhs.image &&
        lhs.description == rhs.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/*struct BirdImagesResponse: Codable {
    let results: [BirdImageMetadata]
}

struct BirdImageUser: Codable {
    let id: String
    let username: String
    let name: String
    let first_name: String
    let last_name: String
    let instagram_username: String
    let twitter_username: String
    let portfolio_url: String
    let profile_image: [String:String] //small, medium, large keys
    let links: [String:String] //self, html, photos, likes keys
}

struct BirdImageMetadata: Codable {
    let id: String
    let created_at: String
    let width: Int
    let height: Int
    let color: String
    let blur_hash: String
    let likes: Int
    let liked_by_user: Bool
    let desciprtion: String
    let user: BirdImageUser
    let urls: [String:String] //raw, full, regular, small, thumb
    let links: [String:String] //self, html, download
}*/

struct BirdSighting: Codable, Hashable, Identifiable, Observable, Equatable {
    let id = UUID()
    var speciesMediaMetadata: [BirdSpeciesAssetMetadata]? = []
    var pictureData: [Data]? = []
    var audioData: [Data]? = []
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
    
    static func == (lhs: BirdSighting, rhs: BirdSighting) -> Bool {
        return lhs.speciesCode == rhs.speciesCode &&
        lhs.locName == rhs.locName
    }
    
}

class BirdSightingService: ObservableObject {
    public static let notablesURLString:String =  "https://api.ebird.org/v2/data/obs/geo/recent/notable"//?lat={{lat}}&lng={{lng}}"
    public static let youTubeVideoBaseURL: String = "https://www.youtube.com/watch?v="
    public static let cornellUOrnithologyAPIKey = "4ubf1p4of0js"
    public static let unsplashAPIKey: String = ""
    public static let recentsURLString: String = "https://api.ebird.org/v2/data/obs/geo/recent"
    
    typealias SightingsRequestCompletionHandler = (Result<[BirdSighting], Error>) -> Void
    typealias SightingsRequestResult = Result<[BirdSighting], Error>
    
    @Published var sightings: [BirdSighting] = [] {
        didSet {
            let commonNames = sightings.compactMap({$0.comName})
            birdSeenCommonDescription = commonNames.joined(separator: ", ")
        }
    }
    
    @Published var notableSightings: [BirdSighting] = [] {
        didSet {
            let commonNames = notableSightings.compactMap({$0.comName})
            notableBirdsSeenCommonDescription = commonNames.joined(separator: ", ")
        }
    }
    
    @Published var birdYouTubeVideoURL: [String:String] = [:]
    @Published var birdSoundURL: [String:String] = [:]
    @Published var birdSeenCommonDescription: String?
    @Published var notableBirdsSeenCommonDescription: String?
    @Published var speciesMedia: [BirdSpeciesAssetMetadata] = []
    
    init(sightings: [BirdSighting] = []) {
        self.sightings = sightings
    }
    
    func retrieveImageData(of dataArray: [BirdSpeciesAssetMetadata]) {
        for data in dataArray {
            data.retrieveImageData()
        }
    }
    
    
    func downloadFileCompletionHandler(urlstring: String, named: String, completion: @escaping (URL?, Error?) -> Void) {
        
        let url = URL(string: urlstring)!
        let documentsUrl =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let destinationUrl = documentsUrl.appendingPathComponent(named)
        print(destinationUrl)
        
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("File already exists [\(destinationUrl.path)]")
            //            try! FileManager().removeItem(at: destinationUrl)
            completion(destinationUrl, nil)
            return
        }
        
        let request = URLRequest(url: url)
        
        
        let task = URLSession.shared.downloadTask(with: request) { tempFileUrl, response, error in
            //            print(tempFileUrl, response, error)
            if error != nil {
                completion(nil, error)
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let tempFileUrl = tempFileUrl {
                        print("download finished")
                        try! FileManager.default.moveItem(at: tempFileUrl, to: destinationUrl)
                        completion(destinationUrl, error)
                    } else {
                        completion(nil, error)
                    }
                    
                }
            }
            
        }
        task.resume()
    }
    
    func makeAudioRequest(using coordinate: CLLocationCoordinate2D) -> URLRequest? {
        let typeAudio = URLQueryItem(name: "type", value: "audio")
        let queryItems:[URLQueryItem] = [typeAudio]
        guard let baseURL = URL(string:BirdSightingService.recentsURLString) else { return nil}
        let finalURL = baseURL.appending(queryItems: queryItems)
        var request = URLRequest(url: finalURL)
        request.addValue("\(BirdSightingService.cornellUOrnithologyAPIKey)", forHTTPHeaderField: "X-eBirdApiToken")
        return request
    }
    
    func makeRequest(using coordinate: CLLocationCoordinate2D) -> URLRequest? {
        let latitudeURLQueryItem = URLQueryItem(name: "lat", value: String(coordinate.latitude))
        let longitudeURLQueryItem = URLQueryItem(name: "lng", value: String(coordinate.longitude))
        let sortingURLQueryItem = URLQueryItem(name: "sort", value: "date")
        let maxURLQueryItem = URLQueryItem(name: "maxResults", value: "100")
        let distItem = URLQueryItem(name: "dist", value: "22")
        let queryItems:[URLQueryItem] = [latitudeURLQueryItem, longitudeURLQueryItem, sortingURLQueryItem, maxURLQueryItem, distItem]
        guard let baseURL = URL(string:BirdSightingService.recentsURLString) else { return nil}
        let finalURL = baseURL.appending(queryItems: queryItems)
        var request = URLRequest(url: finalURL)
        request.addValue("\(BirdSightingService.cornellUOrnithologyAPIKey)", forHTTPHeaderField: "X-eBirdApiToken")
        return request
    }
    
    func makeNotablesRequest(using coordinate: CLLocationCoordinate2D) -> URLRequest? {
        let latitudeURLQueryItem = URLQueryItem(name: "lat", value: String(coordinate.latitude))
        let longitudeURLQueryItem = URLQueryItem(name: "lng", value: String(coordinate.longitude))
        let sortingURLQueryItem = URLQueryItem(name: "sort", value: "date")
        let maxURLQueryItem = URLQueryItem(name: "maxResults", value: "100")
        let distItem = URLQueryItem(name: "dist", value: "22")
        let queryItems:[URLQueryItem] = [latitudeURLQueryItem, longitudeURLQueryItem, sortingURLQueryItem, maxURLQueryItem, distItem]
        guard let notablesURL = URL(string:BirdSightingService.notablesURLString) else { return nil}
        let finalURL = notablesURL.appending(queryItems: queryItems)
        var request = URLRequest(url: finalURL)
        request.addValue("\(BirdSightingService.cornellUOrnithologyAPIKey)", forHTTPHeaderField: "X-eBirdApiToken")
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
    
    func cacheNotableSightings(using coordinate: CLLocationCoordinate2D) {
        guard let request = makeNotablesRequest(using: coordinate) else { return }
        let dataTask = URLSession(configuration: .ephemeral).dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data else {
                print(error?.localizedDescription ?? "Error retrieving notable bird sighting data")
                return
            }
            do {
                let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.notableSightings = decodedSightings
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 4, execute: { [weak self] in
                    let coordinate = CoreLocation.CLLocationManager().location?.coordinate ?? coordinate
                    self?.cacheNotableSightings(using: coordinate)
                })
            }
        })
        dataTask.resume()
    }
    
    func getNotableSightings(using coordinate: CLLocationCoordinate2D) async -> [BirdSighting] {
        guard let request = makeNotablesRequest(using: coordinate) else { return []}
        do {
            let data = try await URLSession(configuration: .ephemeral).data(for: request).0
            let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
            self.notableSightings = decodedSightings
            
            return notableSightings
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    func requestWebsiteOf(speciesCode: String, sighting: BirdSighting) {
        guard let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            print("failure to make species url of \(speciesCode)")
            return
        }
        guard let url = URL(string: "https://ebird.org/species/" + speciesURLString) else {
            print("failure to make species url of \(speciesCode): \(speciesURLString)")
            return
        }
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "GET"
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                
                // This is your file-variable:
                // data
                guard let parsedData = String(data: data!, encoding: String.Encoding.utf8) else { return }
                print(parsedData)
                var assets = parsedData.components(separatedBy: "\"assetId\" : ")
                assets.indices.reversed().forEach {
                    if $0 % 2 == 0 { assets.remove(at: $0) }
                }
                var ids: [Int] = []
                var assetIds: [String] = []
                var citationURLs: [String] = []
                for item in assets {
                    let components = item.components(separatedBy: ",")
                    if let assetInfo = components.first, let assetId = Int(assetInfo) {
                        ids.append(assetId)
                        assetIds.append("https://cdn.download.ams.birds.cornell.edu/api/v1/asset/"  + "\(assetId)")
                        //assetIds.append("https://macaulaylibrary.org/asset/" + "\(assetId)")
                    }
                    for component in components {
                        let array = component.split(separator: "\"citationUrl\" : ")
                        if let url = array.last {
                            citationURLs.append(String(url))
                        }
                    }
                }
                
                var assetFormatCodeArray = parsedData.components(separatedBy: "\"assetFormatCode\" : ")
                assetFormatCodeArray.indices.reversed().forEach {
                    if $0 % 2 == 0 { assetFormatCodeArray.remove(at: $0) }
                }
                var assetFormatCodes: [String] = []
                for item in assetFormatCodeArray {
                    let components = item.components(separatedBy: ",")
                    if let assetInfo = components.first {
                        let assetFormatCode = String(assetInfo).replacingOccurrences(of: "\"", with: "")
                        assetFormatCodes.append(assetFormatCode)
                    }
                }
                
                var userArray = parsedData.components(separatedBy: "\"userDisplayName\" : ")
                userArray.indices.reversed().forEach {
                    if $0 % 2 == 0 { userArray.remove(at: $0) }
                }
                var userNames: [String] = []
                for item in userArray {
                    let components = item.components(separatedBy: ",")
                    if let userName = components.first {
                        userNames.append(userName)
                    }
                }
                
                var baseArray = parsedData.components(separatedBy: "\"mlBaseDownloadUrl\" : ")
                baseArray.indices.reversed().forEach {
                    if $0 % 2 == 0 { baseArray.remove(at: $0) }
                }
                var baseURLs: [String] = []
                for item in baseArray {
                    let components = item.components(separatedBy: ",")
                    if let baseURL = components.first {
                        baseURLs.append(baseURL)
                    }
                }
                
                var citationNameArray = parsedData.components(separatedBy: "\"citationName\" : ")
                citationNameArray.indices.reversed().forEach {
                    if $0 % 2 == 0 { citationNameArray.remove(at: $0) }
                }
                var citationNames: [String] = []
                for item in citationNameArray {
                    let components = item.components(separatedBy: ",")
                    if let citationName = components.first {
                        citationNames.append(citationName)
                    }
                }
                
                for (index, code) in assetFormatCodes.enumerated() {
                    let metadata = BirdSpeciesAssetMetadata(identifier: ids[index], expectedIndex: (self?.speciesMedia.compactMap({$0.speciesCode == code}).count ?? 0) + 1, speciesCode: speciesCode, assetFormatCode: code, url: assetIds[index], uploadedBy: userNames[index], citationUrl: citationURLs[index], baseURL: baseURLs[index], comName: sighting.comName, sciName: sighting.sciName)
                    if (self?.speciesMedia.contains(metadata) != true) {
                        DispatchQueue.main.async { [weak self] in
                            self?.speciesMedia.append(metadata)
                        }
                    }
                    /*if (sighting.speciesMedia.contains(metadata) == false) {
                        DispatchQueue.main.async { [weak self] in
                            sighting.speciesMedia.append(metadata)
                        }
                    }*/
                }
            }
            else {
                // Failure
                print("Failure: %@", error?.localizedDescription ?? "unknown error");
            }
        })
        task.resume()
    }
    
    func requestWebsiteAssetMetadataOf(sighting: BirdSighting) {
        guard let speciesCode = sighting.speciesCode else {
            return
        }
        guard let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            print("failure to make species url of \(speciesCode)")
            return
        }
        guard let url = URL(string: "https://ebird.org/species/" + speciesURLString) else {
            print("failure to make species url of \(speciesCode): \(speciesURLString)")
            return
        }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "GET"
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            let parsedData = String(data: data, encoding: String.Encoding.utf8)
            var assets = parsedData?.components(separatedBy: "\"assetId\" : ")
            assets?.indices.reversed().forEach {
                if $0 % 2 == 0 { assets?.remove(at: $0) }
            }
            var ids: [Int] = []
            var assetIds: [String] = []
            var citationURLs: [String] = []
            for item in (assets ?? []) {
                let components = item.components(separatedBy: ",")
                if let assetInfo = components.first, let assetId = Int(assetInfo) {
                    ids.append(assetId)
                    assetIds.append("https://cdn.download.ams.birds.cornell.edu/api/v1/asset/"  + "\(assetId)")
                    //assetIds.append("https://macaulaylibrary.org/asset/" + "\(assetId)")
                }
                for component in components {
                    let array = component.split(separator: "\"citationUrl\" : ")
                    if let url = array.last {
                        citationURLs.append(String(url))
                    }
                }
            }
            
            var assetFormatCodeArray = parsedData?.components(separatedBy: "\"assetFormatCode\" : ")
            assetFormatCodeArray?.indices.reversed().forEach {
                if $0 % 2 == 0 { assetFormatCodeArray?.remove(at: $0) }
            }
            var assetFormatCodes: [String] = []
            for item in (assetFormatCodeArray ?? []) {
                let components = item.components(separatedBy: ",")
                if let assetInfo = components.first {
                    let assetFormatCode = String(assetInfo).replacingOccurrences(of: "\"", with: "")
                    assetFormatCodes.append(assetFormatCode)
                }
            }
            
            var userArray = parsedData?.components(separatedBy: "\"userDisplayName\" : ")
            userArray?.indices.reversed().forEach {
                if $0 % 2 == 0 { userArray?.remove(at: $0) }
            }
            var userNames: [String] = []
            for item in (userArray ?? []) {
                let components = item.components(separatedBy: ",")
                if let userName = components.first {
                    userNames.append(userName)
                }
            }
            
            var baseArray = parsedData?.components(separatedBy: "\"mlBaseDownloadUrl\" : ")
            baseArray?.indices.reversed().forEach {
                if $0 % 2 == 0 { baseArray?.remove(at: $0) }
            }
            var baseURLs: [String] = []
            for item in (baseArray ?? []) {
                let components = item.components(separatedBy: ",")
                if let baseURL = components.first {
                    baseURLs.append(baseURL)
                }
            }
            
            var citationNameArray = parsedData?.components(separatedBy: "\"citationName\" : ")
            citationNameArray?.indices.reversed().forEach {
                if $0 % 2 == 0 { citationNameArray?.remove(at: $0) }
            }
            var citationNames: [String] = []
            for item in (citationNameArray ?? []) {
                let components = item.components(separatedBy: ",")
                if let citationName = components.first {
                    citationNames.append(citationName)
                }
            }
            guard let speciesMedia = self?.speciesMedia else { return }
            var allAssetMetadata: [BirdSpeciesAssetMetadata] = []
            for (index, code) in assetFormatCodes.enumerated() {
                let metadata = BirdSpeciesAssetMetadata(identifier: ids[index], expectedIndex: (speciesMedia.compactMap({$0.speciesCode == code}).count) + 1, speciesCode: speciesCode, assetFormatCode: code, url: assetIds[index], uploadedBy: userNames[index], citationUrl: citationURLs[index], baseURL: baseURLs[index], comName: sighting.comName, sciName: sighting.sciName)
                allAssetMetadata.append(metadata)
            }
            
            if (sighting.speciesMediaMetadata?.contains(allAssetMetadata) != true) {
                DispatchQueue.main.async {
                    let newSighting = BirdSighting(speciesMediaMetadata: (sighting.speciesMediaMetadata ?? []) + allAssetMetadata, speciesCode: sighting.speciesCode, comName: sighting.comName, sciName: sighting.sciName, locId: sighting.locId, locName: sighting.locName, obsDt: sighting.obsDt, howMany: sighting.howMany, lat: sighting.lat, lng: sighting.lng, obsValid: sighting.obsValid, obsReviewed: sighting.obsReviewed, locationPrivate: sighting.locationPrivate)
                    //newSighting.speciesMediaMetadata?.append(metadata)
                    if self?.sightings.contains(sighting) == true {
                        self?.sightings.replace([sighting], with: [newSighting], maxReplacements: 1)
                    }
                    if self?.notableSightings.contains(sighting) == true {
                        self?.notableSightings.replace([sighting], with: [newSighting], maxReplacements: 1)
                    }
                }
            }
        })
        task.resume()
    }
}

