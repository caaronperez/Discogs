//
//  ArtistDetailView.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

struct ArtistDetailView: View {
    private struct HeroImageItem: Hashable {
        let url: String
    }

    @StateObject private var viewModel: ArtistDetailViewModel
    @StateObject private var toastManager = ToastManager()
    @State private var selectedImageIndex = 0

    private let artistName: String

    init(artistID: Int, artistName: String) {
        _viewModel = StateObject(wrappedValue: ArtistDetailViewModel(artistID: artistID))
        self.artistName = artistName
    }

    init(viewModel: ArtistDetailViewModel, artistName: String) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.artistName = artistName
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 120)
            } else if let artist = viewModel.artist {
                VStack(alignment: .leading, spacing: 20) {
                    heroImage(artist: artist)

                    Text(artist.name)
                        .font(.title.bold())

                    if let profile = artist.profile, !profile.isEmpty {
                        Text(profile)
                            .font(.body)
                    }

                    if !viewModel.sortedMembers.isEmpty {
                        membersSection
                    }

                    NavigationLink {
                        ReleasesListView(artistID: artist.id, artistName: artist.name)
                    } label: {
                        Label(viewModel.ui.releasesButtonTitle, systemImage: viewModel.ui.releasesButtonSystemImage)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                ContentUnavailableView(viewModel.ui.emptyDetailsTitle, systemImage: viewModel.ui.emptyDetailsSystemImage)
                    .padding(.top, 80)
            }
        }
        .appThemeBackground()
        .navigationTitle(artistName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.artist?.id) { _, _ in
            selectedImageIndex = 0
        }
        .onChange(of: viewModel.message) { _, message in
            guard let message else { return }
            toastManager.show(title: viewModel.ui.toastTitle, message: message, style: .error)
        }
        .toastOverlay(using: toastManager)
    }

    private func heroImage(artist: ArtistDetail) -> some View {
        let items = heroImageItems(from: artist)

        return Group {
            if items.isEmpty {
                CachedAsyncImage(urlString: nil) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.secondary.opacity(0.15))
                        .overlay {
                            Image(systemName: viewModel.ui.heroPlaceholderSystemImage)
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
            } else {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        CachedAsyncImage(urlString: item.url, contentMode: .fill) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.secondary.opacity(0.15))
                                .overlay {
                                    Image(systemName: viewModel.ui.heroPlaceholderSystemImage)
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func heroImageItems(from artist: ArtistDetail) -> [HeroImageItem] {
        var seen = Set<String>()

        return (artist.images ?? [])
            .compactMap { image in
                let url = (image.uri?.isEmpty == false ? image.uri : image.uri150) ?? ""
                guard !url.isEmpty else { return nil }
                return HeroImageItem(url: url)
            }
            .filter { seen.insert($0.url).inserted }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.ui.membersSectionTitle)
                .font(.headline)

            Picker(viewModel.ui.membersSortTitle, selection: $viewModel.memberSort) {
                ForEach(ArtistDetailViewModel.MemberSort.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            ForEach(viewModel.sortedMembers) { member in
                HStack {
                    Text(member.name)
                    Spacer()
                    if member.active == true {
                        Text(viewModel.ui.activeMemberLabel)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArtistDetailView(
            viewModel: ArtistDetailViewModel(
                artistID: 100,
                api: MockDiscogsAPI(artistDetailResponse: .previewArtist)
            ),
            artistName: "Preview Artist"
        )
    }
}
