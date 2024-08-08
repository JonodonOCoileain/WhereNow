//
//  BirdsBriefView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI
import WidgetKit

struct BirdsBriefView: View {
    let birdData: BirdSightingService
    let briefing: String
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                LazyHStack(alignment:.top) {
                    VStack(alignment: .leading) {
                        Text("🐦 Birds sighted near here recently:")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 4)
                        Text("🐣 " + briefing)
                            .font(.caption)
                            .bold()
                            .font(.system(size: descriptionSize))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                        Spacer()
                    }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    
                    ScrollView {
                        BirdSightingsView(birdData: birdData)
                    }
                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                }
                .scrollTargetLayout()
            }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                .scrollTargetBehavior(.paging)
        }
    }
}

struct BirdSightingsView: View {
    let birdData: BirdSightingService
    var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading, spacing: 9) {
                ForEach(birdData.sightings, id: \.self) { sighting in
                    LazyVStack(alignment:.leading, spacing: 9) {
                        Text(Fun.eBirdjis.randomElement() ?? "")
                            .font(.system(size: 12))
                            .multilineTextAlignment(.leading)
                        Text(sighting.description())
                            .font(.system(size: 12))
                            .multilineTextAlignment(.leading)
                            .lineLimit(8)
                    }
                }
            }
        }.padding(.all)
    }
}

struct BirdBriefView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            BirdsBriefView(birdData: BirdSightingService(sightings: [BirdSighting(speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBirdo", comName: "Big Birdo", sciName: "Birdius Bigiuso", locId: "SesameStreeto", locName: "Sesame Street, PAO", obsDt: "Todayo", howMany: 100, lat: 43.1861, lng: 72.8730, obsValid: true, obsReviewed: true, locationPrivate: true),BirdSighting(speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBirdu", comName: "Big Birdu", sciName: "Birdius Bigiusu", locId: "SesameStreetu", locName: "Sesame Street, PAU", obsDt: "Todayu", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBird", comName: "Big Bird", sciName: "Birdius Bigius", locId: "SesameStreet", locName: "Sesame Street, PA", obsDt: "Today", howMany: 1, lat: 40.1861, lng: 74.8730, obsValid: true, obsReviewed: true, locationPrivate: false),BirdSighting(speciesCode: "BigBirda", comName: "Big Birda", sciName: "Birdius Bigiusa", locId: "SesameStreetA", locName: "Sesame Street, PAA", obsDt: "TodayA", howMany: 1, lat: 41.1861, lng: 75.8730, obsValid: true, obsReviewed: true, locationPrivate: false)]), briefing: "Some bird... What bird... a bird... how birdy was the bird? I belive it was very bird")
        }
    }
}

