//
//  NotableBirdSightingsViews.swift
//  WhereNow
//
//  Created by Jon on 11/14/24.
//

import SwiftUI

struct WatchNotableBirdSightingsViews: View {
    @ObservedObject var birdData: BirdSightingService
    @ObservedObject var locationData: LocationDataModel
    let briefing: String
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    let verySmallSize: CGFloat = 12
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Text("🦅 Especially Notable Bird Reports thanks to Cornell Lab of Ornithology and the Macauley Library.")
                    .multilineTextAlignment(.leading)
                    .frame(width: geometry.size.width)
                    .lineLimit(5)
                    .font(.system(size: verySmallSize))
                    .fixedSize(horizontal: true, vertical: false)
                ScrollView(.horizontal) {
                    HStack(alignment: .top, content: {
                        ForEach(birdData.notableSightings, id: \.self) { sighting in
                            WatchBirdSightingView(geometry: geometry, sighting: sighting, locationData: locationData, currentLocation: locationData.currentLocation.coordinate, birdData: birdData, notables: true)
                                .frame(width: geometry.size.width - 3)
                                .clipped()
                        }
                    })
                    .scrollTargetLayout()
                    .frame(minWidth: geometry.size.width, maxWidth: .infinity, minHeight: 250, maxHeight: 280)
                }
                .scrollTargetBehavior(.paging)
                .frame(width: geometry.size.width)
                Spacer()
            }.frame(width: geometry.size.width, height: 300)
            .onAppear() {
                print("NotableBirdSightingsViews appeared")
            }
        }
    }
}
