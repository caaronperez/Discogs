//
//  SearchBarModifier.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

// Configures modern search toolbar behavior.
struct SearchBarModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .searchToolbarBehavior(.automatic)
        } else {
            content
        }
    }
}

extension View {
    func appSearchBarStyle() -> some View {
        modifier(SearchBarModifier())
    }
}
