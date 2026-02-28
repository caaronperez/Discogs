//
//  SearchView.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: SearchViewModel
    @StateObject private var toastManager: ToastManager

    @AppStorage(APIConfig.tokenUserDefaultsKey) private var personalToken = ""
    @State private var isTokenSettingsPresented = false
    @State private var hasUserAuthentication = SearchView.hasAnyAuthentication(personalToken: "")

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: SearchViewModel())
        _toastManager = StateObject(wrappedValue: ToastManager())
    }

    @MainActor
    init(
        viewModel: SearchViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _toastManager = StateObject(wrappedValue: ToastManager())
    }

    @MainActor
    init(
        viewModel: SearchViewModel,
        toastManager: ToastManager
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _toastManager = StateObject(wrappedValue: toastManager)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isShowingEmptyState {
                    emptyState
                } else {
                    resultsList
                }
            }
            .navigationTitle(viewModel.ui.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: Binding(
                    get: { viewModel.query },
                    set: { viewModel.onQueryChanged($0) }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: viewModel.ui.searchPrompt
            )
            .appSearchBarStyle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isTokenSettingsPresented = true
                    } label: {
                        Image(systemName: hasUserAuthentication ? viewModel.ui.authConnectedSystemImage : viewModel.ui.authDisconnectedSystemImage)
                    }
                }
            }
            .sheet(isPresented: $isTokenSettingsPresented, onDismiss: refreshAuthState) {
                TokenSettingsView()
            }
            .task {
                refreshAuthState()
                await viewModel.bootstrap()
            }
            .onChange(of: personalToken) { _, _ in
                refreshAuthState()
            }
            .onAppear {
                if !hasUserAuthentication {
                    toastManager.show(
                        title: viewModel.ui.authOptionalToastTitle,
                        message: viewModel.ui.authOptionalToastMessage,
                        style: .info
                    )
                }
            }
            .onChange(of: viewModel.message) { _, newMessage in
                guard let newMessage else { return }
                let style = viewModel.toastStyle(for: newMessage)
                toastManager.show(title: viewModel.ui.resultToastTitle, message: newMessage, style: style)
            }
        }
        .appThemeBackground()
        .toastOverlay(using: toastManager)
    }

    private func refreshAuthState() {
        hasUserAuthentication = SearchView.hasAnyAuthentication(personalToken: personalToken)
    }

    private static func hasAnyAuthentication(personalToken: String) -> Bool {
        let hasPersonal = !personalToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return DiscogsOAuthManager.shared.isAuthenticated || hasPersonal
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.ui.emptyHeaderTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(AppThemeText.primary(for: colorScheme))
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.ui.emptyHeaderSubtitle)
                .font(.subheadline)
                .foregroundStyle(AppThemeText.secondary(for: colorScheme))
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .zIndex(20)
        .padding(.horizontal)
        .padding(.top, 56)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            header
                .zIndex(20)

            ZStack(alignment: .bottom) {
                ImageMarqueeView(
                    imageURLs: viewModel.featuredImageURLs,
                    rowCount: 8,
                    bottomFadeHeight: 50
                )
                .padding(.top, -56)
                .opacity(0.58)
                .frame(maxWidth: .infinity)
                .frame(height: 500)
                .ignoresSafeArea(edges: .bottom)

                Text(viewModel.ui.emptyPrompt)
                    .font(.headline)
                    .foregroundStyle(AppThemeText.primary(for: colorScheme))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom)
            }
            .frame(maxWidth: .infinity)

            if !hasUserAuthentication {
                Button(viewModel.ui.connectButtonTitle) {
                    isTokenSettingsPresented = true
                }
                .padding(.bottom, 32)
                .glassToolbarStyle()
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var resultsList: some View {
        List {
            ForEach(viewModel.artists) { artist in
                NavigationLink(value: artist) {
                    ArtistRowView(artist: artist, ui: viewModel.ui)
                }
                .listRowBackground(Color.clear)
                .task {
                    await viewModel.loadMoreIfNeeded(currentItem: artist)
                }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: ArtistSearchResult.self) { artist in
            ArtistDetailView(artistID: artist.id, artistName: artist.displayName)
        }
    }
}

private struct ArtistRowView: View {
    let artist: ArtistSearchResult
    let ui: SearchViewModel.UI

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(urlString: artist.thumb) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
                    .overlay {
                        Image(systemName: ui.rowPlaceholderSystemImage)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.displayName)
                    .font(.headline)
                Text((artist.type ?? ui.fallbackArtistType).capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchView()
}

#Preview("Search Results") {
    SearchResultsPreview()
}

private struct SearchResultsPreview: View {
    @StateObject private var viewModel = SearchViewModel(
        api: MockDiscogsAPI(
            searchResponsesByPage: [1: .previewResults],
            defaultSearchResponse: .previewResults
        )
    )

    var body: some View {
        SearchView(viewModel: viewModel)
            .task {
                viewModel.onQueryChanged("pop")
                await viewModel.submitSearch()
            }
    }
}
