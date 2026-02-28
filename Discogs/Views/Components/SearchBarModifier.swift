//
//  SearchBarModifier.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI
import UIKit

// Configures modern search toolbar behavior.
struct SearchBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .searchToolbarBehavior(.automatic)
                .onAppear(perform: applySearchFieldAppearance)
                .onChange(of: colorScheme) { _, _ in
                    applySearchFieldAppearance()
                }
        } else {
            content
                .onAppear(perform: applySearchFieldAppearance)
                .onChange(of: colorScheme) { _, _ in
                    applySearchFieldAppearance()
                }
        }
    }

    private func applySearchFieldAppearance() {
        let textField = UISearchBar.appearance().searchTextField

        if colorScheme == .light {
            textField.backgroundColor = UIColor.systemGray6
            textField.textColor = UIColor.label
            textField.layer.cornerRadius = 12
            textField.layer.borderWidth = 1
            textField.layer.borderColor = UIColor.systemGray4.cgColor
            textField.clipsToBounds = true
        } else {
            textField.backgroundColor = UIColor.secondarySystemBackground
            textField.textColor = UIColor.label
            textField.layer.borderWidth = 0
            textField.layer.borderColor = UIColor.clear.cgColor
            textField.clipsToBounds = true
        }
    }
}

extension View {
    func appSearchBarStyle() -> some View {
        modifier(SearchBarModifier())
    }
}
