//
//  LocationViewTab.swift
//  WhereNow
//
//  Created by Jon on 11/15/24.
//

import SwiftUI
#if canImport(OpenAI)
import OpenAI
#endif
import MapKit

struct LocationViewTab: View {
    @EnvironmentObject var locationData: LocationDataModel
    @EnvironmentObject var birdData: BirdSightingService
#if canImport(OpenAI)
    let openAI = OpenAI(apiToken: "sk-svcacct-M1ecwlvlJF9AWuO3eyl5woX2xl2BIYQhuu_T2erVswHzxA8riFSwVHsJTBE3WIqJT3BlbkFJujXWhdiTuCbOZSo2cJDwdn3c0yqJIezlJYUtD-d1kJOiFoEHgI4e5aqJ9G4F1ikA")
    @State var timeAskedOpenAI: Date?
    @State var openAIDescription: String = ""
#endif
    
    func askOpenAI() async {
        if let location = locationData.addresses.first?.postalCode {
#if canImport(OpenAI)
            timeAskedOpenAI = Date()
            let query = ChatQuery(messages: [
                .init(role: .user, content: "What birds might I see today near \(location)")!
            ], model: .gpt4_o_mini)
            do {
                let result = try await openAI.chats(query: query)
                openAIDescription = result.choices.first?.message.content ?? ""
                print(result.choices.first?.message.content ?? "No response")
                print("Result")
            } catch {
                print(error)
            }
#endif
        }
    }
    
    var body: some View {
        ScrollView() {
            VStack {
                Text(self.locationData.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                    .multilineTextAlignment(.center)
                if let coordinate = locationData.currentLocation?.coordinate {
                    Map() {
                        Marker("Here", coordinate: coordinate)
                        
                        ForEach(self.birdData.sightings) { sighting in
                            if let lat = sighting.lat, let lng = sighting.lng {
                                Marker(sighting.comName ?? "bird", systemImage: "bird.fill", coordinate: CLLocationCoordinate2D(latitude: Double(lat), longitude: Double(lng)))
                            }
                        }
                    }
                    .frame(minHeight: 300)
                }
#if canImport(OpenAI)
                if openAIDescription.count > 0 {
                    Text("OpenAI says: \n\(openAIDescription)")
                        .font(.caption2)
                        .padding()
                }
#endif
            }.task {
#if canImport(OpenAI)
                let earlyDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
                if let timeAsked = timeAskedOpenAI, timeAsked < earlyDate {
                    await askOpenAI()
                } else if timeAskedOpenAI == nil {
                    await askOpenAI()
                }
#endif
            }
        }
    }
}
