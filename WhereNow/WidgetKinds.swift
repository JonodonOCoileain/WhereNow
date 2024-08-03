//
//  WidgetKinds.swift
//  WhereNow
//
//  Created by Jon on 7/31/24.
//


public enum WidgetKinds {
    case WhereNowMapWidget
    case WhereNowMapAndWeatherWidget
    case WhereNowTextWidget
    
    var description: String {
        switch self {
            case .WhereNowMapWidget:
                return "WhereNowMapWidget"
            case .WhereNowMapAndWeatherWidget:
                return "WhereNowMapAndWeatherWidget"
            case .WhereNowTextWidget:
                return "WhereNowTextWidget"
        }
    }
}
