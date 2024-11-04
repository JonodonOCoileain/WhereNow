//
//  BirdDataSightingsShortView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//
import SwiftUI

struct BirdDataSightingsShortView: View {
    let birdData: [BirdSighting]
    var notables: Bool? = false
    var body: some View {
        VStack() {
            Text(notables == true ? "Especially notable 🐦 sightings near here recently:" : "🐦 Birds sighted near here recently:")
                .font(.system(size: 12))
                .multilineTextAlignment(.leading)
                .padding([.horizontal])
                .padding(.bottom, 4)
                .lineLimit(1000000)
            Text("🐣 " + birdData.compactMap({"\($0.comName ?? "")@\($0.locName ?? "")"}).joined(separator: ", \(Fun.eBirdjis.randomElement() ?? "")"))
                .font(.system(size: 12))
                .bold()
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .lineLimit(1000000)
        }
    }
}
