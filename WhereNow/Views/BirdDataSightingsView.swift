//
//  BirdDataSightingsView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//
import SwiftUI

struct BirdDataSightingsView: View {
    let birdData: [BirdSighting]
    var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading, spacing: 9) {
                ForEach(birdData, id: \.id) { sighting in
                    LazyVStack(alignment:.leading, spacing: 9) {
                        Text(Fun.eBirdjis.randomElement() ?? "")
                            .font(.system(size: 12))
                            .multilineTextAlignment(.leading)
                        Text(sighting.description())
                            .font(.system(size: 12))
                            .multilineTextAlignment(.leading)
                            .lineLimit(8)
                    }
                }
            }
        }.padding(.all)
    }
}
