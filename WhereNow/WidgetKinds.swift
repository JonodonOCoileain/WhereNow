//
//  WidgetKinds.swift
//  WhereNow
//
//  Created by Jon on 7/31/24.
//


public enum WidgetKinds {
    case WhereNowMapWidget
    case WhereNowTextWidget
    
    var description: String {
        switch self {
            case .WhereNowMapWidget:
                return "WhereNowMapWidget"
            case .WhereNowTextWidget:
                return "WhereNowTextWidget"
        }
    }
}