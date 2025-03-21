//
//  Objects.swift
//  WhereNow
//
//  Created by Jon on 7/29/24.
//


import MapKit
import Foundation
import CoreLocation
import SwiftUI

public struct ErrorView: View {
    // MARK: - Config

    private enum Config {
        /// The color to use as a background in case we have an invalid map image.
        static let fallbackColor = Color(red: 225 / 255,
                                         green: 239 / 255,
                                         blue: 210 / 255)
    }

    // MARK: - Public properties

    let errorMessage: String?

    // MARK: - Render

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            Config.fallbackColor
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .padding()
            }
        }
    }
}


protocol LocationStorageManaging {
    func set(location: CLLocation, forKey key: String)
    func location(forKey key: String) -> CLLocation?
}

protocol WeatherStorageManaging {
    func set(weather: ForecastInfo, forKey key: String)
    func weather(forKey key: String) -> ForecastInfo?
}

// MARK: - Helpers

struct fading: ViewModifier {
    func body(content: Content) -> some View {
        content
            .mask(
                HStack(spacing: 0) {

                    // Left gradient
                    LinearGradient(gradient:
                       Gradient(
                           colors: [Color.black.opacity(0), Color.black]),
                           startPoint: .leading, endPoint: .trailing
                       )
                       .frame(width: 50)

                    // Middle
                    Rectangle().fill(Color.black)

                    // Right gradient
                    LinearGradient(gradient:
                       Gradient(
                           colors: [Color.black, Color.black.opacity(0)]),
                           startPoint: .leading, endPoint: .trailing
                       )
                       .frame(width: 50)
                }
             )
    }
}
