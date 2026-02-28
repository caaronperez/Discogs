//
//  AsyncImageCache.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Combine
import SwiftUI
import UIKit

// This was added to shared in-memory image cache for async image loading, avoids loading one-by-one and
actor AsyncImageCache {
    static let shared = AsyncImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    func loadImage(from url: URL) async throws -> UIImage {
        if let cached = image(for: url) {
            return cached
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw APIError.decodingFailed
        }

        insert(image, for: url)
        return image
    }
}

// Loader image
@MainActor
final class AsyncImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false

    func load(urlString: String?) async {
        guard
            let urlString,
            let url = URL(string: urlString),
            !urlString.isEmpty
        else {
            image = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            image = try await AsyncImageCache.shared.loadImage(from: url)
        } catch {
            image = nil
        }
    }
}

struct CachedAsyncImage<Placeholder: View>: View {
    let urlString: String?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @StateObject private var loader = AsyncImageLoader()

    init(
        urlString: String?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: urlString) {
            await loader.load(urlString: urlString)
        }
    }
}
