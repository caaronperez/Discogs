//
//  SearchViewModelTests.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Testing
@testable import Discogs

@Suite
@MainActor
struct SearchViewModelTests {
    @Test
    func submitSearchPopulatesArtists() async {
        let api = MockDiscogsAPI(
            searchResponsesByPage: [
                1: ArtistSearchResponse(
                    pagination: DiscogsPagination(page: 1, pages: 1, perPage: 30, items: 1),
                    results: [ArtistSearchResult(id: 1, title: "Daft Punk", thumb: nil, type: "artist")]
                )
            ]
        )
        let viewModel = SearchViewModel(api: api)

        viewModel.onQueryChanged("daft")
        await viewModel.submitSearch()

        #expect(viewModel.artists.count == 1)
        #expect(viewModel.artists.first?.displayName == "Daft Punk")
    }

    @Test
    func emptySearchResultsProduceFriendlyMessage() async {
        let api = MockDiscogsAPI(
            searchResponsesByPage: [
                1: ArtistSearchResponse(
                    pagination: DiscogsPagination(page: 1, pages: 1, perPage: 30, items: 0),
                    results: []
                )
            ]
        )
        let viewModel = SearchViewModel(api: api)

        viewModel.onQueryChanged("unknown")
        await viewModel.submitSearch()

        #expect(viewModel.artists.isEmpty)
        #expect(viewModel.message == "No artists found for \"unknown\".")
    }
}
