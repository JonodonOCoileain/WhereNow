//
//  NotableBirdSightingsViews.swift
//  WhereNow
//
//  Created by Jon on 11/14/24.
//

import SwiftUI

struct WatchBirdSightingsViews: View {
    @EnvironmentObject var birdData: BirdSightingService
    @EnvironmentObject var locationData: LocationDataModel
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    let verySmallSize: CGFloat = 9
    let width: CGFloat
    var body: some View {
        VStack(alignment: .leading) {
            Text("🦅 Especially Notable Bird Reports")
                .multilineTextAlignment(.leading)
                .frame(width: width)
                .lineLimit(5)
                .font(.system(size: descriptionSize))
                .fixedSize(horizontal: true, vertical: false)
                .clipped()
            Text("Made available by Cornell University")
                .multilineTextAlignment(.leading)
                .frame(width: width)
                .lineLimit(5)
                .font(.system(size: verySmallSize))
                .fixedSize(horizontal: true, vertical: false)
                .clipped()
            
            ScrollView(.horizontal) {
                HStack(alignment: .top, content: {
                    ForEach(birdData.notableSightings, id: \.self) { sighting in
                        WatchBirdSightingView(sighting: sighting, notables: true, width: width)
                            .clipped()
                    }
                })
                .scrollTargetLayout()
            }
            .scrollIndicatorsFlash(onAppear: true)
            .scrollTargetBehavior(.paging)
        }
        .onAppear() {
            print("NotableBirdSightingsViews appeared")
        }
    }
}
