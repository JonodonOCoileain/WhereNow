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
import OSLog

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
    
    @Published var birdSeenCommonDescription: String?
    @Published var notableBirdsSeenCommonDescription: String?
    @Published var speciesMedia: [BirdSpeciesAssetMetadata] = []
    //Array of unique IDs to track requests and prevent duplicative and redundant work
    private var sightingRequests: [String] = []
    @Published var savedImages: Int = 0
    init(sightings: [BirdSighting] = []) {
        self.sightings = sightings
    }
    
    func resetData() {
        sightings = []
        notableSightings = []
        speciesMedia  = []
        birdSeenCommonDescription = nil
        notableBirdsSeenCommonDescription = nil
        deleteFileDirectory()
    }
    //set the name of the new folder
    private let birdFilesFolderURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("BirdFiles")
    func createFileDirectory() {
        do
        {
            try FileManager.default.createDirectory(at: birdFilesFolderURL, withIntermediateDirectories: true)
        }
        catch let error as NSError
        {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }
    
    func deleteFileDirectory() {
        do
        {
            try FileManager.default.removeItem(at: birdFilesFolderURL)
        }
        catch let error as NSError
        {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }
    
    func saveBirdFile(data: Data, metaData: BirdSpeciesAssetMetadata) {
        var isDirectory : ObjCBool = true
        if !FileManager.default.fileExists(atPath: birdFilesFolderURL.path(), isDirectory: &isDirectory) {
            self.createFileDirectory()
        }
        let name = String(metaData.hashValue)
        guard let directoryName = metaData.comName ?? metaData.sciName else {
            Logger.assetMetadata.error("Could not generate asset data folder name for \(metaData.description ?? "Undescribed metadata")")
            return
        }
        let directory = birdFilesFolderURL.appendingPathComponent(directoryName)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let extensionString = metaData.assetFormatCode
        let fileURL = directory.appendingPathComponent(name).appendingPathExtension(extensionString)
        
        do {
            try data.write(to: fileURL)
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
                self?.savedImages += 1
            })
        } catch {
            print(error)
        }
    }
    
    func retrieveData(of dataArray: [BirdSpeciesAssetMetadata]) {
        for metadata in dataArray {
            if let url = URL(string: metadata.url) {
                
                let request = URLRequest(url: url)
                
                let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                    if let data = data {
                        self?.saveBirdFile(data: data, metaData: metadata)
                    }
                }
                task.resume()
            }
        }
    }
    
    func getDataOfBird(metadata: BirdSpeciesAssetMetadata) -> Data? {
        let name = String(metadata.hashValue)
        guard let directoryName = metadata.comName ?? metadata.sciName else {
            Logger.assetMetadata.error("Could not generate asset data folder name for \(metadata.description ?? "Undescribed metadata")")
            return nil
        }
        let directory = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(directoryName)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let extensionString = metadata.assetFormatCode
        let fileURL = directory.appendingPathComponent(name).appendingPathExtension(extensionString)
        
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            do {
                return try Data(contentsOf: fileURL, options: [])
            } catch {
                print(error.localizedDescription)
                return nil
            }
        } else {
            return nil
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
    var cachingSightings: Bool = false
    func cacheSightings(using coordinate: CLLocationCoordinate2D) {
        if !cachingSightings {
            guard let request = makeRequest(using: coordinate) else { return }
            let dataTask = URLSession(configuration: .ephemeral).dataTask(with: request, completionHandler: { [weak self] data, response, error in
                guard let data = data else {
                    print(error?.localizedDescription ?? "Error retrieving forecast data")
                    self?.cachingSightings = false
                    return
                }
                do {
                    let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
                    
                    if decodedSightings.count > 0 {
                        self?.requestWebsiteAssetMetadataOf(sighting: decodedSightings[0])
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.sightings = decodedSightings
                        self?.cachingSightings = false
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
    }
    
    func asyncCacheSightings(using coordinate: CLLocationCoordinate2D) async {
        guard let request = makeRequest(using: coordinate) else { return }
        do {
            let data = try await URLSession(configuration: .ephemeral).data(for: request).0
            do {
                let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
                
                for i in 0...4 {
                    if decodedSightings.count > i {
                        try await self.asyncRequestWebsiteAssetMetadataOf(sighting: decodedSightings[i])
                    }
                }
                
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
            
        } catch {
            print(error)
        }
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
    
    var cachingNotables: Bool = false
    func cacheNotableSightings(using coordinate: CLLocationCoordinate2D) {
        if !cachingNotables {
            var isDirectory : ObjCBool = true
            if !FileManager.default.fileExists(atPath: birdFilesFolderURL.path(), isDirectory: &isDirectory) {
                self.createFileDirectory()
            }
            guard let request = makeNotablesRequest(using: coordinate) else { return }
            let dataTask = URLSession(configuration: .ephemeral).dataTask(with: request, completionHandler: { [weak self] data, response, error in
                guard let data = data else {
                    print(error?.localizedDescription ?? "Error retrieving notable bird sighting data")
                    self?.cachingNotables = false
                    return
                }
                do {
                    let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
                    var sightingsToSave: [BirdSighting] = []
                    for sighting in decodedSightings.reversed() {
                        if !sightingsToSave.contains(where: {$0.speciesCode == sighting.speciesCode && $0.locId == sighting.locId && $0.locName == sighting.locName }) {
                            sightingsToSave.append(sighting)
                        }
                    }
                    let notableSightings = Array(sightingsToSave.reversed())
                    for i in 0...4 {
                        if notableSightings.count > i {
                            self?.requestWebsiteAssetMetadataOf(sighting: notableSightings[i])
                        }
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.notableSightings = notableSightings
                        self?.cachingNotables = false
                    }
                } catch {
                    self?.cachingNotables = false
                    print(error.localizedDescription)
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 4, execute: { [weak self] in
                        let coordinate = CoreLocation.CLLocationManager().location?.coordinate ?? coordinate
                        self?.cacheNotableSightings(using: coordinate)
                    })
                }
            })
            dataTask.resume()
        }
    }
    
    func asyncCacheNotableSightings(using coordinate: CLLocationCoordinate2D) async {
        guard let request = makeNotablesRequest(using: coordinate) else { return }
        do {
            let data = try await URLSession(configuration: .ephemeral).data(for: request).0
            do {
                let decodedSightings = try JSONDecoder().decode([BirdSighting].self, from: data)
                
                for i in 0...4 {
                    if decodedSightings.count > i {
                        try await self.asyncRequestWebsiteAssetMetadataOf(sighting: decodedSightings[i])
                    }
                }
                
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
            
        } catch {
            print(error)
        }
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
                //let statusCode = (response as! HTTPURLResponse).statusCode
                
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
        let requestId = sighting.comName ?? sighting.sciName ?? sighting.speciesCode ?? "unknown"
        if sightingRequests.contains(requestId) {
            Logger.assetMetadata.trace("Request already in progress, exiting additional request function call")
            return
        } else {
            sightingRequests.append(requestId)
        }
        Logger.assetMetadata.trace("Requesting asset metadata of \(sighting.comName ?? "Unknown bird")")
        guard let speciesCode = sighting.speciesCode else {
            Logger.assetMetadata.trace("Failure to find speciesCode")
            sightingRequests.removeAll(where: { $0 == requestId })
            return
        }
        guard let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            Logger.assetMetadata.error("Failure to make SpeciesCode URL")
            sightingRequests.removeAll(where: { $0 == requestId })
            return
        }
        guard let url = URL(string: "https://ebird.org/species/" + speciesURLString) else {
            Logger.assetMetadata.error("Failure to make species url of \(speciesCode): \(speciesURLString)")
            sightingRequests.removeAll(where: { $0 == requestId })
            return
        }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "GET"
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let data = data, error == nil else {
                if let error = error {
                    Logger.assetMetadata.error("Failure to return data using SpeciesCodeURLRequest, reporting error: \(error.localizedDescription)")
                } else {
                    Logger.assetMetadata.error("Failure to return data using SpeciesCodeURLRequest without a reported error")
                }
                self?.sightingRequests.removeAll(where: { $0 == requestId })
                return
            }
            let parsedData = String(data: data, encoding: String.Encoding.utf8)
            var assets = parsedData?.components(separatedBy: "\"assetId\" : ")
            Logger.assetMetadata.trace("Parsing revealed \(assets?.count ?? 0) asset references")
            assets?.indices.reversed().forEach {
                if $0 % 2 == 0 { assets?.remove(at: $0) }
            }
            
            Logger.assetMetadata.trace("After reversing order of asset references and removing every other reference, there are \(assets?.count ?? 0) references")
            
            var ids: [Int] = []
            var assetIds: [String] = []
            var citationURLs: [String] = []
            
            for item in (assets ?? []) {
                let components = item.components(separatedBy: ",")
                if let assetInfo = components.first, let assetId = Int(assetInfo) {
                    ids.append(assetId)
                    assetIds.append("https://cdn.download.ams.birds.cornell.edu/api/v1/asset/"  + "\(assetId)")
                    Logger.assetMetadata.trace("Appending assetId \(assetId)")
                    //assetIds.append("https://macaulaylibrary.org/asset/" + "\(assetId)")
                }
                for component in components {
                    let array = component.split(separator: "\"citationUrl\" : ")
                    if let url = array.last {
                        Logger.assetMetadata.trace("Appending citationURL \(url)")
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
                    Logger.assetMetadata.trace("Appending userName \(assetFormatCode)")
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
                    Logger.assetMetadata.trace("Appending userName \(userName)")
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
                    Logger.assetMetadata.trace("Appending baseURL \(baseURL)")
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
                    Logger.assetMetadata.trace("Appending citation \(citationName)")
                    citationNames.append(citationName)
                }
            }
            guard let speciesMedia = self?.speciesMedia else {
                Logger.assetMetadata.trace("Lost reference to self or speciesMedia, aborting")
                return
            }
            var allAssetMetadata: [BirdSpeciesAssetMetadata] = []
            for (index, code) in assetFormatCodes.enumerated() {
                let metadata = BirdSpeciesAssetMetadata(identifier: ids[index], expectedIndex: (speciesMedia.compactMap({$0.speciesCode == code}).count) + 1, speciesCode: speciesCode, assetFormatCode: code, url: assetIds[index], uploadedBy: userNames[index], citationUrl: citationURLs[index], baseURL: baseURLs[index], comName: sighting.comName, sciName: sighting.sciName)
                Logger.assetMetadata.trace("Adding asset metadata of \(sighting.comName ?? "*missing comName*") to new array")
                
                allAssetMetadata.append(metadata)
            }
            
            if (self?.speciesMedia.contains(allAssetMetadata) != true) {
                DispatchQueue.main.async(execute:  {
                    Logger.assetMetadata.trace("Updating sighting with subId \(sighting.subId ?? "") of \(sighting.comName ?? "") with acquired metadata of \(sighting.comName ?? "unknown")")
                    self?.speciesMedia.append(contentsOf: allAssetMetadata)
                })
            }
        })
        task.resume()
    }
    
    func asyncRequestWebsiteAssetMetadataOf(sighting: BirdSighting) async throws {
        let requestId = sighting.comName ?? sighting.sciName ?? sighting.speciesCode ?? "unknown"
        if sightingRequests.contains(requestId) {
            Logger.assetMetadata.trace("Request already in progress, exiting additional request function call")
            return
        } else {
            sightingRequests.append(requestId)
        }
        Logger.assetMetadata.trace("Requesting asset metadata of \(sighting.comName ?? "Unknown bird")")
        guard let speciesCode = sighting.speciesCode else {
            Logger.assetMetadata.trace("Failure to find speciesCode")
            sightingRequests.removeAll(where: { $0 == requestId })
            return
        }
        guard let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            Logger.assetMetadata.error("Failure to make SpeciesCode URL")
            sightingRequests.removeAll(where: { $0 == requestId })
            return
        }
        guard let url = URL(string: "https://ebird.org/species/" + speciesURLString) else {
            Logger.assetMetadata.error("Failure to make species url of \(speciesCode): \(speciesURLString)")
            sightingRequests.removeAll(where: { $0 == requestId })
            return
        }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "GET"
        do {
            let response = try await session.data(for: request)
            let data = response.0
            //let error = response.1
            let parsedData = String(data: data, encoding: String.Encoding.utf8)
            var assets = parsedData?.components(separatedBy: "\"assetId\" : ")
            Logger.assetMetadata.trace("Parsing revealed \(assets?.count ?? 0) asset references")
            assets?.indices.reversed().forEach {
                if $0 % 2 == 0 { assets?.remove(at: $0) }
            }
            
            Logger.assetMetadata.trace("After reversing order of asset references and removing every other reference, there are \(assets?.count ?? 0) references")
            
            var ids: [Int] = []
            var assetIds: [String] = []
            var citationURLs: [String] = []
            
            for item in (assets ?? []) {
                let components = item.components(separatedBy: ",")
                if let assetInfo = components.first, let assetId = Int(assetInfo) {
                    ids.append(assetId)
                    assetIds.append("https://cdn.download.ams.birds.cornell.edu/api/v1/asset/"  + "\(assetId)")
                    Logger.assetMetadata.trace("Appending assetId \(assetId)")
                    //assetIds.append("https://macaulaylibrary.org/asset/" + "\(assetId)")
                }
                for component in components {
                    let array = component.split(separator: "\"citationUrl\" : ")
                    if let url = array.last {
                        Logger.assetMetadata.trace("Appending citationURL \(url)")
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
                    Logger.assetMetadata.trace("Appending userName \(assetFormatCode)")
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
                    Logger.assetMetadata.trace("Appending userName \(userName)")
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
                    Logger.assetMetadata.trace("Appending baseURL \(baseURL)")
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
                    Logger.assetMetadata.trace("Appending citation \(citationName)")
                    citationNames.append(citationName)
                }
            }
            let speciesMedia = self.speciesMedia
            var allAssetMetadata: [BirdSpeciesAssetMetadata] = []
            for (index, code) in assetFormatCodes.enumerated() {
                let metadata = BirdSpeciesAssetMetadata(identifier: ids[index], expectedIndex: (speciesMedia.compactMap({$0.speciesCode == code}).count) + 1, speciesCode: speciesCode, assetFormatCode: code, url: assetIds[index], uploadedBy: userNames[index], citationUrl: citationURLs[index], baseURL: baseURLs[index], comName: sighting.comName, sciName: sighting.sciName)
                Logger.assetMetadata.trace("Adding asset metadata of \(sighting.comName ?? "*missing comName*") to new array")
                
                allAssetMetadata.append(metadata)
            }
            
            if (self.speciesMedia.contains(allAssetMetadata) != true) {
                DispatchQueue.main.async(execute:  {
                    Logger.assetMetadata.trace("Updating sighting with subId \(sighting.subId ?? "") of \(sighting.comName ?? "") with acquired metadata of \(sighting.comName ?? "unknown")")
                    self.speciesMedia.append(contentsOf: allAssetMetadata)
                })
            }
            if let index = self.sightingRequests.firstIndex(of: requestId) {
                self.sightingRequests.remove(at: index)
            }
        } catch {
            if let err
                = error as? URLError {
                Logger.assetMetadata.error("Failure to return data using SpeciesCodeURLRequest, reporting error: \(err.localizedDescription)")
            }
        }
    }
}

