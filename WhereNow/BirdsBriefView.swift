//
//  BirdsBriefView.swift
//  WhereNow
//
//  Created by Jon on 8/8/24.
//

import SwiftUI
import WidgetKit

#if canImport(SafariServices)
import SafariServices
#if canImport(UIKit)
import UIKit
#endif
#endif
import AVFoundation

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
                        Spacer()
                    }.frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: CGFloat(birdData.sightings.count) * descriptionSize < geometry.size.height - titleSize ? CGFloat(birdData.sightings.count) * descriptionSize + titleSize : geometry.size.height, maxHeight: geometry.size.height)
                    
                    ScrollView {
                        BirdSightingsView(birdData: birdData)
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

struct BirdSightingsView: View {
    @ObservedObject var audioPlayerViewModel: AudioPlayerViewModel = AudioPlayerViewModel()
    
    let birdData: BirdSightingService
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    @State private var isFullScreen = false
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment:.leading, spacing: 9) {
                    ForEach(birdData.sightings, id: \.self) { sighting in
                        LazyHStack(alignment:.top) {
                            BirdSightingDescriptionView(sighting: sighting)
                            .frame(width: geometry.size.width*3/4, height: 130)
                            /*.onAppear(perform: {
                                if let name = sighting.comName {
                                    //birdData.getBirdAudioSource(of: name)
                                }
                            })*/
                            Spacer()
                            /*Button(action: {
                                if let name = sighting.comName, let remoteFile = birdData.birdSoundURL[name], let localFilename = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                                    self.birdData.downloadFileCompletionHandler(urlstring: remoteFile, named: localFilename) { url, error in
                                        if let error = error {
                                            print(error)
                                        } else {
                                            let documentsUrl =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                                            let destinationUrl = documentsUrl.appendingPathComponent(localFilename)
                                            self.audioPlayerViewModel.useFile(url: destinationUrl)
                                            self.audioPlayerViewModel.playOrPause()
                                        }
                                    }
                                }
                            },label: {
                                    Image(systemName: audioPlayerViewModel.isPlaying ? "pause.circle" : "play.circle")
                                      .resizable()
                                      .frame(width: 32, height: 32)
                                  })
                            .frame(width: geometry.size.width/4, height: 150)*/
                        }.frame(width: geometry.size.width, height: 130)
                    }
                }.frame(width: geometry.size.width)
            }.frame(width: geometry.size.width)
        }
    }
}

struct BirdSightingDescriptionView: View {
    let sighting: BirdSighting
    let titleSize: CGFloat = 11
    let descriptionSize: CGFloat = 12
    var body: some View {
        LazyVStack(alignment:.leading, spacing: 0) {
            Text(Fun.eBirdjis.randomElement() ?? "")
                .font(.system(size: descriptionSize))
                .multilineTextAlignment(.leading)
            if let commonName = sighting.comName {
                Text(commonName)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let commonName = sighting.comName {
                Text(commonName)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let name = sighting.sciName {
                Text(name)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let quantity = sighting.howMany {
                Text("Quantity: \(quantity)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let date = sighting.obsDt {
                Text("Date: " + date)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let location = sighting.locName {
                Text("Location: " + location)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let locationPrivate = sighting.locationPrivate {
                Text("In public location: \(locationPrivate == false)")
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            if let name = sighting.comName, let nameURLString = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string:"https://www.youtube.com/results?search_query=\(nameURLString)") {
                Link("Tap to search on YouTube", destination: url)
                    .font(.system(size: descriptionSize))
                    .multilineTextAlignment(.leading)
             }
        }
    }
}

class AudioPlayerViewModel: ObservableObject {
    var audioPlayer: AVPlayer?
    
    @Published var isPlaying = false
    
    init() {
        if let sound = Bundle.main.path(forResource: "PocketCyclopsLvl1", ofType: "mp3") {
            self.audioPlayer = AVPlayer(url: URL(fileURLWithPath: sound))
        } else {
            print("Audio file could not be found.")
        }
    }
    func useRemoteFile(string: String) {
        if let url = URL(string: string) {
            self.audioPlayer = AVPlayer(url: url)
        }
    }
    
    func useFile(url: URL) {
        self.audioPlayer = AVPlayer(url: url)
    }
    
    func playOrPause() {
        guard let player = audioPlayer else { return }
        
        if player.rate != 0 {
            player.pause()
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = false
            }
        } else {
            player.play()
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = true
            }
        }
    }
}

