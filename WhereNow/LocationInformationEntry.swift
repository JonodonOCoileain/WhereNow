//
//  LocationInformationEntry.swift
//  WhereNow
//
//  Created by Jon on 8/2/24.
//
import Foundation
import CoreLocation
import WidgetKit

struct LocationInformationEntry: TimelineEntry {
    let configuration: ConfigurationAppIntent? = nil
    // MARK: - Types

    enum State {
        /// The timeline provider asked for a placeholder.
        case placeholder

        /// We resolved a user-location and successfully created the map-snapshot.
        case success(LocationInformation)

        /// An error occurred.
        case failure(Error)
    }

    // MARK: - Public properties

    /// The date to display the widget. This property is required by the protocol `TimelineEntry`.
    let date: Date

    /// The current state of our entry.
    let state: State
    
    var shortDescription: String {
        switch self.state {
        case .placeholder:
            return "Planet Earth, Milky Way Galaxy"
        case .success(let locationInformation):
            let shortAddressArray: [String] = locationInformation.addresses?.compactMap({$0.formattedVeryShort()}) ?? ["Planet Earth, Milky Way Galaxy"]
            return shortAddressArray.joined(separator: "\n")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    
    var mediumLocationDescription: String {
        switch self.state {
        case .placeholder:
            return "Planet Earth, Milky Way Galaxy"
        case .success(let locationInformation):
            let shortAddressArray: [String] = locationInformation.addresses?.compactMap({$0.formattedShort()}) ?? ["Planet Earth, Milky Way Galaxy"]
            return shortAddressArray.joined(separator: "\n")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    
    var flagAndFreeformDescription: String {
        switch self.state {
        case .placeholder:
            return "Planet Earth, Milky Way Galaxy"
        case .success(let locationInformation):
            let freeformAddressArray: [String] = locationInformation.addresses?.compactMap({$0.flag() + " " + ($0.freeformAddress ?? "")}) ?? ["Planet Earth, Milky Way Galaxy"]
            return freeformAddressArray.joined(separator: "\n")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    
    var flagDescription: String {
        switch self.state {
        case .placeholder:
            return "🌍"
        case .success(let locationInformation):
            let freeformAddressArray: [String] = locationInformation.addresses?.compactMap({$0.flag()}) ?? ["🌍"]
            return freeformAddressArray.joined(separator: "\n")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    var townStateDescription: String {
        switch self.state {
        case .placeholder:
            return "Planet\nEarth"
        case .success(let locationInformation):
            let freeformAddressArray: [String] = locationInformation.addresses?.compactMap({ ($0.municipality ?? "") + "\n" + ($0.countrySubdivision ?? "")}) ?? ["Planet\nEarth"]
            return freeformAddressArray.joined(separator: "\n")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    var locationPlusWeatherDescription: String {
        switch self.state {
        case .placeholder:
            return "Planet Earth, Milky Way Galaxy\nWeather Now!"
        case .success(let locationInformation):
            let shortAddressArray: [String] = locationInformation.addresses?.compactMap({$0.formattedVeryShort()}) ?? ["Planet Earth, Milky Way Galaxy"]
            return shortAddressArray.joined(separator: "\n") + "\n" + (locationInformation.weather?.first?.forecast ?? "")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    var locationPlusWeatherDescriptionPlusEmoji: String {
        switch self.state {
        case .placeholder:
            return "Planet Earth, Milky Way Galaxy\nWeather Now!"
        case .success(let locationInformation):
            let shortAddressArray: [String] = locationInformation.addresses?.compactMap({$0.formattedVeryShort()}) ?? ["Planet Earth, Milky Way Galaxy"]
            return shortAddressArray.joined(separator: "\n") + "\n" + (locationInformation.weather?.first?.forecast ?? "") + (Fun.emojis.randomElement() ?? "")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    var weatherDescription: String {
        switch self.state {
        case .placeholder:
            return "Weather Now!"
        case .success(let locationInformation):
            return (locationInformation.weather?.first?.forecast ?? "")
        case .failure(let error):
            return error.localizedDescription
        }
    }
    var weatherPlusEmojiDescription: String {
        switch self.state {
        case .placeholder:
            return "Weather Now!"
        case .success(let locationInformation):
            return (locationInformation.weather?.first?.forecast ?? "") + (Fun.emojis.randomElement() ?? "")
        case .failure(let error):
            return error.localizedDescription
        }
    }
}
