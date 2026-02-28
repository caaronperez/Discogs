//
//  MockDiscogsAPI.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Foundation

final class MockDiscogsAPI: DiscogsAPIProtocol {
    var searchResponsesByPage: [Int: ArtistSearchResponse]
    var defaultSearchResponse: ArtistSearchResponse
    var artistDetailResponse: ArtistDetail
    var releasesResponsesByPage: [Int: ArtistReleasesResponse]
    var defaultReleasesResponse: ArtistReleasesResponse

    var searchError: Error?
    var artistDetailError: Error?
    var releasesError: Error?

    init(
        searchResponsesByPage: [Int: ArtistSearchResponse] = [:],
        defaultSearchResponse: ArtistSearchResponse = .empty,
        artistDetailResponse: ArtistDetail = .previewArtist,
        releasesResponsesByPage: [Int: ArtistReleasesResponse] = [:],
        defaultReleasesResponse: ArtistReleasesResponse = .empty
    ) {
        self.searchResponsesByPage = searchResponsesByPage
        self.defaultSearchResponse = defaultSearchResponse
        self.artistDetailResponse = artistDetailResponse
        self.releasesResponsesByPage = releasesResponsesByPage
        self.defaultReleasesResponse = defaultReleasesResponse
    }

    func searchArtists(query: String, page: Int) async throws -> ArtistSearchResponse {
        if let searchError {
            throw searchError
        }
        return searchResponsesByPage[page] ?? defaultSearchResponse
    }

    func artistDetails(id: Int) async throws -> ArtistDetail {
        if let artistDetailError {
            throw artistDetailError
        }
        return artistDetailResponse
    }

    func artistReleases(
        artistID: Int,
        page: Int,
        sort: ArtistReleaseSort,
        sortOrder: ArtistReleaseSortOrder
    ) async throws -> ArtistReleasesResponse {
        if let releasesError {
            throw releasesError
        }
        return releasesResponsesByPage[page] ?? defaultReleasesResponse
    }
}

extension ArtistSearchResponse {
    static let empty = ArtistSearchResponse(
        pagination: DiscogsPagination(page: 1, pages: 1, perPage: APIConfig.perPage, items: 0),
        results: []
    )

    static let previewResults = ArtistSearchResponse(
        pagination: DiscogsPagination(page: 1, pages: 1, perPage: APIConfig.perPage, items: 3),
        results: [
            ArtistSearchResult(id: 10, title: "Dua Lipa", thumb: "https://via.placeholder.com/150", type: "artist"),
            ArtistSearchResult(id: 11, title: "Lady Gaga", thumb: "https://via.placeholder.com/150", type: "artist"),
            ArtistSearchResult(id: 12, title: "Shakira", thumb: "https://via.placeholder.com/150", type: "artist")
        ]
    )
}

extension ArtistDetail {
    static let previewArtist = ArtistDetail(
        id: 100,
        name: "Preview Artist",
        profile: "This is preview data for ArtistDetailView.",
        images: [
            DiscogsImage(uri: "https://via.placeholder.com/800", uri150: "https://via.placeholder.com/150", width: 800, height: 800),
            DiscogsImage(uri: "https://via.placeholder.com/801", uri150: "https://via.placeholder.com/151", width: 800, height: 800)
        ],
        members: [
            ArtistMember(id: 1, name: "Member A", active: true),
            ArtistMember(id: 2, name: "Member B", active: false)
        ],
        urls: nil
    )
}

extension ArtistReleasesResponse {
    static let empty = ArtistReleasesResponse(
        pagination: DiscogsPagination(page: 1, pages: 1, perPage: APIConfig.perPage, items: 0),
        releases: []
    )

    static let previewReleases = ArtistReleasesResponse(
        pagination: DiscogsPagination(page: 1, pages: 1, perPage: APIConfig.perPage, items: 3),
        releases: [
            .preview(id: 1, title: "Future Nostalgia", year: 2020, formatValues: ["Vinyl"], labelValues: ["Warner"]),
            .preview(id: 2, title: "Chromatica", year: 2020, formatValues: ["CD"], labelValues: ["Interscope"]),
            .preview(id: 3, title: "El Dorado", year: 2017, formatValues: ["File"], labelValues: ["Sony"])
        ]
    )
}

extension ArtistRelease {
    static func preview(
        id: Int,
        title: String,
        year: Int,
        genreValues: [String] = [],
        formatValues: [String],
        labelValues: [String]
    ) -> ArtistRelease {
        ArtistRelease(
            id: id,
            title: title,
            year: year,
            thumb: "https://via.placeholder.com/150",
            type: "release",
            role: "Main",
            artist: "Preview Artist",
            genreValues: genreValues,
            formatValues: formatValues,
            labelValues: labelValues
        )
    }
}
