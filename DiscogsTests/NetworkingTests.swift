//
//  NetworkingTests.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Foundation
import Testing
@testable import Discogs

@MainActor
@Suite
struct NetworkingTests {
    @Test
    func apiErrorMappingHandlesExpectedStatusCodes() {
        #expect(APIError.from(statusCode: 200) == nil)
        #expect(APIError.from(statusCode: 201) == nil)
        #expect(APIError.from(statusCode: 204) == nil)
        #expect(APIError.from(statusCode: 401) == .unauthorized)
        #expect(APIError.from(statusCode: 403) == .forbidden)
        #expect(APIError.from(statusCode: 404) == .notFound)
        #expect(APIError.from(statusCode: 405) == .methodNotAllowed)
        #expect(APIError.from(statusCode: 422) == .unprocessableEntity)
        #expect(APIError.from(statusCode: 500) == .internalServerError)
    }

    @Test
    func searchRequestContainsPaginationAndArtistType() async throws {
        let client = MockHTTPClient(result: ArtistSearchResponse(
            pagination: DiscogsPagination(page: 1, pages: 1, perPage: 30, items: 0),
            results: []
        ))
        let api = DiscogsAPI(client: client)

        _ = try await api.searchArtists(query: "abba", page: 2)

        #expect(client.lastRequest?.path == "/database/search")
        #expect(client.lastRequest?.queryItems.contains(URLQueryItem(name: "type", value: "artist")) == true)
        #expect(client.lastRequest?.queryItems.contains(URLQueryItem(name: "page", value: "2")) == true)
        #expect(client.lastRequest?.queryItems.contains(URLQueryItem(name: "per_page", value: "30")) == true)
    }

    @Test
    func releasesRequestIsSortedDescendingByYear() async throws {
        let client = MockHTTPClient(result: ArtistReleasesResponse(
            pagination: DiscogsPagination(page: 1, pages: 1, perPage: 30, items: 0),
            releases: []
        ))
        let api = DiscogsAPI(client: client)

        _ = try await api.artistReleases(artistID: 10, page: 3)

        #expect(client.lastRequest?.path == "/artists/10/releases")
        #expect(client.lastRequest?.queryItems.contains(URLQueryItem(name: "sort", value: "year")) == true)
        #expect(client.lastRequest?.queryItems.contains(URLQueryItem(name: "sort_order", value: "desc")) == true)
        #expect(client.lastRequest?.queryItems.contains(URLQueryItem(name: "per_page", value: "30")) == true)
    }
}
