//
//  ReleasesListView.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

struct ReleasesListView: View {
    @StateObject private var viewModel: ReleasesViewModel
    @StateObject private var toastManager = ToastManager()

    @State private var isFilterSheetPresented = false
    @FocusState private var isBottomSearchFocused: Bool
    private let artistName: String

    init(artistID: Int, artistName: String) {
        _viewModel = StateObject(wrappedValue: ReleasesViewModel(artistID: artistID))
        self.artistName = artistName
    }

    init(viewModel: ReleasesViewModel, artistName: String) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.artistName = artistName
    }

    var body: some View {
        List {
            ForEach(viewModel.filteredAndSortedReleases) { release in
                ReleaseRow(release: release, viewModel: viewModel)
                    .listRowBackground(Color.clear)
                    .task {
                        await viewModel.loadNextPageIfNeeded(currentItem: release)
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
        .appThemeBackground()
        .navigationTitle(viewModel.navigationTitle(for: artistName))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isFilterSheetPresented = true
                } label: {
                    Label(viewModel.ui.filtersButtonTitle, systemImage: viewModel.ui.filtersButtonSystemImage)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            floatingSearchBar
        }
        .sheet(isPresented: $isFilterSheetPresented) {
            ReleaseFilterSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadInitial()
        }
        .onChange(of: viewModel.message) { _, message in
            guard let message else { return }
            let style = viewModel.toastStyle(for: message)
            toastManager.show(title: viewModel.ui.releasesToastTitle, message: message, style: style)
        }
        .toastOverlay(using: toastManager)
    }

    private var floatingSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.ui.releaseSearchButtonSystemImage)
                .foregroundStyle(.secondary)

            TextField(viewModel.ui.releaseSearchPlaceholder, text: $viewModel.releaseSearchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isBottomSearchFocused)

            if !viewModel.releaseSearchText.isEmpty {
                Button {
                    viewModel.clearBottomSearch()
                } label: {
                    Image(systemName: viewModel.ui.releaseSearchCloseSystemImage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct ReleaseRow: View {
    let release: ArtistRelease
    let viewModel: ReleasesViewModel

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(urlString: release.thumb) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
                    .overlay {
                        Image(systemName: viewModel.ui.rowPlaceholderSystemImage)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(release.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(viewModel.yearText(for: release))
                    Text(viewModel.ui.rowMetaSeparator)
                    Text(release.primaryLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let genres = viewModel.genresText(for: release) {
                    Text(genres)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ReleasesListPreview()
    }
}

private struct ReleasesListPreview: View {
    @StateObject private var viewModel = ReleasesViewModel(
        artistID: 100,
        api: MockDiscogsAPI(releasesResponsesByPage: [1: .previewReleases], defaultReleasesResponse: .previewReleases)
    )

    var body: some View {
        ReleasesListView(viewModel: viewModel, artistName: "Preview Artist")
    }
}
