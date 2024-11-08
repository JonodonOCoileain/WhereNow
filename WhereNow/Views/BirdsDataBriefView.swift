//
//  BirdsDataBriefView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI

struct BirdsDataBriefView: View {
    let birdData: [BirdSighting]
    let briefing: String
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack(alignment:.top) {
                    VStack(alignment: .leading) {
                        Text("🐦 Birds sighted near here recently:")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 4)
                        Text("🐣 " + briefing)
                            .font(.caption)
                            .bold()
                            .font(.system(size: descriptionSize))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                        Spacer()
                    }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    
                    ScrollView {
                        BirdSightingDescriptionView(birdData: birdData)
                    }
                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                }
                .scrollTargetLayout()
            }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                .scrollTargetBehavior(.paging)
        }
    }
}
