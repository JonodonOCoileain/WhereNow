//
//  ViewModifiers.swift
//  WhereNow
//
//  Created by Jon on 8/27/24.
//

import SwiftUI

struct SomeView: View {
    @State var clicked: Bool = false
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            VStack {
                Text("Star says:")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                    .padding()
                SpinningBlueRoundedRectangle()
            }
            .modifier(AppearingView(trigger: $clicked))
        }
        .onTapGesture {
            clicked.toggle()
        }
        
    }
}

struct TextView: View {
    var body: some View {
        Text("Hello")
    }
}

struct SpinningBlueRoundedRectangle: View {
    var body: some View {
        TextView()
            .modifier(Spinnable())
    }
}

struct Spinnable: ViewModifier {
    @State private var spinning = false
    @State private var spun = false
    func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundStyle(.white)
            .padding()
            .background(.blue)
            .clipShape(.rect(cornerRadius: 10))
            .rotationEffect(.degrees(spinning ? 180 : spun ? 360 : 0))
            .scaleEffect(spinning ? 1 : 0.6)
            .padding()
            .animation(.easeInOut, value: spinning)
            .onTapGesture {
                spinning.toggle()
                if spinning == false {
                    spun.toggle()
                }
            }
    }
}

struct AppearingView: ViewModifier {
    @Binding var trigger: Bool
    
    func body(content: Content) -> some View {
        content.scaleEffect(trigger ? 1 : 0)
            .animation(.easeInOut, value: trigger)
            .frame(maxWidth: trigger ? .infinity : 0)
    }
}

struct SpecialAppearingView: ViewModifier {
    @Binding var showLocation: Bool
    @Binding var hideLocationTime: Double
    @Binding var showLocationTime: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(showLocation ? 1 : 0)
            .offset(y: hideLocationTime > showLocationTime ? -200 * (Date().timeIntervalSince1970 - hideLocationTime)/0.35 : (hideLocationTime < showLocationTime && showLocationTime >= 0.35+Date().timeIntervalSince1970  ? -10 * (showLocationTime - Date().timeIntervalSince1970)/0.35 : 0))
            .frame(maxHeight: showLocationTime < Date().timeIntervalSince1970 - 0.35 && showLocationTime > hideLocationTime ? .infinity : Date().timeIntervalSince1970 > hideLocationTime + 0.35 && hideLocationTime > showLocationTime ? 0 : Date().timeIntervalSince1970 < hideLocationTime + 0.35 && Date().timeIntervalSince1970 > hideLocationTime ? 500 * (Date().timeIntervalSince1970 - hideLocationTime)/0.35 : .infinity)
            .animation(.easeInOut, value: showLocation)
    }
}

struct Modifiers_Previews: PreviewProvider {
    static var previews: some View {
        SomeView()
                .previewDevice("iPhone 15 Pro")
    }
}
