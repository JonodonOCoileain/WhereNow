//
//  Response.swift
//  WhereNow
//
//  Created by Jonathan Lavallee Collins on 3/21/25.
//



struct Response: Codable {
    var summary: Summary?
    var addresses: [AddressPair]
}

struct AddressPair: Codable {
    var address: Address
}

struct Summary: Codable {
    var queryTime: Int?
    var numResults: Int?
}

struct Addresses: Codable {
    var address: Address?
}

struct Address: Codable, Equatable {
    var buildingNumber: String?
    var streetNumber: String?
    var routeNumbers: [String]?
    var street: String?
    var streetName: String?
    var streetNameAndNumber: String?
    var countryCode: String?
    var countrySubdivision: String?
    var countrySecondarySubdivision: String?
    var municipality:String?
    var postalCode: String?
    var neighborhood: String?
    var country: String?
    var countryCodeISO3: String?
    var freeformAddress: String?
    var boundingBox: BoundingBox?
    var extendedPostalCode:String?
    var countrySubdivisionName:String? //State
    var countrySubdivisionCode:String?
    var localName: String? //Town
    var ocean: String?
    var inlandWater: String?
    
    func flag() -> String {
        var flag: String = ""
        if let countryCode = self.countryCode {
            let base : UInt32 = 127397
            for v in countryCode.unicodeScalars {
                flag.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
        }
        return flag
    }
    
    func formattedLarge() -> String {
        let addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ",") ?? ""].joined(separator: " "),[municipality ?? "",countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: " "),[extendedPostalCode ?? postalCode ?? "",country ?? ""].joined(separator: " ")]
        return addressInfo.joined(separator: "\n")
    }
    
    func formattedCommonLong() -> String {
        
        var flag: String = ""
        if let countryCode = self.countryCode {
            let base : UInt32 = 127397
            for v in countryCode.unicodeScalars {
                flag.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
        }
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),municipality ?? "",[countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func formattedCommonWithFlag() -> String {
        
        var flag: String = ""
        if let countryCode = self.countryCode {
            let base : UInt32 = 127397
            for v in countryCode.unicodeScalars {
                flag.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
        }
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[municipality ?? "",countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        if flag.isEmpty {
            return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return (addressInfo.joined(separator: "\n") + " " + flag).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func checkNumeric(S: String) -> Bool {
       return Double(S) != nil
    }
    
    func formattedVeryShort() -> String {
        if var streetArray = streetName?.components(separatedBy: " ") as? [String] {
            if (streetArray.last?.count ?? 5) <= 4, streetArray.count > 1 {
                streetArray.removeLast()
            }
            if let number = streetArray.first, checkNumeric(S: number) {
                streetArray.removeFirst()
            }
            if ["street", "avenue", "drive", "lane"].contains(streetArray.last?.lowercased()) {
                streetArray.removeLast()
            }
                
            let street = streetArray.joined(separator: " ")
            if localName?.contains(street) != true {
                return streetArray.joined(separator: " ") + ", " + (localName ?? municipality ?? "")
            } else {
                return street + ", " + (municipality ?? "")
            }
        } else {
            if (streetName?.count ?? 0) >= 1 {
                if let streetName = streetName, localName?.contains(streetName) != true {
                    return streetName + ", " + (localName ?? municipality ?? "")
                } else {
                    return (streetName ?? "") + ", " + (municipality ?? "")
                }
            } else {
                return localName ?? municipality ?? "" + ", " + (countrySubdivisionName ?? "")
            }
        }
    }
    
    func formattedShort() -> String {
        if let streetArray = streetName?.components(separatedBy: " ") as? [String] {
            let street = streetArray.joined(separator: " ")
            if localName?.contains(street) != true {
                return streetArray.joined(separator: " ") + ", " + (localName ?? municipality ?? "")
            } else {
                return street + ", " + (municipality ?? "")
            }
        } else {
            if (streetName?.count ?? 0) >= 1 {
                if let streetName = streetName, localName?.contains(streetName) != true {
                    return streetName + ", " + (localName ?? municipality ?? "")
                } else {
                    return (streetName ?? "") + ", " + (municipality ?? "")
                }
            } else {
                return localName ?? municipality ?? "" + ", " + (countrySubdivisionName ?? "")
            }
        }
    }
    
    func formattedCommonLongFlag() -> String {
        var flag: String = ""
        if let countryCode = self.countryCode {
            let base : UInt32 = 127397
            for v in countryCode.unicodeScalars {
                flag.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
        }
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),municipality ?? "",[countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        if flag.isEmpty {
            return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return (flag + "\n" + addressInfo.joined(separator: "\n")).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func formattedCommonVeryLongFlag() -> String {
        var flag: String = ""
        if let countryCode = countryCode {
            let base : UInt32 = 127397
            for v in countryCode.unicodeScalars {
                flag.unicodeScalars.append(UnicodeScalar(base + v.value)!)
            }
        }
        
        var addressInfo: [String] = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),municipality ?? "", countrySecondarySubdivision ?? "", countrySubdivisionName ?? "",postalCode ?? "",country ?? ""]
        if localName == countrySecondarySubdivision {
            addressInfo = [[streetNameAndNumber ?? "", routeNumbers?.joined(separator: ", ") ?? ""].joined(separator: " "),[countrySecondarySubdivision ?? "",countrySubdivisionName ?? ""].joined(separator: ", "),postalCode ?? "",country ?? ""]
        }
        addressInfo.removeAll(where: { $0 == "" })
        if flag.isEmpty {
            return addressInfo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return (flag + "\n" + addressInfo.joined(separator: "\n")).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

struct BoundingBox: Codable, Equatable {
    var northEast: String?
    var southWest: String?
    var entity: String?
}