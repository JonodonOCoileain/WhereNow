//
//  BirdSightingService.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import Foundation
import SwiftUI
import CoreLocation

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
    public static let youTubeVideoBaseURL: String = "https://www.youtube.com/watch?v="
    public static let cornellUOrnithologyAPIKey = "4ubf1p4of0js"
    public static let unsplashAPIKey: String = ""
    public static let BaseURLString: String = "https://api.ebird.org/v2/data/obs/geo/recent"
    
    typealias SightingsRequestCompletionHandler = (Result<[BirdSighting], Error>) -> Void
    typealias SightingsRequestResult = Result<[BirdSighting], Error>

    var sightings: [BirdSighting] = [] {
        didSet {
            let commonNames = sightings.compactMap({$0.comName})
            birdSeenCommonDescription = commonNames.joined(separator: ", ")
        }
    }
    var birdImageData: [String:Data] = [:]
    var birdImageMetadataRequest: [String:URLRequest] = [:]
    @Published var birdYouTubeVideoURL: [String:String] = [:]
    @Published var birdSoundURL: [String:String] = [:]
    @Published var birdSeenCommonDescription: String?
    
    init(sightings: [BirdSighting] = []) {
        self.sightings = sightings
    }
    
    /*func cacheBirdImageMetadataRequests() {
        for birdSighting in sightings {
            if let uniqueID = birdSighting.speciesCode, let name = birdSighting.comName {
                let urlString = "https://api.unsplash.com/search/photos?client_id=\(BirdSightingService.unsplashAPIKey)&page=1&query=\(name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"
                if let url = URL(string: urlString) {
                    var request = URLRequest(url: url)
                    request.addValue("10", forHTTPHeaderField: "X-Ratelimit-Limit")
                    birdImageMetadataRequest[uniqueID] = request
                }
            }
        }
    }*/
    //"fullurl":"https://commons.wikimedia.org/wiki/File:Falco_peregrinus_MHNT.ZOO.2010.11.102.1.jpg"
    func getWikiImageSource(of bird: String) {
        let bird = bird.replacingOccurrences(of: " ", with: "+")
        let imageMetadataURLString = "https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=\(bird)"
        
        guard let imageMetadataURL = URL(string: imageMetadataURLString) else {
            print("Error: \(imageMetadataURLString) doesn't seem to be a valid URL")
            return
        }
        var imageMetadataRequest = URLRequest(url: imageMetadataURL)
        imageMetadataRequest.httpMethod = "GET"
        let session = URLSession(configuration: .default)
        
        let imageMetadataTask = session.dataTask(with: imageMetadataRequest) { data, _, _ in
            if let imageMetadata = data, let imageMetadataResult = String(data: imageMetadata, encoding: .utf8) {
                var imageLicenseStrings:[String] = []
                var imageURLStrings:[String] = []
                let separatedArray = imageMetadataResult.components(separatedBy: CharacterSet(charactersIn: ",:"))
                for (index, item) in separatedArray.enumerated() {
                    if item == "fullurl" {
                        imageURLStrings.append(separatedArray[index+1])
                    }
                    if item.contains("license") {
                        imageLicenseStrings.append(separatedArray[index+1])
                    }
                }
            }
        }
        imageMetadataTask.resume()
    }
    
    func getWikiAudioSource(of bird: String) {
        let bird = bird.replacingOccurrences(of: " ", with: "+")
        let audioURLString = "https://commons.wikimedia.org/wiki/Special:MediaSearch?type=audio&search=\(bird)"
        
        guard let audioURL = URL(string: audioURLString) else {
            print("Error: \(audioURLString) doesn't seem to be a valid URL")
            return
        }
        var audioMetadataRequest = URLRequest(url: audioURL)
        audioMetadataRequest.httpMethod = "GET"
        
        let session = URLSession(configuration: .default)
        
        
        let audioMetadataTask = session.dataTask(with: audioMetadataRequest) { /*[weak self]*/ data, _, _ in
            if let audioMetadata = data, let audioMetadataResult = String(data: audioMetadata, encoding: .utf8) {
                var audioLicenseStrings:[String] = []
                var audioURLStrings:[String] = []
                let separatedArray = audioMetadataResult.components(separatedBy: CharacterSet(charactersIn: ",:"))
                for (index, item) in separatedArray.enumerated() {
                    if item == "fullurl" {
                        audioURLStrings.append(separatedArray[index+1])
                    }
                    if item.contains("license") {
                        audioLicenseStrings.append(separatedArray[index+1])
                    }
                }
            }
        }
        audioMetadataTask.resume()
    }

    func cacheBirdSoundInfo(of name: String) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://xeno-canto.org/api/2/recordings?query=\(encodedName)") else { return }//previously the url ended with +q:A
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let session = URLSession(configuration: .default)
            
        let dataTask = session.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let dict = data?.convertToDictionary() else { return }
            guard let items = dict["recordings"] as? [[String:Any]] else { return }
            guard let item = items.first else { return }
            guard let soundFileURLString = item["file"] as? String else { return }
            DispatchQueue.main.async { [weak self] in
                self?.birdSoundURL[name] = soundFileURLString
            }
        }
        dataTask.resume()
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
        guard let baseURL = URL(string:BirdSightingService.BaseURLString) else { return nil}
        let finalURL = baseURL.appending(queryItems: queryItems)
        var request = URLRequest(url: finalURL)
        request.addValue("\(BirdSightingService.cornellUOrnithologyAPIKey)", forHTTPHeaderField: "X-eBirdApiToken")
        return request
    }
    
    func makeRequest(using coordinate: CLLocationCoordinate2D) -> URLRequest? {
        let latitudeURLQueryItem = URLQueryItem(name: "lat", value: String(coordinate.latitude))
        let longitudeURLQueryItem = URLQueryItem(name: "lng", value: String(coordinate.longitude))
        let sortingURLQueryItem = URLQueryItem(name: "sort", value: "date")
        let queryItems:[URLQueryItem] = [latitudeURLQueryItem, longitudeURLQueryItem, sortingURLQueryItem]
        guard let baseURL = URL(string:BirdSightingService.BaseURLString) else { return nil}
        let finalURL = baseURL.appending(queryItems: queryItems)
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
}
