//
//  WhereNowApp.swift
//  WhereNow Watch App
//
//  Created by Jon on 7/17/24.
//

import SwiftUI

@main
struct WhereNow_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            WhereNowView()
                .environmentObject(LocationDataModel())
        }
    }
}
