//
//  SearchViewModel.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    struct UI {
        let navigationTitle = "Search"
        let searchPrompt = "Artist name"
        let clearQuerySystemImage = "xmark.circle"
        let authConnectedSystemImage = "person.crop.circle.badge.checkmark"
        let authDisconnectedSystemImage = "person.crop.circle"
        let authOptionalToastTitle = "Authentication Optional"
        let authOptionalToastMessage = "You can browse with embedded app credentials. Add OAuth or personal token only if you want your own session."
        let resultToastTitle = "Discogs"
        let emptyHeaderTitle = "Find the artists behind the records"
        let emptyHeaderSubtitle = "Search Discogs and explore profiles and more."
        let emptyPrompt = "Search for an artist to begin"
        let connectButtonTitle = "Connect Discogs"
        let rowPlaceholderSystemImage = "music.mic"
        let fallbackArtistType = "artist"
    }

    let ui = UI()

    @Published var query: String = ""
    @Published private(set) var artists: [ArtistSearchResult] = []
    @Published private(set) var featuredImageURLs: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isBootstrapping = false
    @Published var message: String?

    private let api: DiscogsAPIProtocol
    private var currentPage = 1
    private var totalPages = 1
    private var searchTask: Task<Void, Never>?

    init(api: DiscogsAPIProtocol? = nil) {
        self.api = api ?? DiscogsAPI()
    }

    var isShowingEmptyState: Bool {
        artists.isEmpty && query.isEmpty
    }

    func toastStyle(for message: String) -> ToastStyle {
        message.hasPrefix("No") ? .info : .error
    }

    // Loads the image strip content displayed in the empty search state.
    func bootstrap() async {
        guard featuredImageURLs.isEmpty else { return }

        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            let suggestions = [
                // These are my favorite artists, not a specific selection
                "Dua Lipa",
                "Danna Paola",
                "Demi Lovato",
                "Britney Spears",
                "Hannah Montana",
                "Lady Gaga",
                "Shakira",
                "Belanova",
                "Charli XCX",
                "Kylie Minogue",
                "Bad Bunny",
                "Taylor Swift",
                "Olivia Rodrigo",
                "Sabrina Carpenter",
                "Carly Rae Jepsen",
                "Doja Cat",
                "Ariana Grande",
                "Shawn Mendes",
                "Harry Styles",
                "Blackpink",
                "Depeche Mode",
                "Justin Bieber"
            ]
            var thumbnails: [String] = []

            for suggestion in suggestions {
                let response = try await api.searchArtists(query: suggestion, page: 1)
                let artistThumbnails = response.results
                    .compactMap(\.thumb)
                    .filter { !$0.isEmpty }
                thumbnails.append(contentsOf: artistThumbnails.prefix(1))
            }

            featuredImageURLs = orderedUnique(thumbnails)
        } catch {
            // Empty-state images are non-blocking.
        }
    }

    private func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for value in values where seen.insert(value).inserted {
            result.append(value)
        }

        return result
    }

    func onQueryChanged(_ value: String) {
        query = value
        searchTask?.cancel()

        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            artists = []
            currentPage = 1
            totalPages = 1
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await search(reset: true)
        }
    }

    func submitSearch() async {
        searchTask?.cancel()
        await search(reset: true)
    }

    func loadMoreIfNeeded(currentItem: ArtistSearchResult) async {
        guard currentPage < totalPages else { return }

        let thresholdIndex = artists.index(artists.endIndex, offsetBy: -5, limitedBy: artists.startIndex) ?? artists.startIndex
        guard artists.firstIndex(of: currentItem).map({ $0 >= thresholdIndex }) == true else { return }

        await search(reset: false)
    }

    private func search(reset: Bool) async {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return }
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let page = reset ? 1 : currentPage + 1
            let response = try await api.searchArtists(query: normalizedQuery, page: page)

            if reset {
                artists = response.results
            } else {
                artists.append(contentsOf: response.results)
            }

            currentPage = response.pagination.page
            totalPages = response.pagination.pages

            if artists.isEmpty {
                message = "No artists found for \"\(normalizedQuery)\"."
            }
        } catch let error as APIError {
            message = error.errorDescription
        } catch {
            message = "Unexpected error while searching artists."
        }
    }
}
