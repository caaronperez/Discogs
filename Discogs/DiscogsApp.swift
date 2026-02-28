//
//  DiscogsApp.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

@main
struct DiscogsApp: App {
    @AppStorage(APIConfig.appearanceUserDefaultsKey) private var appearanceModeRawValue = AppAppearanceMode.dark.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(selectedAppearanceMode.colorScheme)
        }
    }

    private var selectedAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .dark
    }
}
