//
//  WhereNowPortraitLocationView.swift
//  WhereNow
//
//  Created by Jon on 11/27/24.
//
import SwiftUI

struct WhereNowPortraitLocationView: View {
#if os(watchOS)
    let reversePadding = true
#else
    let reversePadding = false
#endif
    static var countTime:Double = 0.1
    @EnvironmentObject var locationData: LocationDataModel
    
    var body: some View {
        ScrollView() {
            VStack {
                Text(self.locationData.addresses.compactMap({$0.formattedCommonVeryLongFlag()}).joined(separator: "\n\n"))
                    .multilineTextAlignment(.center)
#if os(watchOS)
#else
                if let image = self.locationData.image {
                    MapSnapshotView(image: image)
                }
#endif
            }
        }
    }
}
