//
//  ContentView.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingLaunchSplash = true

    var body: some View {
        ZStack {
            SearchView()
                .opacity(isShowingLaunchSplash ? 0 : 1)

            if isShowingLaunchSplash {
                LaunchSplashView {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isShowingLaunchSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
