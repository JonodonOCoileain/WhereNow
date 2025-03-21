//
//  CLPlacemark+.swift
//  WhereNow
//
//  Created by Jonathan Lavallee Collins on 3/21/25.
//
import CoreLocation
extension CLPlacemark {
    func asAddress() -> Address {
        let address = Address(buildingNumber: nil, streetNumber: self.subThoroughfare, routeNumbers: nil, street: self.thoroughfare, streetName: self.addressDictionary?["Street"] as? String, streetNameAndNumber: (self.subThoroughfare ?? "") + " " + (self.thoroughfare ?? ""), countryCode: self.isoCountryCode, countrySubdivision: self.administrativeArea, countrySecondarySubdivision: self.subAdministrativeArea, municipality: self.locality ?? self.addressDictionary?["City"] as? String, postalCode: self.postalCode, neighborhood: self.subLocality, country: self.country, countryCodeISO3: self.isoCountryCode, freeformAddress: (self.addressDictionary?["FormattedAddressLines"] as? [String])?.joined(separator: ","), boundingBox: nil, extendedPostalCode: nil, countrySubdivisionName: self.region?.description ?? "", countrySubdivisionCode: nil, localName: self.name, ocean: self.ocean ?? "", inlandWater: self.inlandWater ?? "")
        return address
    }
}
