
//
//  BirdSightingDescriptionView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI

public struct PlaygroundView: View {
    private let flexibleColumn = [
            GridItem(.flexible(minimum: 60, maximum: 60)),
            GridItem(.flexible(minimum: 60, maximum: 60)),
            GridItem(.flexible(minimum: 60, maximum: 60))
        ]
    
    public var body: some View {
        Text("Grid Example")
        ScrollView(.horizontal, content: {
            LazyVGrid(columns: flexibleColumn, content: {
                Text("text")
                Image(systemName: "figure.walk.circle.fill")
                Text("text")
                Image(systemName: "figure.walk.circle.fill")
                Text("text")
                Image(systemName: "figure.walk.circle.fill")
                Text("text")
                Image(systemName: "figure.walk.circle.fill")
            })
        })
        Spacer()
    }
}

#Preview("Hello World!") {
    PlaygroundView()
}

