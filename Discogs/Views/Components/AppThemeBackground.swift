//
//  AppThemeBackground.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return nil
        }
    }
}

enum AppThemeBackground {
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.02, blue: 0.03),
            Color(red: 0.01, green: 0.01, blue: 0.02),
            Color(red: 0.00, green: 0.00, blue: 0.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassReflection = LinearGradient(
        colors: [
            Color.white.opacity(0.16),
            Color.white.opacity(0.05),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .center
    )

    static let glassGlow = RadialGradient(
        colors: [
            Color.white.opacity(0.12),
            Color.clear
        ],
        center: .topTrailing,
        startRadius: 40,
        endRadius: 340
    )
}

enum AppThemeText {
    static func primary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? .black : .white
    }

    static func secondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? Color.black.opacity(0.7) : Color.white.opacity(0.8)
    }
}

struct AppThemeBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        ZStack {
            background
                .ignoresSafeArea()
            content
        }
    }

    @ViewBuilder
    private var background: some View {
        if colorScheme == .light {
            Color.gray.opacity(0.1)
        } else {
            ZStack {
                AppThemeBackground.gradient
                AppThemeBackground.glassGlow
                    .blendMode(.screen)
                AppThemeBackground.glassReflection
                    .blendMode(.screen)
            }
        }
    }
}

extension View {
    func appThemeBackground() -> some View {
        modifier(AppThemeBackgroundModifier())
    }
}
