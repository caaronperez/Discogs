//
//  ReleasesViewModel.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Combine
import Foundation

struct ReleaseFilters: Equatable {
    var year: Int?
    var genre: String?
    var label: String?
}

@MainActor
final class ReleasesViewModel: ObservableObject {
    struct UI {
        let filtersButtonTitle = "Filters"
        let filtersButtonSystemImage = "line.3.horizontal.decrease.circle"
        let releasesToastTitle = "Releases"
        let rowPlaceholderSystemImage = "record.circle"
        let unknownYearText = "Unknown year"
        let rowMetaSeparator = "•"
        let releaseSearchButtonTitle = "Search"
        let releaseSearchButtonSystemImage = "magnifyingglass"
        let releaseSearchPlaceholder = "Filter by title, year, or format"
        let releaseSearchCloseSystemImage = "xmark.circle.fill"
        let filterSortSectionTitle = "Sort"
        let filterSortByTitle = "Sort By"
        let filterOrderTitle = "Order"
        let filterYearSectionTitle = "Year"
        let filterYearPickerTitle = "Year"
        let filterGenreSectionTitle = "Genre"
        let filterGenrePickerTitle = "Genre"
        let filterLabelSectionTitle = "Label"
        let filterLabelPickerTitle = "Label"
        let filterAllOptionTitle = "All"
        let filterSheetTitle = "Filters"
        let filterResetButtonTitle = "Reset"
        let filterDoneButtonTitle = "Done"
    }

    let ui = UI()

    @Published private(set) var releases: [ArtistRelease] = []
    @Published var releaseSearchText = ""
    @Published var isBottomSearchExpanded = false
    @Published private(set) var isLoading = false
    @Published var filters = ReleaseFilters()
    @Published var selectedSort: ArtistReleaseSort = .year
    @Published var selectedSortOrder: ArtistReleaseSortOrder = .descending
    @Published var message: String?

    private let artistID: Int
    private let api: DiscogsAPIProtocol
    private var currentPage = 0
    private var totalPages = 1

    init(artistID: Int, api: DiscogsAPIProtocol? = nil) {
        self.artistID = artistID
        self.api = api ?? DiscogsAPI()
    }

    var filteredAndSortedReleases: [ArtistRelease] {
        let normalizedQuery = releaseSearchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return releases.filter { release in
            let matchesYear = filters.year == nil || release.year == filters.year
            let matchesGenre = filters.genre == nil || release.genreValues.contains(filters.genre ?? "")
            let matchesLabel = filters.label == nil || release.labelValues.contains(filters.label ?? "")
            let matchesQuery = normalizedQuery.isEmpty || releaseMatchesQuery(release, query: normalizedQuery)
            return matchesYear && matchesGenre && matchesLabel && matchesQuery
        }
    }

    var availableYears: [Int] {
        Array(Set(releases.compactMap(\.year))).sorted(by: >)
    }

    var availableGenres: [String] {
        Array(Set(releases.flatMap(\.genreValues))).sorted()
    }

    var availableLabels: [String] {
        Array(Set(releases.flatMap(\.labelValues))).sorted()
    }

    func navigationTitle(for artistName: String) -> String {
        "\(artistName) Albums"
    }

    func yearText(for release: ArtistRelease) -> String {
        release.year.map(String.init) ?? ui.unknownYearText
    }

    func genresText(for release: ArtistRelease) -> String? {
        guard !release.genreValues.isEmpty else { return nil }
        return release.genreValues.joined(separator: ", ")
    }

    func loadInitial() async {
        guard releases.isEmpty else { return }
        await loadNextPageIfNeeded(currentItem: nil)
    }

    func reloadWithCurrentSort() async {
        guard !isLoading else { return }
        releases = []
        currentPage = 0
        totalPages = 1
        await loadNextPageIfNeeded(currentItem: nil)
    }

    // Loads paginated artist releases from Discogs.
    func loadNextPageIfNeeded(currentItem: ArtistRelease?) async {
        guard !isLoading else { return }
        guard currentPage < totalPages || currentPage == 0 else { return }

        if let currentItem,
           let index = releases.firstIndex(of: currentItem),
           index < releases.count - 5 {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let nextPage = currentPage + 1
            let response = try await api.artistReleases(
                artistID: artistID,
                page: nextPage,
                sort: selectedSort,
                sortOrder: selectedSortOrder
            )

            releases.append(contentsOf: response.releases)
            currentPage = response.pagination.page
            totalPages = response.pagination.pages

            if releases.isEmpty {
                message = "No releases found for this artist."
            }
        } catch let error as APIError {
            message = error.errorDescription
        } catch {
            message = "Unexpected error while loading releases."
        }
    }

    func resetFilters() {
        filters = ReleaseFilters()
    }

    func collapseBottomSearch() {
        isBottomSearchExpanded = false
        releaseSearchText = ""
    }

    func clearBottomSearch() {
        releaseSearchText = ""
    }

    func toastStyle(for message: String) -> ToastStyle {
        message.hasPrefix("No") ? .info : .error
    }

    private func releaseMatchesQuery(_ release: ArtistRelease, query: String) -> Bool {
        let titleMatch = release.title.lowercased().contains(query)
        let yearMatch = release.year.map(String.init)?.contains(query) == true

        let joinedFormats = release.formatValues.joined(separator: " ").lowercased()
        let formatMatch = joinedFormats.contains(query)

        return titleMatch || yearMatch || formatMatch
    }
}
