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
}
