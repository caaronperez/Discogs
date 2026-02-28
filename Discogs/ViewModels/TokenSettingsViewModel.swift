//
//  TokenSettingsViewModel.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Combine
import Foundation

@MainActor
final class TokenSettingsViewModel: ObservableObject {
    struct UI {
        let authenticationSectionTitle = "Authentication"
        let oauthTitle = "OAuth"
        let oauthConnectedValue = "Connected"
        let oauthNotConnectedValue = "Not connected"
        let personalTokenTitle = "Personal Token"
        let tokenNotSetValue = "Not set"
        let tokenConfiguredValue = "Configured"

        let oauthSectionTitle = "OAuth (Discogs App)"
        let connectDiscogsButtonTitle = "Connect with Discogs"
        let connectDiscogsSystemImage = "link"
        let verifierHelpText = "After approving access in Safari, copy the verifier code shown by Discogs and paste it below."
        let verifierPlaceholder = "Verifier code"
        let finishSignInButtonTitle = "Finish Sign In"
        let disconnectOAuthButtonTitle = "Disconnect OAuth"

        let personalTokenSectionTitle = "Personal Token (Optional)"
        let personalTokenPlaceholder = "Discogs personal token"
        let saveTokenButtonTitle = "Save Token"
        let clearTokenButtonTitle = "Clear Token"
        let personalTokenHelpText = "If OAuth is connected, OAuth credentials are used first. Personal token is used as a fallback."

        let navigationTitle = "Discogs Account"
        let doneButtonTitle = "Done"

        let disconnectedOAuthMessage = "Disconnected OAuth session."
        let emptyTokenMessage = "Token cannot be empty. Use Clear Token to remove it."
        let persistTokenFailureMessage = "Could not persist token. Please try again."
        let personalTokenSavedMessage = "Personal token saved."
        let personalTokenClearedMessage = "Personal token cleared."
        let authorizationOpenedMessage = "Authorization opened in Safari."
        let startAuthorizationFailureMessage = "Failed to start authentication."
        let completedAuthorizationMessage = "Discogs authentication completed."
        let completeAuthorizationFailureMessage = "Failed to complete authentication."
    }

    let ui = UI()

    func oauthStatusText(isAuthenticated: Bool) -> String {
        isAuthenticated ? ui.oauthConnectedValue : ui.oauthNotConnectedValue
    }

    func personalTokenStatusText(personalToken: String) -> String {
        personalToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ui.tokenNotSetValue : ui.tokenConfiguredValue
    }

    func isPositiveStatus(_ value: String) -> Bool {
        value == ui.oauthConnectedValue || value == ui.tokenConfiguredValue
    }
}
