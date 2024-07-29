//
//  WhereNowApp.swift
//  WhereNow
//
//  Created by Jon on 7/17/24.
//

import SwiftUI

@main
struct WhereNowApp: App {
    var body: some Scene {
        WindowGroup {
            WhereNowView()
                .environmentObject(LocationDataModel())
                .preferredColorScheme(.dark)
        }
    }
}
