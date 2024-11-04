//
//  BirdsBriefView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI
import WidgetKit
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(SafariServices)
import SafariServices
#if canImport(UIKit)
import UIKit
#endif
#endif
import AVFoundation

struct BirdSightingsViews: View {
    let birdData: BirdSightingService
    let briefing: String
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                LazyHStack(alignment:.top) {
                    VStack(alignment: .leading) {
                        Text("🦅 Especially Notable Bird Reports thanks to Cornell Lab of Ornithology and the Macauley Library.")
                            .frame(width: geometry.size.width)
                            .lineLimit(5)
                        ScrollView() {
                            VStack(alignment: .leading, content: {
                                BirdSightingsContainerView(birdData: birdData, notables: true)
                                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                            })
                        }.frame(width: geometry.size.width)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("🐥 Avian data provided by the Lab of Ornithology and Macauley Library of Cornell University")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 1)
                            .lineLimit(3)
                        Text("🐦 Birds sighted near here recently:")
                            .font(.system(size: titleSize))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal])
                            .padding(.bottom, 4)
                        ScrollView {
                            Text("🐣 " + briefing)
                                .font(.caption)
                                .bold()
                                .font(.system(size: descriptionSize))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)
                                .lineLimit(1000000)
                        }
                    }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    
                    ScrollView {
                        BirdSightingsContainerView(birdData: birdData)
                            .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    }
                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                }
                .scrollTargetLayout()
            }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                .scrollTargetBehavior(.paging)
        }
    }
}

struct BirdSightingsContainerView: View {
    let birdData: BirdSightingService
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    @State private var isFullScreen = false
    
    var notables: Bool? = false
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment:.leading, spacing: 9) {
                    ForEach(notables == true ? birdData.notableSightings : birdData.sightings, id: \.id) { sighting in
                        LazyHStack(alignment:.top) {
                            BirdSightingView(sighting: sighting, birdData: birdData)
                                .frame(width: geometry.size.width*9/10)
                            Spacer()
                                .frame(width: 1, height: 1)
                        }
                    }
                }.frame(width: geometry.size.width)
            }.frame(width: geometry.size.width)
        }
    }
}

class PlayerViewModel: ObservableObject {
  var audioPlayer: AVPlayer?

  @Published var isPlaying = false
    
    init(with url: URL? = nil) {
        if let url = url {
            self.audioPlayer = AVPlayer(url: url)
        }
    }
    
    func set(url: URL) {
        self.audioPlayer = AVPlayer(url: url)
    }
    
    func play() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.play()
        isPlaying = true
    }
    
    func pause() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.pause()
        isPlaying = false
    }
}

