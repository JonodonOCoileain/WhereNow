//
//  File.swift
//  WhereNow
//
//  Created by Jon on 8/6/24.
//

import CoreLocation

extension CoreLocation.CLLocation {
    func getAddresses() async -> [Address] {
        let coordinate = self.coordinate
        guard let url = URL(string: "https://api.tomtom.com/search/2/reverseGeocode/\(coordinate.latitude),\(coordinate.longitude).json?key=FBSjYeqToGYAeG2A5txodKfGHrql38S4&radius=100") else { return [] }
        var addresses: [Address] = []
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let newResponse = try JSONDecoder().decode(Response.self, from: data)
            let newAddresses = newResponse.addresses.compactMap({$0.address})
            addresses = newAddresses
        } catch {
            print(error.localizedDescription)
            do {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(self)
                
                let newAddresses = placemarks.compactMap({$0.asAddress()})
                addresses = newAddresses
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return addresses
    }
}
