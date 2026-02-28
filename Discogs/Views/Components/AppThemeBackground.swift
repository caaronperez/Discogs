//
//  AppThemeBackground.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

enum AppThemeBackground {
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.08, blue: 0.10),
            Color(red: 0.13, green: 0.07, blue: 0.16),
            Color(red: 0.03, green: 0.05, blue: 0.09)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppThemeBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AppThemeBackground.gradient
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func appThemeBackground() -> some View {
        modifier(AppThemeBackgroundModifier())
    }
}
