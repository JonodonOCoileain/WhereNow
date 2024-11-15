//
//  LocationViewTab.swift
//  WhereNow
//
//  Created by Jon on 11/15/24.
//

import SwiftUI

struct LocationViewTab: View {
    @ObservedObject var locationData: LocationDataModel
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
            }
        }
    }
}
