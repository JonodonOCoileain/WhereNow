//
//  GameView.swift
//  WhereNow
//
//  Created by Jónótdón Lavallee Ó Coileáin on 11/25/24.
//

import SwiftUI

struct GameView: View {
    @State var tapped: Bool = false
    var body: some View {
        Image(systemName: "bird")
            .modifier(SpinWhenTapped(tapToggler: $tapped, tapActionNotification: "tapped", labelString: "Bird says:"))
    }
}


struct SpinWhenTapped: ViewModifier {
    @Binding var tapToggler: Bool
    
    var tapActionNotification: String
    var labelString: String
    @State var glow: Bool = false
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
    static let wobbleDegrees2:CGFloat = CGFloat.goldenRatio * SpinWhenTapped.wobbleDegrees * -1
    
    let wobbleStartTime: Double = 1.0//Double.goldenRatio / 2
    
    func body(content: Content) -> some View {
        VStack {
#if targetEnvironment(simulator) && (os(iOS) || os(tvOS))
            Button(action: {
                spinning = false
                spun = false
                wobble1 = false
                wobble2 = false
            }, label: { Text("Reset") })
            Text("randomOrder: \(randomOrder)")
            Spacer()
#endif
            content
                .font(.largeTitle)
                .foregroundStyle(.yellow)
                .onChange(of: spun) { _,_  in
                    self.randomOrder = CGFloat([-1,1].randomElement() ?? 1)
                    self.randomDuration1 = CGFloat([0,1].randomElement() ?? 1)
                }
                .clipShape(.rect(cornerRadius: 10))
                .rotationEffect(.degrees(wobble1 ? randomOrder * SpinWhenTapped.wobbleDegrees2 : 0))
                .rotationEffect(.degrees(wobble2 ? randomOrder *  SpinWhenTapped.wobbleDegrees : 0))
                .rotationEffect(.degrees(spinning ? 540 : spun ? 720 : 0))
                .scaleEffect(spinning ? 2.0 : 1.0)
                .onTapGesture {
                    tapToggler.toggle()
                    withAnimation(.smooth(
                        duration: randomDuration1 + randomDuration2 + randomDuration3 + randomDuration4
                    )) {
                        
                    }
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
            Text(labelString)
                .font(.largeTitle)
                .foregroundStyle(.yellow)
                .padding([.top], $spinning.wrappedValue ? 120 : 20)
            if tapActionNotification.count > 0 {
                Text(tapActionNotification).opacity($spinning.wrappedValue ? 1.0 : 0.0001)
                    .padding([.top], $spinning.wrappedValue ? 100 : 20)
            } else {
                Text(tapActionNotification).opacity($spinning.wrappedValue ? 1.0 : 0.0001)
            }
            Spacer()
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
