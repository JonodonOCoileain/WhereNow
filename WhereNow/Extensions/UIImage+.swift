//
//  UIImage+.swift
//  WhereNow
//
//  Created by Jon on 12/1/24.
//

import UIKit
import OSLog
extension UIImage {
    func addTo(bottomImage: UIImage) -> UIImage {
        var size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContext(size)

        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        bottomImage.draw(in: areaSize)

        self.draw(in: areaSize, blendMode: .normal, alpha: 0.8)

        var newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func combineImages(_ images: [UIImage]) -> UIImage {
        var images = images
        if var newImage: UIImage = images.first {
            while(images.count > 1) {
                var bottomImage = images.removeFirst()
                var topImage = images.removeFirst()
                
                var size = CGSize(width: 300, height: 300)
                UIGraphicsBeginImageContext(size)
                
                let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                bottomImage.draw(in: areaSize)
                
                topImage.draw(in: areaSize, blendMode: .normal, alpha: 0.8)
                
                newImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                
                images.insert(newImage.copy() as! UIImage, at: 0)
            }
            return newImage
        } else {
            Logger.images.warning("Images array passed to combiner is empty.")
            return UIImage()
        }
    }
}
