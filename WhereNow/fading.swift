//
//  fading.swift
//  WhereNow
//
//  Created by Jonathan Lavallee Collins on 4/20/25.
//
import SwiftUI

struct fading: ViewModifier {
    func body(content: Content) -> some View {
        content
            .mask(
                HStack(spacing: 0) {

                    // Left gradient
                    LinearGradient(gradient:
                       Gradient(
                           colors: [Color.black.opacity(0), Color.black]),
                           startPoint: .leading, endPoint: .trailing
                       )
                       .frame(width: 50)

                    // Middle
                    Rectangle().fill(Color.black)

                    // Right gradient
                    LinearGradient(gradient:
                       Gradient(
                           colors: [Color.black, Color.black.opacity(0)]),
                           startPoint: .leading, endPoint: .trailing
                       )
                       .frame(width: 50)
                }
             )
    }
}
