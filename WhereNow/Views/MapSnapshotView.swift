//
//  MapSnapshotView.swift
//  WhereNow
//
//  Created by Jon on 11/15/24.
//

import SwiftUI

struct MapSnapshotView: View {
    var image: Image
    var body: some View {
        ZStack {
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 400, maxHeight: 400)
                .edgesIgnoringSafeArea(.all)
                .cornerRadius(20)
                .clipped()
                .padding()
            
            // The map is centered on the user location, therefore we can simply draw the blue dot in the
            // center of our view to simulate the user coordinate.
            Circle()
                .foregroundColor(.blue)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .frame(width: 15,
                       height: 15)
        }.padding()
    }
}
