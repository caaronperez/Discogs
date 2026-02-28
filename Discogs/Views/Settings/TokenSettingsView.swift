//
//  TokenSettingsView.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

struct TokenSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel = TokenSettingsViewModel()
    @AppStorage(APIConfig.tokenUserDefaultsKey) private var personalToken = ""

    @State private var personalTokenInput = ""
    @State private var verifierCode = ""
    @State private var isWorking = false
    @State private var statusMessage = ""
    @State private var hasPendingAuthorization = false
    @State private var isOAuthAuthenticated = DiscogsOAuthManager.shared.isAuthenticated
    @FocusState private var isTokenFieldFocused: Bool

    private let authManager = DiscogsOAuthManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.ui.authenticationSectionTitle) {
                    authRow(title: viewModel.ui.oauthTitle, value: viewModel.oauthStatusText(isAuthenticated: isOAuthAuthenticated))
                    authRow(
                        title: viewModel.ui.personalTokenTitle,
                        value: viewModel.personalTokenStatusText(personalToken: personalToken)
                    )

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(viewModel.ui.oauthSectionTitle) {
                    if !isOAuthAuthenticated {
                        Button {
                            Task { await startAuthorization() }
                        } label: {
                            Label(viewModel.ui.connectDiscogsButtonTitle, systemImage: viewModel.ui.connectDiscogsSystemImage)
                        }
                        .disabled(isWorking)

                        if hasPendingAuthorization {
                            Text(viewModel.ui.verifierHelpText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            TextField(viewModel.ui.verifierPlaceholder, text: $verifierCode)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            Button(viewModel.ui.finishSignInButtonTitle) {
                                Task { await completeAuthorization() }
                            }
                            .disabled(isWorking || verifierCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button(role: .destructive) {
                            authManager.signOut()
                            isOAuthAuthenticated = false
                            hasPendingAuthorization = false
                            verifierCode = ""
                            statusMessage = viewModel.ui.disconnectedOAuthMessage
                        } label: {
                            Text(viewModel.ui.disconnectOAuthButtonTitle)
                        }
                    }
                }

                Section(viewModel.ui.personalTokenSectionTitle) {
                    SecureField(viewModel.ui.personalTokenPlaceholder, text: $personalTokenInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isTokenFieldFocused)

                    Button(viewModel.ui.saveTokenButtonTitle) {
                        savePersonalToken()
                    }
                    .disabled(isWorking)

                    Button(viewModel.ui.clearTokenButtonTitle, role: .destructive) {
                        clearPersonalToken()
                    }
                    .disabled(isWorking)

                    Text(viewModel.ui.personalTokenHelpText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text(viewModel.ui.creditsFooterText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .scrollContentBackground(.hidden)
            .appThemeBackground()
            .navigationTitle(viewModel.ui.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.ui.doneButtonTitle) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                personalTokenInput = personalToken
                isOAuthAuthenticated = authManager.isAuthenticated
            }
        }
    }

    private func authRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(viewModel.isPositiveStatus(value) ? .green : .secondary)
        }
    }

    private func savePersonalToken() {
        let normalized = personalTokenInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            statusMessage = viewModel.ui.emptyTokenMessage
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(normalized, forKey: APIConfig.tokenUserDefaultsKey)

        let persistedToken = defaults.string(forKey: APIConfig.tokenUserDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard persistedToken == normalized else {
            statusMessage = viewModel.ui.persistTokenFailureMessage
            return
        }

        personalToken = persistedToken
        personalTokenInput = persistedToken
        isTokenFieldFocused = false
        statusMessage = viewModel.ui.personalTokenSavedMessage
    }

    private func clearPersonalToken() {
        UserDefaults.standard.removeObject(forKey: APIConfig.tokenUserDefaultsKey)
        personalToken = ""
        personalTokenInput = ""
        isTokenFieldFocused = false
        statusMessage = viewModel.ui.personalTokenClearedMessage
    }

    private func startAuthorization() async {
        isWorking = true
        defer { isWorking = false }

        do {
            let authorizeURL = try await authManager.beginAuthorization()
            hasPendingAuthorization = true
            statusMessage = viewModel.ui.authorizationOpenedMessage
            openURL(authorizeURL)
        } catch let error as APIError {
            statusMessage = error.errorDescription ?? viewModel.ui.startAuthorizationFailureMessage
        } catch {
            statusMessage = viewModel.ui.startAuthorizationFailureMessage
        }
    }

    private func completeAuthorization() async {
        isWorking = true
        defer { isWorking = false }

        do {
            try await authManager.completeAuthorization(verifier: verifierCode)
            isOAuthAuthenticated = true
            hasPendingAuthorization = false
            statusMessage = viewModel.ui.completedAuthorizationMessage
        } catch let error as APIError {
            statusMessage = error.errorDescription ?? viewModel.ui.completeAuthorizationFailureMessage
        } catch {
            statusMessage = viewModel.ui.completeAuthorizationFailureMessage
        }
    }
}

#Preview {
    TokenSettingsView()
}
