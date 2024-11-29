//
//  GameView.swift
//  WhereNow
//
//  Created by Jónótdón Lavallee Ó Coileáin on 11/25/24.
//

import SwiftUI
import AVFAudio
// by Luca Angeletti
extension String {
    func toUIImage() -> UIImage {
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.set()
        let rect = CGRect(origin: .zero, size: size)
        //UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 50)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

enum TypeOfFood: Int, CaseIterable {
    case nut
    case blueberry
    case worm
    case oyster
    case crab
    case fish
    case lobstah
    case frenchFry
    case pizza
    case carrot
    case snail
    
    var imageName: String {
        switch self {
        case .nut: return "🌰"
        case .blueberry: return "🫐"
        case .oyster: return "🦪"
        case .crab: return "🦀"
        case .fish: return "🐠"
        case .lobstah: return "🦞"
        case .pizza: return "🍕"
        case .worm: return "🪱"
        case .frenchFry: return "🍟"
        case .carrot: return "🥕"
        case .snail: return "🐌"
        }
    }
    
    var color: Color {
        switch self {
        case .nut: return Color.brown
        case .blueberry: return Color.blue
        case .oyster: return Color.red
        case .crab: return Color.red
        case .fish: return Color.blue
        case .lobstah: return Color.red
        case .pizza: return Color.red
        case .worm: return Color.brown
        case .frenchFry: return Color(red: 1.0, green: 0.8431372549, blue: 0)
        case .carrot: return Color.orange
        case .snail: return Color.brown
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
    @State var foods: [TypeOfFood] = TypeOfFood.allCases
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State var food = Food(id: 0, type: TypeOfFood(rawValue: Int.random(in: 0...TypeOfFood.allCases.count)) ?? .carrot, coordinate: CGPoint())
    let height: CGFloat// = 450.0
    let width: CGFloat// = 250.0
    static let imageSize: CGFloat = 35
    @State private var angle: Double = .zero
    
    @State private var ellipseX: CGFloat = .zero
    @State private var ellipseY: CGFloat = .zero
    var currentLocation: CGPoint? = nil
    var body: some View {
        VStack {
            let imageName = food.type.imageName
            Ellipse()
                .strokeBorder(Color.clear, lineWidth: 2)
                .frame(width: width, height: height)
                .overlay(
                    Image(uiImage: imageName.toUIImage())
                        .resizable()
                        .backgroundStyle(.clear)
                        .frame(width: RotateObjectInEllipsePath.imageSize, height: RotateObjectInEllipsePath.imageSize)
                        .rotationEffect(.degrees(angle))
                        .offset(x: ellipseX, y: ellipseY)
                        .opacity(ellipseY < 1 && chomp == false ? 1.0 : 0)
                )
                .overlay(content: {
                    ScoreView(score: $score)
                        .padding(.top, 270)
                })
            
            Spacer()
                .frame(height: 40)
        }// VStack
        .animation(.default, value: 1)
        .onReceive(timer) { _ in
            angle += 1
            let theta = CGFloat(.pi * angle / 180)
            ellipseX = width / 2 * cos(theta)
            ellipseY = height / 2 * sin(theta)
        }
        .onChange(of: ellipseY) { oldValue, newValue in
            if oldValue < 0 && newValue >= 0 {
                chomp = false
                let point = food.coordinate
                foods.removeAll(where: { $0 == food.type })
                if foods.isEmpty {
                    foods = TypeOfFood.allCases
                }
                if let nextFood = foods.randomElement() {
                    foods.removeAll(where: { $0 == foods.randomElement()})
                    food = Food(id: food.id + 1, type: nextFood, coordinate: point)
                }
            }
        }
        .onChange(of: tapped) { oldValue, newValue in
            let maximum = (BirdView.birdWidth / 2) - (BirdView.birdWidth * 0.45)
            let minimum = 0 - (BirdView.birdWidth / 2) - (BirdView.birdWidth * 0.25)
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
    @State var audioPlayer: AVAudioPlayer!

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
                .onChange(of: spinning) { oldValue, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(randomDuration1 + randomDuration2 + randomDuration3), execute: {
                            if  self.chomp {
                                if let sound = Bundle.main.path(forResource: "whistle", ofType: "m4a") {
                                    print("whistle")
                                    self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
                                    self.audioPlayer.play()
                                }
                            }
                        })
                    }
                }
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
