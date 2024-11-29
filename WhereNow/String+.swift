//
//  String+Extensions.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//

import UIKit

extension String {
    func toImage() -> UIImage {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters){
            return UIImage(data: data) ?? UIImage()
        }
        return UIImage()
    }
    func matches(for regex: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

extension String {
    static var weatherNowTitle = "Weather Now!"
    static var andLaterTitle = "(And later!)"
    static var gameNowTitle = "Game Now!"
    static var chomp = "chomp!"
}

