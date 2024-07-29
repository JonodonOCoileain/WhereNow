//
//  CL+Extensions.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//
import CoreLocation
extension CLLocation {
    func getPlaces(with completion: @escaping ([CLPlacemark]?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(self) { placemarks, error in
            
            guard error == nil else {
                print("*** Error in \(#function): \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemarks = placemarks else {
                print("*** Error in \(#function): placemarks is nil")
                completion(nil)
                return
            }
            
            completion(placemarks)
        }
    }
}
