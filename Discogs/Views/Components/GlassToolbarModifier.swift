//
//  GlassToolbarModifier.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

// Applies a Liquid Glass-inspired style to toolbar button groups.
struct GlassToolbarModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.bordered)
        }
    }
}

extension View {
    func glassToolbarStyle() -> some View {
        modifier(GlassToolbarModifier())
    }
}
