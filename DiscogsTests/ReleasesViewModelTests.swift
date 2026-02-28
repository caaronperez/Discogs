//
//  ReleasesViewModelTests.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Testing
@testable import Discogs

@Suite
@MainActor
struct ReleasesViewModelTests {
    @Test
    func releasesAreSortedNewestFirst() async {
        let api = MockDiscogsAPI(releasesResponsesByPage: [
            1: ArtistReleasesResponse(
                pagination: DiscogsPagination(page: 1, pages: 1, perPage: 30, items: 2),
                releases: [
                    .preview(id: 2, title: "Newer", year: 2010, formatValues: ["Electronic"], labelValues: ["Label B"]),
                    .preview(id: 1, title: "Older", year: 2001, formatValues: ["Rock"], labelValues: ["Label A"])
                ]
            )
        ])

        let viewModel = ReleasesViewModel(artistID: 1, api: api)
        await viewModel.loadInitial()

        #expect(viewModel.filteredAndSortedReleases.map(\.id) == [2, 1])
    }

    @Test
    func filtersApplyToYearGenreAndLabel() async {
        let api = MockDiscogsAPI(releasesResponsesByPage: [
            1: ArtistReleasesResponse(
                pagination: DiscogsPagination(page: 1, pages: 1, perPage: 30, items: 2),
                releases: [
                    .preview(id: 1, title: "One", year: 2020, genreValues: ["Jazz"], formatValues: ["File"], labelValues: ["Blue"]),
                    .preview(id: 2, title: "Two", year: 2020, genreValues: ["Rock"], formatValues: ["File"], labelValues: ["Red"])
                ]
            )
        ])

        let viewModel = ReleasesViewModel(artistID: 1, api: api)
        await viewModel.loadInitial()

        viewModel.filters = ReleaseFilters(year: 2020, genre: "Jazz", label: "Blue")

        #expect(viewModel.filteredAndSortedReleases.count == 1)
        #expect(viewModel.filteredAndSortedReleases.first?.id == 1)
    }

    @Test
    func paginationAppendsNewPages() async {
        let api = MockDiscogsAPI(releasesResponsesByPage: [
            1: ArtistReleasesResponse(
                pagination: DiscogsPagination(page: 1, pages: 2, perPage: 30, items: 2),
                releases: [.preview(id: 1, title: "One", year: 2020, formatValues: ["Rock"], labelValues: ["A"])]
            ),
            2: ArtistReleasesResponse(
                pagination: DiscogsPagination(page: 2, pages: 2, perPage: 30, items: 2),
                releases: [.preview(id: 2, title: "Two", year: 2019, formatValues: ["Rock"], labelValues: ["A"])]
            )
        ])

        let viewModel = ReleasesViewModel(artistID: 1, api: api)
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.filteredAndSortedReleases.last)

        #expect(viewModel.filteredAndSortedReleases.count == 2)
    }
}
