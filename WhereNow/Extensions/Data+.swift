//
//  Data+.swift
//  WhereNow
//
//  Created by Jon on 8/6/24.
//

import Foundation

extension Data {
    func convertToDictionary() -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}
