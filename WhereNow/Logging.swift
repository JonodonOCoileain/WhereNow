//
//  Logging.swift
//  WhereNow
//
//  Created by Jon on 11/8/24.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs related to bird photos and audiofiles
    static let assetMetadata = Logger(subsystem: subsystem, category: "Requesting_Asset_Metadata")
    
    static let images = Logger(subsystem: subsystem, category: "Images")
}
