//
//  BirdSighting.swift
//  WhereNow
//
//  Created by Jon on 11/10/24.
//
import SwiftUI
import Foundation

class BirdSighting: Codable, Hashable, Identifiable, ObservableObject, Equatable {
    enum ChildKeys: CodingKey {
        case id, identifier, userDisplayName, subId, speciesCode, comName, sciName, locId, locName, obsDt, howMany, lat, lng, obsValid, obsReviewed, locationPrivate
    }
    
    var id: String { "\(userDisplayName ?? "")\(subId ?? "")\(speciesCode ?? "")\(comName ?? "")\(sciName ?? "")\(locId ?? "")\(obsDt ?? "")\(howMany ?? 0)\(lat ?? 1)\(lng ?? 1)\(obsValid ?? false)\(obsReviewed ?? false)\(locationPrivate ?? false)" }
    
    var subId: String? = nil
    var userDisplayName: String? = nil
    var speciesCode: String? = nil
    var comName: String? = nil
    var sciName: String? = nil
    var locId: String? = nil
    var locName: String? = nil
    var obsDt: String? = nil
    var howMany: Int? = nil
    var lat: Float? = nil
    var lng: Float? = nil
    var obsValid: Bool? = nil
    var obsReviewed: Bool? = nil
    var locationPrivate: Bool? = nil
    init(subId: String? = nil, userDisplayName: String? = nil, speciesMediaMetadata: [BirdSpeciesAssetMetadata]? = nil, audioData: [Data]? = nil, speciesCode: String? = nil, comName: String? = nil, sciName: String? = nil, locId: String? = nil, locName: String? = nil, obsDt: String? = nil, howMany: Int? = nil, lat: Float? = nil, lng: Float? = nil, obsValid: Bool? = nil, obsReviewed: Bool? = nil, locationPrivate: Bool? = nil) {
        self.subId = subId
        self.userDisplayName = userDisplayName
        self.locId = locId
        self.locName = locName
        self.obsDt = obsDt
        self.comName = comName
        self.sciName = sciName
        self.speciesCode = speciesCode
        self.howMany = howMany
        self.lat = lat
        self.lng = lng
        self.obsValid = obsValid
        self.obsReviewed = obsReviewed
        self.locationPrivate = locationPrivate
    }
    
    func description() -> String {
        let userDisplayName = userDisplayName ?? ""
        let commonName = comName ?? ""
        let sciName = sciName ?? ""
        let howMany = howMany ?? 1
        let locName = locName ?? ""
        let obsDt = obsDt ?? ""
        let locationPrivate = locationPrivate ?? false
        
        let description = "\(commonName)\n\(sciName)\nSeen by: \(userDisplayName)\nQuantity: \(howMany)\nAt Location: \(locName)\nOn Date: \(obsDt)\nIn public location: \(locationPrivate == false)"
        return description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userDisplayName)
        hasher.combine(subId)
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ChildKeys.self)
        self.subId = try container.decode(String.self, forKey: .subId)
        self.userDisplayName = try container.decodeIfPresent(String.self, forKey: .userDisplayName)
        self.comName = try container.decodeIfPresent(String.self, forKey: .comName)
        self.sciName = try container.decodeIfPresent(String.self, forKey: .sciName)
        self.speciesCode = try container.decodeIfPresent(String.self, forKey: .speciesCode)
        self.locId = try container.decodeIfPresent(String.self, forKey: .locId)
        self.locName = try container.decodeIfPresent(String.self, forKey: .locName)
        self.obsDt = try container.decodeIfPresent(String.self, forKey: .obsDt)
        self.howMany = try container.decodeIfPresent(Int.self, forKey: .howMany)
        self.lat = try container.decodeIfPresent(Float.self, forKey: .lat)
        self.lng = try container.decodeIfPresent(Float.self, forKey: .lng)
        self.obsValid = try container.decodeIfPresent(Bool.self, forKey: .obsValid)
        self.obsReviewed = try container.decodeIfPresent(Bool.self, forKey: .obsReviewed)
        self.locationPrivate = try container.decodeIfPresent(Bool.self, forKey: .locationPrivate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ChildKeys.self)
        try container.encode(self.subId, forKey: .subId)
        try container.encodeIfPresent(self.comName, forKey: .comName)
        try container.encodeIfPresent(self.sciName, forKey: .sciName)
        try container.encodeIfPresent(self.speciesCode, forKey: .speciesCode)
        try container.encodeIfPresent(self.locId, forKey: .locId)
        try container.encodeIfPresent(self.locName, forKey: .locName)
        try container.encodeIfPresent(self.obsDt, forKey: .obsDt)
        try container.encodeIfPresent(self.howMany, forKey: .howMany)
        try container.encodeIfPresent(self.lat, forKey: .lat)
        try container.encodeIfPresent(self.lng, forKey: .lng)
        try container.encodeIfPresent(self.obsValid, forKey: .obsValid)
        try container.encodeIfPresent(self.obsReviewed, forKey: .obsReviewed)
        try container.encodeIfPresent(self.locationPrivate, forKey: .locationPrivate)
    }
    
    static func == (lhs: BirdSighting, rhs: BirdSighting) -> Bool {
        return lhs.subId == rhs.subId && lhs.locName == rhs.locName && lhs.obsDt == rhs.obsDt && lhs.comName == rhs.comName && lhs.lat == rhs.lat && lhs.sciName == rhs.sciName && rhs.locId == rhs.locId
    }
    
}
