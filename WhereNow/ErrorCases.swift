//
//  ErrorCases.swift
//  WhereNow
//
//  Created by Jon on 8/2/24.
//

import Foundation

public enum ErrorCases: Error {
    case Unknown
    case Described(String)
    
    var description: String {
        switch self {
        case .Unknown: return "Unknown"
        case .Described(let description): return description
        }
    }
}
