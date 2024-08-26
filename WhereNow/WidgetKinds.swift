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
    case WhereNowTextLocationOnlyWidget
    case WhereNowWeatherTextWidget
    case WhereNowLongWeatherWidget
    case WhereNowBirdSightingsWidget
    case WhereNowNotableBirdSightingsWidget
    
    var description: String {
        switch self {
            case .WhereNowMapWidget:
                return "WhereNowMapWidget"
            case .WhereNowMapAndWeatherWidget:
                return "WhereNowMapAndWeatherWidget"
            case .WhereNowTextWidget:
                return "WhereNowTextWidget"
            case .WhereNowTextLocationOnlyWidget:
                return "WhereNowTextLocationOnlyWidget"
            case .WhereNowWeatherTextWidget:
                return "WhereNowWeatherTextWidget"
            case .WhereNowLongWeatherWidget:
                return "WhereNowLongWeatherTextWidget"
            case .WhereNowBirdSightingsWidget:
                return "WhereNowBirdSightingsWidget"
            case .WhereNowNotableBirdSightingsWidget:
                return "WhereNowNotablBirdSightingsWidget"
        }
    }
}
