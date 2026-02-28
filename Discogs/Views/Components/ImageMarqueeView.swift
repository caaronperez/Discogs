//
//  ImageMarqueeView.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

// Animated rows of square artist thumbnails used in the empty search state.
struct ImageMarqueeView: View {
    let imageURLs: [String]
    let rowCount: Int
    let bottomFadeHeight: CGFloat

    init(imageURLs: [String], rowCount: Int = 4, bottomFadeHeight: CGFloat = 50) {
        self.imageURLs = imageURLs
        self.rowCount = rowCount
        self.bottomFadeHeight = bottomFadeHeight
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<rowCount, id: \.self) { index in
                MarqueeRow(
                    urls: rowURLs(for: index),
                    direction: index.isMultiple(of: 2) ? .left : .right,
                    speed: 30 + CGFloat(index * 4)
                )
                .frame(height: 86)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .mask {
            GeometryReader { geometry in
                let height = max(geometry.size.height, 1)
                let fadeStart = max(0, (height - bottomFadeHeight) / height)

                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: fadeStart),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func rowURLs(for index: Int) -> [String] {
        guard !imageURLs.isEmpty else {
            return Array(repeating: "", count: 12)
        }

        let strideStart = (index * 2) % imageURLs.count
        let head = imageURLs[strideStart...]
        let tail = imageURLs[..<strideStart]
        return Array(head + tail)
    }
}

private struct MarqueeRow: View {
    enum Direction {
        case left
        case right
    }

    let urls: [String]
    let direction: Direction
    let speed: CGFloat

    private let itemSize: CGFloat = 80
    private let spacing: CGFloat = 10

    @State private var anchorDate = Date()

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: .now, by: 1.0 / 60.0)) { context in
                let cycleWidth = CGFloat(urls.count) * (itemSize + spacing)
                let elapsed = CGFloat(context.date.timeIntervalSince(anchorDate))
                let travel = (elapsed * speed).truncatingRemainder(dividingBy: max(cycleWidth, 1))

                let offset = direction == .left ? -travel : -cycleWidth + travel

                HStack(spacing: spacing) {
                    ForEach(Array((urls + urls).enumerated()), id: \.offset) { index, url in
                        MarqueeTile(url: url, size: itemSize)
                            .id(index)
                    }
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(x: offset)
                .clipped()
            }
        }
        .onAppear {
            anchorDate = .now
        }
        .clipped()
    }
}

private struct MarqueeTile: View {
    let url: String
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.15))

            CachedAsyncImage(urlString: url, contentMode: .fill) {
                ProgressView()
                    .tint(.secondary)
            }
            .frame(width: size, height: size)
            .clipped()
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ImageMarqueeView(
        imageURLs: [
            "https://via.placeholder.com/200",
            "https://via.placeholder.com/201",
            "https://via.placeholder.com/202",
            "https://via.placeholder.com/203"
        ],
        rowCount: 4,
        bottomFadeHeight: 50
    )
    .frame(height: 380)
}
