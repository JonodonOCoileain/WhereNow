//
//  HeaderView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//

import SwiftUI

struct HeaderView: View {
    @Binding var isPresenting: Bool
    @Binding var showTimeTracker: Double
    @Binding var hideTimeTracker: Double
    let title: String
    var spinningText: String? = nil
    @State private var textIsSpinning = 0.0
    var body: some View {
        HStack(content: {
            #if os(watchOS)
            Text(title)
                .font(.caption)
            #else
            Text(title)
                .font(.title)
            #endif
            if let spinningText = spinningText {
                Text(spinningText)
                    .font(.caption)
                    .rotationEffect(.degrees(textIsSpinning))
                    .onAppear {
                        withAnimation(.linear(duration: 1)
                            .speed(0.1).repeatForever(autoreverses: false)) {
                                textIsSpinning = 360.0
                            }
                    }
            }
            Spacer()
            Image(systemName: "chevron.compact.down")
                .foregroundColor(.gray)
                .rotationEffect(.degrees(isPresenting ? 0 : 180))
                .animation(Animation.easeInOut(duration: 0.3), value: isPresenting)
        })
        .padding()
        .background()
        .onTapGesture {
            isPresenting.toggle()
            if isPresenting {
                showTimeTracker = Date().timeIntervalSince1970
            } else {
                hideTimeTracker = Date().timeIntervalSince1970
            }
        }
    }
}

