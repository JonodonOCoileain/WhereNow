//
//  LocationViewTab.swift
//  WhereNow
//
//  Created by Jon on 11/15/24.
//

import SwiftUI
import OpenAI

struct LocationViewTab: View {
    @EnvironmentObject var locationData: LocationDataModel
    let openAI = OpenAI(apiToken: "sk-svcacct-M1ecwlvlJF9AWuO3eyl5woX2xl2BIYQhuu_T2erVswHzxA8riFSwVHsJTBE3WIqJT3BlbkFJujXWhdiTuCbOZSo2cJDwdn3c0yqJIezlJYUtD-d1kJOiFoEHgI4e5aqJ9G4F1ikA")
    @State var timeAskedOpenAI: Date?
    @State var openAIDescription: String = ""
    
    func askOpenAI() async {
        if let location = locationData.addresses.first?.postalCode {
            timeAskedOpenAI = Date()
            let query = ChatQuery(messages: [
                .init(role: .user, content: "What birds might I see today near \(location)")!
            ], model: .gpt4_o_mini)
            do {
                let result = try await openAI.chats(query: query)
                openAIDescription = result.choices.first?.message.content?.string ?? ""
                print(result.choices.first?.message.content ?? "No response")
                print("Result")
            } catch {
                print(error)
            }
        }
    }
    
    var body: some View {
        ScrollView() {
            VStack {
                Text(self.locationData.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                    .multilineTextAlignment(.center)
#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
                if let image = self.locationData.image {
                    MapSnapshotView(image: image)
                }
#endif
                if openAIDescription.count > 0 {
                    Text("OpenAI says: \n\(openAIDescription)")
                        .font(.caption2)
                        .padding()
                }
            }.task {
                let earlyDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
                if let timeAsked = timeAskedOpenAI, timeAsked < earlyDate {
                    await askOpenAI()
                } else if timeAskedOpenAI == nil {
                    await askOpenAI()
                }
            }
        }
    }
}
