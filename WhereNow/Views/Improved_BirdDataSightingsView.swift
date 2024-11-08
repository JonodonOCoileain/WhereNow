
//
//  BirdSightingDescriptionView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI

struct Improved_BirdSightingDescriptionView: View {
    let birdData: [BirdSighting]
    
    // Define constants for font size and spacing to enhance readability and maintainability
    private let fontSize: CGFloat = 12
    private let verticalSpacing: CGFloat = 9
    private let paddingAmount: CGFloat = 16

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: verticalSpacing) {
                ForEach(birdData) { sighting in
                    Improved_BirdSightingView(sighting: sighting, fontSize: fontSize, spacing: verticalSpacing)
                }
            }
            .padding(paddingAmount)
        }
    }
}

// Subcomponent to handle individual bird sighting display
struct Improved_BirdSightingView: View {
    let sighting: BirdSighting
    let fontSize: CGFloat
    let spacing: CGFloat
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: spacing) {
            // Handle empty array case for eBirdjis
            Text(Fun.eBirdjis.randomElement() ?? "🐦")
                .font(.system(size: fontSize))
                .multilineTextAlignment(.leading)
            
            Text(sighting.description())
                .font(.system(size: fontSize))
                .multilineTextAlignment(.leading)
                .lineLimit(8)
        }
    }
}
