//
//  CachedAsyncImage.swift
//  Vika
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    var body: some View {
        Group {
            if let url {
                if let cached = ImageCacheService.shared.image(for: url.absoluteString) {
                    content(Image(uiImage: cached))
                } else {
                    AsyncImage(url: url, transaction: Transaction(animation: .default)) { phase in
                        switch phase {
                        case .success(let image):
                            content(image)
                                .onAppear {
                                    loadIntoCache(url: url)
                                }
                        case .failure:
                            placeholder()
                        case .empty:
                            placeholder()
                        @unknown default:
                            placeholder()
                        }
                    }
                }
            } else {
                placeholder()
            }
        }
    }

    private func loadIntoCache(url: URL) {
        Task {
            guard ImageCacheService.shared.image(for: url.absoluteString) == nil else { return }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let ui = UIImage(data: data) {
                await MainActor.run {
                    ImageCacheService.shared.insert(ui, for: url.absoluteString)
                }
            }
        }
    }
}
