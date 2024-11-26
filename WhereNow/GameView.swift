//
//  GameView.swift
//  WhereNow
//
//  Created by Jónótdón Lavallee Ó Coileáin on 11/25/24.
//

import SwiftUI

enum TypeOfFood: CaseIterable {
    case nut
    case berry
    case worm
    case clam
    case crab
    case fish
    case urchin
    case frenchFry
    case pizza
    case carrot
    
    var imageName: String {
        switch self {
        case .nut: return "nut"
        case .berry: return "berry"
        case .clam: return "clam"
        case .crab: return "crab"
        case .fish: return "fish"
        case .urchin: return "urchin"
        case .pizza: return "pizza"
        case .worm: return "worm"
        case .frenchFry: return "frenchFry"
        case .carrot: return "carrot"
        }
    }
}

struct Food {
    let id: Int
    let type: TypeOfFood
    var coordinate: CGPoint
}

struct FoodView {
    var food: [Food] = []
    var body: some View {
        Text("Food Now!")
    }
}

struct GameView: View {
    @State var tapped: Bool = false
    @State var chomp: Bool = false

    var body: some View {
        GeometryReader { geometry in
            Spacer()
            VStack(spacing: 25) {
                Spacer()
                ZStack {
                    RotateObjectInEllipsePath(tapped: $tapped, chomp: $chomp, height: BirdView.birdHeight + SpinWhenTapped.jumpHeight, width: geometry.size.width)
                    
                    BirdView(tapped: $tapped, chomp: $chomp)
                }
                /*.overlay(alignment: .center, content: {
                    ScoreView(score: score)
                        .padding(.top, 300)
                })*/
                Spacer()
            }
            Spacer()
        }
    }
}

struct BirdView: View {
    @Binding var tapped: Bool
    @Binding var chomp: Bool
    static let birdWidth:CGFloat = 152
    static let birdHeight: CGFloat = 102
    var body: some View {
        ZStack {
            Image("Pheonixy")
                .resizable()
                .frame(width: 154, height: 167)
                .opacity(tapped ? 0 : 1)
            Image("PurpleBird")
                .resizable()
                .frame(width: BirdView.birdWidth, height: BirdView.birdHeight)
            Image("BlueGlow")
                .resizable()
                .frame(width: 152, height: 102)
                .opacity(tapped && chomp ? 1 : 0)
        }
        .frame(width: 152, height: 105)
        .modifier(SpinWhenTapped(tapToggler: $tapped, chomp: $chomp, tapActionNotification: "tapped", labelString: "Bird says:"))
    }
}

struct ScoreView: View {
    @Binding var score: Int
    
    var body: some View {VStack {
        Text(score == 0 ? "Tap the bird now to play!" : "\(score)")
            .foregroundStyle(.blue)
        if score > 0 {
            Button(action: {
                score = 0
            }) {
                Text("Reset")
            }.buttonStyle(.bordered)
        }
    }
    }
}

struct RotateObjectInEllipsePath: View {
    @Binding var tapped: Bool
    @State var score: Int = 0
    @Binding var chomp: Bool
    let foods: [TypeOfFood] = [.carrot]//TypeOfFood.allCases
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State var food = TypeOfFood.carrot
    let height: CGFloat// = 450.0
    let width: CGFloat// = 250.0
    static let imageSize: CGFloat = 35
    @State private var angle: Double = .zero
    
    @State private var ellipseX: CGFloat = .zero
    @State private var ellipseY: CGFloat = .zero
    var currentLocation: CGPoint? = nil
    var body: some View {
        VStack {
            Ellipse()
                .strokeBorder(Color.clear, lineWidth: 2)
                .frame(width: width, height: height)
                .overlay(
                    Image(systemName: food.imageName)
                        .resizable()
                        .frame(width: RotateObjectInEllipsePath.imageSize, height: RotateObjectInEllipsePath.imageSize)
                        .rotationEffect(.degrees(angle))
                        .offset(x: ellipseX, y: ellipseY)
                        .opacity(ellipseY < 1 || chomp == true ? 1.0 : 0)
                )
                .overlay(content: {
                    ScoreView(score: $score)
                        .padding(.top, 270)
                })
            
            Spacer()
                .frame(height: 40)
        }// VStack
        .animation(.default)
        .onReceive(timer) { _ in
            angle += 1
            let theta = CGFloat(.pi * angle / 180)
            ellipseX = width / 2 * cos(theta)
            ellipseY = height / 2 * sin(theta)
        }
        .onChange(of: ellipseY) { oldValue, newValue in
            if oldValue < 0 && newValue >= 0 {
                chomp = false
            }
        }
        .onChange(of: tapped) { oldValue, newValue in
            let maximum = (BirdView.birdWidth / 2) - (BirdView.birdWidth * 0.35)
            let minimum = 0 - (BirdView.birdWidth / 2) - (BirdView.birdWidth * 0.35)
            if newValue && ellipseY < 0 &&  ellipseX >= minimum && ellipseX <= maximum {
                chomp = true
                print("chomp detection at \(ellipseX), \(ellipseY)")
            } else {
                print("miss")
                print("tap detection at \(ellipseX), \(ellipseY)")
                print("max \(maximum)")
                print("min \(minimum)")
            }
        }
        .onChange(of: chomp) { _, newValue in
            if newValue == true {
                print("Chomp!")
                score += 100
            }
        }
    }
    
}

struct SpinWhenTapped: ViewModifier {
    @Binding var tapToggler: Bool
    @Binding var chomp: Bool
    static let jumpHeight:CGFloat = 400
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
            Spacer()
            
            content
                .onChange(of: spun) { _,_  in
                    self.randomOrder = CGFloat([-1,1].randomElement() ?? 1)
                    self.randomDuration1 = CGFloat([0,1].randomElement() ?? 1)
                }
                .shadow(color: .blue, radius: glow ? 10 : 0, x: 0, y: 0)
                .rotationEffect(.degrees(wobble1 ? randomOrder * SpinWhenTapped.wobbleDegrees2 : 0))
                .rotationEffect(.degrees(wobble2 ? randomOrder *  SpinWhenTapped.wobbleDegrees : 0))
                .rotationEffect(.degrees(spinning ? 540 : spun ? 720 : 0))
                .scaleEffect(spinning ? 2.0 : 1.0)
                .onTapGesture {
                    glow = true
                    tapToggler = true
                    withAnimation(.easeOut(
                        duration: randomDuration1 + randomDuration2 + randomDuration3
                    )) {
                        glow = false
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
                        tapToggler = false
                    }
                    withAnimation(.linear(duration: randomDuration3).delay(wobbleStartTime + randomDuration1 + randomDuration2)) {
                        wobble2 = true
                    }
                    withAnimation(.easeOut(duration: randomDuration4).delay(wobbleStartTime + randomDuration1 + randomDuration2 + randomDuration3)) {
                        wobble2 = false
                        chomp = false
                    }
                }
                .padding([.bottom], $spinning.wrappedValue ? SpinWhenTapped.jumpHeight : 0)
            
            Spacer(minLength: 100)
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
