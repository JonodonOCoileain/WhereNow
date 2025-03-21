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
        Text("WHERE NOW!")
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
    @State private var wobble1 = false
    @State private var wobble2 = false
    @State private var randomOrder: CGFloat = CGFloat([-1,1].randomElement() ?? 1)
    @State private var randomDuration1: CGFloat = CGFloat([0.1,0.15].randomElement() ?? 1)
    @State private var randomDuration2: CGFloat = CGFloat([0.1,0.15].randomElement() ?? 1)
    @State private var randomDuration3: CGFloat = CGFloat([0.1,0.15].randomElement() ?? 1)
    @State private var randomDuration4: CGFloat = CGFloat([0.1,0.15].randomElement() ?? 1)
    
    static let wobbleDegrees:CGFloat = -23.4
    static let wobbleDegrees2:CGFloat = CGFloat.goldenRatio * UpdatedSpinnable.wobbleDegrees * -1
    
    let wobbleStartTime: Double = 1.0//Double.goldenRatio / 2
    
    func body(content: Content) -> some View {
        VStack {
            /*#if targetEnvironment(simulator) && os(iOS)
            Button(action: {
                spinning = false
                spun = false
                wobble1 = false
                wobble2 = false
            }, label: { Text("Reset") })
            Text("randomOrder: \(randomOrder)")
            #endif*/
            content
                .onChange(of: spun) { _,_  in
                    self.randomOrder = CGFloat([-1,1].randomElement() ?? 1)
                    self.randomDuration1 = CGFloat([0,1].randomElement() ?? 1)
                }
                .font(.largeTitle)
                .foregroundStyle(.white)
                .padding()
                .background(.blue)
                .clipShape(.rect(cornerRadius: 10))
                .rotationEffect(.degrees(wobble1 ? randomOrder * UpdatedSpinnable.wobbleDegrees2 : 0))
                .rotationEffect(.degrees(wobble2 ? randomOrder *  UpdatedSpinnable.wobbleDegrees : 0))
                .rotationEffect(.degrees(spinning ? 540 : spun ? 720 : 0))
                .scaleEffect(spinning ? 1 : 0.6)
                .onTapGesture {
                    tapToggler.toggle()
                    withAnimation(.smooth(duration: CGFloat.goldenRatio/4).delay(0)) {
                        spinning.toggle()
                    }
                    withAnimation(.easeIn(duration: CGFloat.goldenRatio/4).delay(CGFloat.goldenRatio/4)) {
                        spun.toggle()
                        spinning.toggle()
                    }
                    withAnimation(.easeIn(duration: randomDuration1).delay(wobbleStartTime)) {
                        wobble1 = true
                    }
                    withAnimation(.linear(duration: randomDuration2).delay(wobbleStartTime + randomDuration1)) {
                        wobble1 = false
                    }
                    withAnimation(.linear(duration: randomDuration3).delay(wobbleStartTime + randomDuration1 + randomDuration2)) {
                        wobble2 = true
                    }
                    withAnimation(.easeOut(duration: randomDuration4).delay(wobbleStartTime + randomDuration1 + randomDuration2 + randomDuration3)) {
                        wobble2 = false
                    }
                }
            if tapActionNotification.count > 0 {
                Text(tapActionNotification).opacity($spinning.wrappedValue ? 1.0 : 0.0001)
                    .padding([.top], $spinning.wrappedValue ? 100 : 0)
            } else {
                Text(tapActionNotification).opacity($spinning.wrappedValue ? 1.0 : 0.0001)
                    .padding([.top], $spinning.wrappedValue ? 40 : 0)
            }
        }
    }
}

struct NewView_Previews: PreviewProvider {
    static var previews: some View {
        SpinningBlueRoundedRectangle(setting: "Demo")
    }
}



