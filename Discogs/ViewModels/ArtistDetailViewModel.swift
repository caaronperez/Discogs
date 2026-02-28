//
//  ArtistDetailViewModel.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Combine
import Foundation

@MainActor
final class ArtistDetailViewModel: ObservableObject {
    struct UI {
        let releasesButtonTitle = "View Artist Albums"
        let releasesButtonSystemImage = "music.note.list"
        let emptyDetailsTitle = "No details available"
        let emptyDetailsSystemImage = "person.crop.circle.badge.exclamationmark"
        let toastTitle = "Artist"
        let heroPlaceholderSystemImage = "person.2.circle"
        let membersSectionTitle = "Band Members"
        let membersSortTitle = "Sort"
        let activeMemberLabel = "Active"
    }

    let ui = UI()

    enum MemberSort: String, CaseIterable, Identifiable {
        case nameAscending = "Name A-Z"
        case nameDescending = "Name Z-A"
        case activeFirst = "Active First"

        var id: String { rawValue }
    }

    @Published private(set) var artist: ArtistDetail?
    @Published private(set) var isLoading = false
    @Published var memberSort: MemberSort = .activeFirst
    @Published var message: String?

    private let artistID: Int
    private let api: DiscogsAPIProtocol

    init(artistID: Int, api: DiscogsAPIProtocol? = nil) {
        self.artistID = artistID
        self.api = api ?? DiscogsAPI()
    }

    var sortedMembers: [ArtistMember] {
        let members = artist?.members ?? []
        switch memberSort {
        case .nameAscending:
            return members.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return members.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .activeFirst:
            return members.sorted {
                ($0.active ?? false) == ($1.active ?? false)
                    ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    : ($0.active ?? false) && !($1.active ?? false)
            }
        }
    }

    func loadIfNeeded() async {
        guard artist == nil else { return }
        await load()
    }

    // Loads artist detail information from Discogs.
    func load() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            artist = try await api.artistDetails(id: artistID)
        } catch let error as APIError {
            message = error.errorDescription
        } catch {
            message = "Unexpected error while loading artist details."
        }
    }
}
