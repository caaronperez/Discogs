//
//  DiscogsAPI.swift
//  Discogs
//
//  Created by Cristian Perez on 2/26/26.
//

import Foundation

// MODELS from API
enum ArtistReleaseSort: String, CaseIterable, Identifiable {
    case year
    case title
    case format

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .year:
            return "Year"
        case .title:
            return "Title"
        case .format:
            return "Format"
        }
    }
}

enum ArtistReleaseSortOrder: String, CaseIterable, Identifiable {
    case ascending = "asc"
    case descending = "desc"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

protocol DiscogsAPIProtocol {
    func searchArtists(query: String, page: Int) async throws -> ArtistSearchResponse
    func artistDetails(id: Int) async throws -> ArtistDetail
    func artistReleases(
        artistID: Int,
        page: Int,
        sort: ArtistReleaseSort,
        sortOrder: ArtistReleaseSortOrder
    ) async throws -> ArtistReleasesResponse
}

extension DiscogsAPIProtocol {
    func artistReleases(artistID: Int, page: Int) async throws -> ArtistReleasesResponse {
        try await artistReleases(
            artistID: artistID,
            page: page,
            sort: .year,
            sortOrder: .descending
        )
    }
}

struct DiscogsAPI: DiscogsAPIProtocol {
    private let client: HTTPClientProtocol

    init(client: HTTPClientProtocol = HTTPClient()) {
        self.client = client
    }

    func searchArtists(query: String, page: Int) async throws -> ArtistSearchResponse {
        let request = APIRequest(
            path: "/database/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "type", value: "artist"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(APIConfig.perPage))
            ]
        )
        return try await client.send(request, as: ArtistSearchResponse.self)
    }

    func artistDetails(id: Int) async throws -> ArtistDetail {
        let request = APIRequest(path: "/artists/\(id)")
        return try await client.send(request, as: ArtistDetail.self)
    }

    func artistReleases(
        artistID: Int,
        page: Int,
        sort: ArtistReleaseSort,
        sortOrder: ArtistReleaseSortOrder
    ) async throws -> ArtistReleasesResponse {
        let request = APIRequest(
            path: "/artists/\(artistID)/releases",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(APIConfig.perPage)),
                URLQueryItem(name: "sort", value: sort.rawValue),
                URLQueryItem(name: "sort_order", value: sortOrder.rawValue)
            ]
        )
        return try await client.send(request, as: ArtistReleasesResponse.self)
    }
}

// MARK: - Search Models
struct ArtistSearchResponse: Decodable {
    let pagination: DiscogsPagination
    let results: [ArtistSearchResult]
}

struct ArtistSearchResult: Identifiable, Decodable, Hashable {
    let id: Int
    let title: String
    let thumb: String?
    let type: String?

    var displayName: String {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Unknown Artist" : cleaned
    }
}

struct DiscogsPagination: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int
    let items: Int
}

// MARK: - Artist Models
struct ArtistDetail: Identifiable, Decodable {
    let id: Int
    let name: String
    let profile: String?
    let images: [DiscogsImage]?
    let members: [ArtistMember]?
    let urls: [String]?
}

struct DiscogsImage: Decodable, Hashable {
    let uri: String?
    let uri150: String?
    let width: Int?
    let height: Int?
}

struct ArtistMember: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let active: Bool?
}

// MARK: - Releases Models
struct ArtistReleasesResponse: Decodable {
    let pagination: DiscogsPagination
    let releases: [ArtistRelease]
}

struct ReleaseStats: Decodable, Hashable {
    let community: ReleaseCommunityStats?
}

struct ReleaseCommunityStats: Decodable, Hashable {
    let inWantlist: Int?
    let inCollection: Int?
}

struct ArtistRelease: Identifiable, Decodable, Hashable {
    let id: Int
    let title: String
    let year: Int?
    let thumb: String?
    let type: String?
    let role: String?
    let artist: String?
    let genreValues: [String]
    let formatValues: [String]
    let labelValues: [String]
    let status: String?
    let resourceURL: String?
    let mainRelease: Int?
    let trackInfo: String?
    let stats: ReleaseStats?

    init(
        id: Int,
        title: String,
        year: Int?,
        thumb: String?,
        type: String?,
        role: String?,
        artist: String?,
        genreValues: [String] = [],
        formatValues: [String],
        labelValues: [String],
        status: String? = nil,
        resourceURL: String? = nil,
        mainRelease: Int? = nil,
        trackInfo: String? = nil,
        stats: ReleaseStats? = nil
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.thumb = thumb
        self.type = type
        self.role = role
        self.artist = artist
        self.genreValues = genreValues
        self.formatValues = formatValues
        self.labelValues = labelValues
        self.status = status
        self.resourceURL = resourceURL
        self.mainRelease = mainRelease
        self.trackInfo = trackInfo
        self.stats = stats
    }

    var primaryLabel: String {
        labelValues.first ?? "Unknown label"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case year
        case thumb
        case type
        case role
        case artist
        case format
        case label
        case status
        case resourceURL = "resource_url"
        case mainRelease = "main_release"
        case trackInfo = "trackinfo"
        case stats
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let intID = try? container.decodeIfPresent(Int.self, forKey: .id)
        let stringID = try? container.decodeIfPresent(String.self, forKey: .id)
        id = intID ?? Int(stringID ?? "") ?? 0

        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? "Unknown release"
        thumb = try? container.decodeIfPresent(String.self, forKey: .thumb)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        role = try? container.decodeIfPresent(String.self, forKey: .role)
        artist = try? container.decodeIfPresent(String.self, forKey: .artist)

        if let yearInt = try? container.decodeIfPresent(Int.self, forKey: .year) {
            year = yearInt
        } else if let yearString = try? container.decodeIfPresent(String.self, forKey: .year) {
            year = Int(yearString)
        } else {
            year = nil
        }

        // `artist-releases` endpoint does not provide genre fields.
        genreValues = []

        if let formatArray = try? container.decodeIfPresent([String].self, forKey: .format) {
            formatValues = formatArray
        } else if let formatString = try? container.decodeIfPresent(String.self, forKey: .format) {
            formatValues = formatString.isEmpty ? [] : [formatString]
        } else {
            formatValues = []
        }

        if let labelArray = try? container.decodeIfPresent([String].self, forKey: .label) {
            labelValues = labelArray
        } else if let labelString = try? container.decodeIfPresent(String.self, forKey: .label) {
            labelValues = labelString.isEmpty ? [] : [labelString]
        } else {
            labelValues = []
        }

        status = try? container.decodeIfPresent(String.self, forKey: .status)
        resourceURL = try? container.decodeIfPresent(String.self, forKey: .resourceURL)
        mainRelease = try? container.decodeIfPresent(Int.self, forKey: .mainRelease)
        trackInfo = try? container.decodeIfPresent(String.self, forKey: .trackInfo)
        stats = try? container.decodeIfPresent(ReleaseStats.self, forKey: .stats)
    }
}
