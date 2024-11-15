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
    @State var tapping: Bool = false
    let setting: String
    var body: some View {
        TextView()
            .modifier(UpdatedSpinnable(tapToggler: $tapping, tapActionNotification: "\(setting) \($tapping.wrappedValue ? "selected" : "deselected")"))
        
    }
}

struct Spinnable: ViewModifier {
    @Binding var tapToggler: Bool
    @State private var spinning = false
    @State private var spun = false
    let timer = Timer.publish(every: 0.34, on: .main, in: .common).autoconnect()
    @State var currentRandom:Int? = [1,2].randomElement()
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
                tapToggler.toggle()
                spinning.toggle()
                if spinning == false {
                    spun.toggle()
                }
            }
            .onReceive(timer) { input in
                self.currentRandom = [1,2].randomElement()
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

struct UpdatedSpinnable: ViewModifier {
    @Binding var tapToggler: Bool
    var tapActionNotification: String
    @State private var spinning = false
    @State private var spun = false
    func body(content: Content) -> some View {
        VStack {
            content
                .font(.largeTitle)
                .foregroundStyle(.white)
                .padding()
                .background(.blue)
                .clipShape(.rect(cornerRadius: 10))
                .rotationEffect(.degrees(spinning ? 540 : spun ? 720 : 0))
                .scaleEffect(spinning ? 1 : 0.6)
                .onTapGesture {
                    tapToggler.toggle()
                    withAnimation(.smooth(duration: 0.4).delay(0)) {
                        spinning.toggle()
                    }
                    withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                        spun.toggle()
                        spinning.toggle()
                    }
                }
            Text(tapActionNotification).opacity($spinning.wrappedValue ? 1.0 : 0.0001)
                .padding([.top], $spinning.wrappedValue ? 100 : 20)
        }
    }
}

struct NewView_Previews: PreviewProvider {
    static var previews: some View {
        SpinningBlueRoundedRectangle(setting: "Demo")
    }
}