struct BirdSightingView: View {
    @State private var isPresented: Bool = false
    @State private var selectedDetailTitle: String?
    @State private var selectedDetailSubtitle: String?
    @State private var selectedBirdData: BirdSpeciesAssetMetadata?
    @ObservedObject var player = PlayerViewModel()
    let sighting: BirdSighting
    @ObservedObject var birdData: BirdSightingService
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    
    var body: some View {
        LazyVStack(alignment:.leading, spacing: 0) {
            if let code = sighting.speciesCode {
                let relatedData = birdData.speciesMedia.filter({$0.speciesCode == code})
                if relatedData.count > 0 {
                    HStack(alignment: .center) {
                        ForEach(relatedData.filter({$0.assetFormatCode == "photo"}), id: \.id) { imageData in
                            VStack {
                                AsyncImage(url: URL(string: imageData.url)){ image in
                                    image.resizable()
                                } placeholder: {
                                    Color.red
                                }
                                .frame(width: 64, height: 64)
                                
                                Text("Uploaded by:")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                Text(imageData.uploadedBy)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .onTapGesture {
#if os(iOS)
                                if let citationUrl = selectedBirdData?.citationUrl {
                                    UIApplication.shared.open(URL(string: citationUrl)!)
                                }
#endif
                            }
                            .onLongPressGesture(perform: {
                                selectedDetailTitle = sighting.sciName
                                selectedDetailSubtitle = sighting.comName
                                selectedBirdData = imageData
                                isPresented.toggle()
                            })
                        }
                    }.frame(maxWidth: .infinity, maxHeight: 64)
                        .padding(.bottom)
                }
            } else {
                Text(Fun.eBirdjis.randomElement() ?? "")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
            }
            if let commonName = sighting.comName {
                Text(commonName)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            if let name = sighting.sciName {
                Text(name)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            if let location = sighting.locName {
                Text("Location: " + location)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            if let date = sighting.obsDt {
                Text("Date: " + date)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            if let quantity = sighting.howMany {
                Text("Quantity: \(quantity)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            if let locationPrivate = sighting.locationPrivate {
                Text("In public location: \(locationPrivate == false)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            if let name = sighting.comName, let nameURLString = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string:"https://www.youtube.com/results?search_query=\(nameURLString)") {
                Link("📺 YouTube", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .padding([.top, .bottom], 4)
            }
            if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://media.ebird.org/catalog?taxonCode=\(speciesURLString)&mediaType=photo") {
                Link("🖼️ Photos", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .padding([.bottom], 4)
            }
            if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://media.ebird.org/catalog?taxonCode=\(speciesURLString)&mediaType=audio") {
                Link("🎼🔊 Recordings", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .padding([.bottom], 4)
            }
            //https://ebird.org/species/baleag
            if let speciesCode = sighting.speciesCode, let speciesURLString = speciesCode.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://ebird.org/species/\(speciesURLString)") {
                Link("Species Overview", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
            }
            //Audio files
            if let code = sighting.speciesCode {
                let relatedData = birdData.speciesMedia.filter({$0.speciesCode == code})
                if relatedData.count > 0 {
                    LazyHStack {
                        ForEach(relatedData.filter({$0.assetFormatCode == "audio"})) { key in
                            Button(action:{
                                if let url = URL(string: key.url) {
                                    self.player.set(url: url)
                                    self.player.play()
                                }
                            },label:{
                                VStack(alignment: .center, spacing: 2) {
                                    Image(systemName: "play")
                                        .frame(width: 64, height: 64)
                                        .clipShape(.rect(cornerRadius: 8))
                                        .buttonStyle(.borderedProminent)
                                    Text("Uploaded by:")
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                    Text(key.uploadedBy)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                }.onLongPressGesture {
                                    #if os(iOS)
                                    UIApplication.shared.open(URL(string: key.citationUrl)!)
                                    #endif
                                }
                            })
                        }
                    }.padding()
                }
            }
        }
        .sheet(item: $selectedBirdData, content: { data in
            if let selectedBirdData = selectedBirdData {
                FullScreenModalView(data: selectedBirdData)
            }
        })
        .onAppear {
            if let code = sighting.speciesCode, !birdData.speciesMedia.compactMap({$0.speciesCode}).contains(code) {
                birdData.requestWebsiteOf(speciesCode: code)
            }
        }
        .padding()
    }
}

struct FullScreenModalView: View {
    @Environment(\.dismiss) var dismiss
    @State var data: BirdSpeciesAssetMetadata
    var body: some View {
        VStack {
            if let sciName = data.sciName {
                Text(sciName)
                    .padding(.horizontal)
            }
            if let comName = data.comName {
                Text(comName)
                    .padding(.horizontal)
            }
            Text(data.generatedUrl).onTapGesture {
#if canImport(UniformTypeIdentifiers)
                #if os(iOS)
                UIPasteboard.general.setValue(data.generatedUrl,
                            forPasteboardType: UTType.plainText.identifier)
                #endif
                #endif
            }
            AsyncImage(url: URL(string: data.generatedUrl)){ image in
                image
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
            } placeholder: {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            dismiss()
        }
    }
}

/* audio asset example
 "asset": {
 "ageSex": {},
 "assetFormatCode": "audio",
 "assetId": 549106,
 "assetRestricted": true,
 "assetState": "committed",
 "assetTagCodes": ["call", "production"],
 "assetValid": true,
 "catalogDt": "2020-12-11T00:00:00",
 "catalogUserId": "USER16990",
 "citable": true,
 "citationName": "ML 92022701",
                 "citationUrl": "https://macaulaylibrary.org/audio/92022701",
                 "comName": "Bald Eagle",
                 "countryCode": "US",
                 "countryName": "United States",
                 "createDt": "2020-12-02T18:03:02.057",
                 "createQueued": 1,
                 "cutLength": 28536,
                 "digitizeDt": "2020-11-17T00:00:00",
                 "digitizeUserId": "USER16990",
                 "ebirdChecklistUrl": "https://ebird.org/ebird/view/checklist/S44087605",
                 "ebirdSpeciesUrl": "https://ebird.org/species/baleag",
                 "hasAgeSexData": false,
                 "lastEditedDt": "2024-06-15T22:53:59.216701",
                 "latitude": 28.2299949,
                 "licenseId": "LICENSE4",
                 "locId": "L857180",
                 "locName": "River Lakes Conservation Area--Moccasin Island",
                 "longitude": -80.8110523,
                 "mediaEditDt": "2020-11-17T00:00:00",
                 "mediaEditUserId": "USER16990",
                 "mediaFileName": "Bald Eagle Q4 C US-FL-009 ML92022701 Edit.wav",
                 "mediaFileSize": 1,
                 "mimeType": "audio/wav",
                 "mlBaseDownloadUrl": "https://cdn.download.ams.birds.cornell.edu/api/v1/asset/",
                 "obsDay": 30,
                 "obsDt": "2018-03-30",
                 "obsDtDisplay": "30 Mar 2018",
                 "obsMonth": 3,
                 "obsReviewed": false,
                 "obsValid": true,
                 "obsYear": 2018,
                 "parentAssetId": 92022701,
                 "parentAssetRestricted": false,
                 "projId": "ML",
                 "projectId": 1000043,
                 "quality": 3,
                 "ratingAverage": 3.0,
                 "ratingCount": 4,
                 "ratingRank": 2.5733333333333333,
                 "renditionTypes": ["audio", "poster", "spectrogram_small"],
                 "sciName": "Haliaeetus leucocephalus",
                 "source": "ml",
                 "speciesCode": "baleag",
                 "subId": "S44087605",
                 "subjects": [{
                     "speciesCode": "baleag",
                     "subjectTagCodes": ["call"]
                 }],
                 "subnational1Code": "US-FL",
                 "subnational1Name": "Florida",
                 "subnational2Code": "US-FL-009",
                 "subnational2Name": "Brevard",
                 "taxonCategoryCode": "species",
                 "taxonReportAs": "baleag",
                 "taxonomicSort": 8187.0,
                 "userDisplayName": "Paul Marvin",
                 "userId": "USER640979"
 }
 
 "asset": {
                 "ageSex": {
                     "juvenileUnknownCount": 1
                 },
                 "assetFormatCode": "photo",
                 "assetId": 306062831,
                 "assetRestricted": false,
                 "assetReviewed": false,
                 "assetState": "committed",
                 "assetTagCodes": ["flying_flight"],
                 "assetValid": true,
                 "citable": true,
                 "citationName": "ML 255379201",
                 "citationUrl": "https://macaulaylibrary.org/photo/255379201",
                 "comName": "Bald Eagle",
                 "countryCode": "US",
                 "countryName": "United States",
                 "createDt": "2020-08-13T20:38:53",
                 "createQueued": 1,
                 "ebirdChecklistUrl": "https://ebird.org/ebird/view/checklist/S72372921",
                 "ebirdSpeciesUrl": "https://ebird.org/species/baleag",
                 "groupId": "G5618064",
                 "hasAgeSexData": true,
                 "lastEditedDt": "2024-04-28T22:47:13.358345",
                 "latitude": 41.7642459,
                 "licenseId": "LICENSE4",
                 "locId": "L612903",
                 "locName": "Erie Marsh Preserve/Gun Club (no access Sep 1-Dec 15)",
                 "longitude": -83.4719821,
                 "mediaFileName": "127A3865.jpg",
                 "mediaFileSize": 257992,
                 "mimeType": "image/jpeg",
                 "mlBaseDownloadUrl": "https://cdn.download.ams.birds.cornell.edu/api/v1/asset/",
                 "obsDay": 13,
                 "obsDt": "2020-08-13T10:13",
                 "obsDtDisplay": "13 Aug 2020",
                 "obsId": "OBS967491788",
                 "obsMonth": 8,
                 "obsReviewed": false,
                 "obsTime": 1013,
                 "obsValid": true,
                 "obsYear": 2020,
                 "parentAssetId": 255379201,
                 "parentAssetRestricted": false,
                 "ratingAverage": 4.111111111111111,
                 "ratingCount": 27,
                 "ratingRank": 3.62269366222544,
                 "renditionTypes": ["160", "320", "480", "640", "900", "1200", "1800", "2400"],
                 "sciName": "Haliaeetus leucocephalus",
                 "source": "bna",
                 "speciesCode": "baleag",
                 "subId": "S72372921",
                 "subjects": [{
                     "speciesCode": "baleag",
                     "subjectTagCodes": ["flying_flight"]
                 }],
                 "subnational1Code": "US-MI",
                 "subnational1Name": "Michigan",
                 "subnational2Code": "US-MI-115",
                 "subnational2Name": "Monroe",
                 "taxonCategoryCode": "species",
                 "taxonReportAs": "baleag",
                 "taxonomicSort": 8187.0,
                 "updateUserId": "USER789364",
                 "userDisplayName": "Benjamin Hack",
                 "userId": "USER789364"
             },
             "caption": "Juveniles have a brown body with brown and white mottled wings. The tail is also mottled with a dark band at the tip.",
             "captionLocale": "en",
             "captionsMap": {
                 "en": {
                     "localeCode": "en",
                     "localeText": "Juveniles have a brown body with brown and white mottled wings. The tail is also mottled with a dark band at the tip."
                 }
             },
             "displayOrder": 2,
             "title": "Juvenile",
             "titleLocale": "en",
             "titlesMap": {
                 "af": {
                     "localeCode": "af",
                     "localeText": "Juvenile"
                 },
                 "da": {
                     "localeCode": "da",
                     "localeText": "Juvenil"
                 },
                 "de": {
                     "localeCode": "de",
                     "localeText": "juvenil"
                 },
                 "en": {
                     "localeCode": "en",
                     "localeText": "Juvenile"
                 },
                 "es": {
                     "localeCode": "es",
                     "localeText": "Juvenil"
                 },
                 "fr": {
                     "localeCode": "fr",
                     "localeText": "Juvénile"
                 },
                 "he": {
                     "localeCode": "he",
                     "localeText": "צעיר"
                 },
                 "id": {
                     "localeCode": "id",
                     "localeText": "Juvenil"
                 },
                 "ja": {
                     "localeCode": "ja",
                     "localeText": "幼鳥"
                 },
                 "ko": {
                     "localeCode": "ko",
                     "localeText": "어린새"
                 },
                 "ml": {
                     "localeCode": "ml",
                     "localeText": "Juvenile"
                 },
                 "mr": {
                     "localeCode": "mr",
                     "localeText": "Juvenile"
                 },
                 "pt": {
                     "localeCode": "pt",
                     "localeText": "Juvenil"
                 },
                 "ru": {
                     "localeCode": "ru",
                     "localeText": "Молодая птица"
                 },
                 "th": {
                     "localeCode": "th",
                     "localeText": "นกเด็ก"
                 },
                 "tr": {
                     "localeCode": "tr",
                     "localeText": "genç"
                 },
                 "uk": {
                     "localeCode": "uk",
                     "localeText": "Ювенільний птах"
                 },
                 "zh": {
                     "localeCode": "zh",
                     "localeText": "幼鳥"
                 },
                 "zu": {
                     "localeCode": "zu",
                     "localeText": "Esencane"
                 },
                 "zh_CN": {
                     "localeCode": "zh_CN",
                     "localeText": "幼鸟"
                 }
             }
         }, {
             "asset": {
                 "ageSex": {},
                 "assetFormatCode": "photo",
                 "assetId": 306063031,
                 "assetRestricted": false,
                 "assetReviewed": true,
                 "assetState": "committed",
                 "assetValid": true,
                 "citable": true,
                 "citationName": "ML 143694961",
                 "citationUrl": "https://macaulaylibrary.org/photo/143694961",
                 "comName": "Bald Eagle",
                 "countryCode": "US",
                 "countryName": "United States",
                 "createDt": "2019-03-04T09:58:21",
                 "createQueued": 1,
                 "ebirdChecklistUrl": "https://ebird.org/ebird/view/checklist/S52314531",
                 "ebirdSpeciesUrl": "https://ebird.org/species/baleag",
                 "groupId": "G3822514",
                 "hasAgeSexData": false,
                 "lastEditedDt": "2022-07-02T17:47:12.33178",
                 "latitude": 42.549821,
                 "licenseId": "LICENSE4",
                 "locId": "L8546048",
                 "locName": "199 River Rd, Deerfield US-MA (42.5498,-72.5621)",
                 "longitude": -72.562109,
                 "mediaFileName": "LY2A0856.jpg",
                 "mediaFileSize": 5185447,
                 "mimeType": "image/jpeg",
                 "mlBaseDownloadUrl": "https://cdn.download.ams.birds.cornell.edu/api/v1/asset/",
                 "obsComments": "*high. Careful single scan count. Possibly a 9th. All imm",
                 "obsDay": 2,
                 "obsDt": "2019-02-02T11:08",
                 "obsDtDisplay": "02 Feb 2019",
                 "obsId": "OBS705921647",
                 "obsMonth": 2,
                 "obsReviewed": true,
                 "obsTime": 1108,
                 "obsValid": true,
                 "obsYear": 2019,
                 "parentAssetId": 143694961,
                 "parentAssetRestricted": false,
                 "ratingAverage": 4.793103448275862,
                 "ratingCount": 29,
                 "ratingRank": 4.293360545786059,
                 "renditionTypes": ["160", "320", "480", "640", "900", "1200", "1800", "2400"],
                 "sciName": "Haliaeetus leucocephalus",
                 "source": "bna",
                 "speciesCode": "baleag",
                 "subId": "S52314531",
                 "subjects": [{
                     "speciesCode": "baleag"
                 }],
                 "subnational1Code": "US-MA",
                 "subnational1Name": "Massachusetts",
                 "subnational2Code": "US-MA-011",
                 "subnational2Name": "Franklin",
                 "taxonCategoryCode": "species",
                 "taxonReportAs": "baleag",
                 "taxonomicSort": 8187.0,
                 "updateUserId": "USER1056900",
                 "userDisplayName": "Jonathan Eckerson",
                 "userId": "USER532483"
             }
 */
