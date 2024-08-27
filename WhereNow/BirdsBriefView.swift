//
//  BirdsBriefView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI
import WidgetKit

#if canImport(SafariServices)
import SafariServices
#if canImport(UIKit)
import UIKit
#endif
#endif
import AVFoundation

struct BirdsBriefView: View {
    let birdData: BirdSightingService
    let briefing: String
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                LazyHStack(alignment:.top) {
                    VStack(alignment: .leading) {
                        Text("🦅 Especially Notable Bird Reports thanks to Cornell Lab of Ornithology and the Macauley Library.")
                            .frame(width: geometry.size.width)
                            .lineLimit(5)
                        ScrollView() {
                            VStack(alignment: .leading, content: {
                                BirdSightingsView(birdData: birdData, notables: true)
                                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                            })
                        }.frame(width: geometry.size.width)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("🐥 Avian data provided by the Lab of Ornithology and Macauley Library of Cornell University")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 1)
                            .lineLimit(3)
                        Text("🐦 Birds sighted near here recently:")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 4)
                        ScrollView {
                            Text("🐣 " + briefing)
                                .font(.caption)
                                .bold()
                                .font(.system(size: descriptionSize))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)
                                .lineLimit(1000000)
                        }
                    }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    
                    ScrollView {
                        BirdSightingsView(birdData: birdData)
                            .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    }
                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                }
                .scrollTargetLayout()
            }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                .scrollTargetBehavior(.paging)
        }
    }
}

struct BirdSightingsView: View {
    let birdData: BirdSightingService
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    @State private var isFullScreen = false
    
    var notables: Bool? = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment:.leading, spacing: 9) {
                    ForEach(notables == true ? birdData.notableSightings : birdData.sightings, id: \.self) { sighting in
                        LazyHStack(alignment:.top) {
                            BirdSightingDescriptionView(sighting: sighting)
                            .frame(width: geometry.size.width*9/10, height: 163)
                            Spacer()
                                .frame(width: 1, height: 1)
                        }
                    }
                }.frame(width: geometry.size.width)
            }.frame(width: geometry.size.width)
        }
    }
}

struct BirdSightingDescriptionView: View {
    let sighting: BirdSighting
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    var body: some View {
        LazyVStack(alignment:.leading, spacing: 0) {
            Text(Fun.eBirdjis.randomElement() ?? "")
                .font(.system(size: descriptionSize))
                .multilineTextAlignment(.leading)
            if let commonName = sighting.comName {
                Text(commonName)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let name = sighting.sciName {
                Text(name)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let location = sighting.locName {
                Text("Location: " + location)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let date = sighting.obsDt {
                Text("Date: " + date)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let quantity = sighting.howMany {
                Text("Quantity: \(quantity)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let locationPrivate = sighting.locationPrivate {
                Text("In public location: \(locationPrivate == false)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let name = sighting.comName, let nameURLString = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string:"https://www.youtube.com/results?search_query=\(nameURLString)") {
                Link("📺 Tap to search on YouTube", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .padding([.bottom], 3)
             }
            if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://media.ebird.org/catalog?taxonCode=\(speciesURLString)&mediaType=photo") {
                Link("🖼️ Tap to see photos", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .padding([.bottom], 3)
            }
            if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://media.ebird.org/catalog?taxonCode=\(speciesURLString)&mediaType=audio") {
                Link("🎼🔊 Tap for recordings", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
