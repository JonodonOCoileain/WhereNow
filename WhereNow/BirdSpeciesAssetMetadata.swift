//
//  BirdSpeciesAssetMetadata.swift
//  WhereNow
//
//  Created by Jon on 11/10/24.
//


import Foundation
import SwiftUI
import CoreLocation
import AVFoundation
import OSLog

class BirdSpeciesAssetMetadata: Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var id: Int { identifier }
    
    let identifier: Int
    let expectedIndex: Int
    var speciesCode: String? = nil
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
        hasher.combine(identifier)
        hasher.combine(expectedIndex)
        hasher.combine(speciesCode)
        hasher.combine(assetFormatCode)
        hasher.combine(url)
        hasher.combine(uploadedBy)
        hasher.combine(citationUrl)
        hasher.combine(baseURL)
        hasher.combine(comName)
        hasher.combine(sciName)
        hasher.combine(description)
        hasher.combine(image)
    }
}
