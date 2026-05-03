//
//  PhotoGalleryViewer.swift
//  Vika
//

import SwiftUI

struct GalleryImageItem: Identifiable {
    let id: String
    let urlString: String?
    let imageData: Data?

    static func remote(_ urlString: String) -> GalleryImageItem {
        GalleryImageItem(id: urlString, urlString: urlString, imageData: nil)
    }

    static func local(id: String, data: Data) -> GalleryImageItem {
        GalleryImageItem(id: id, urlString: nil, imageData: data)
    }
}

struct PhotoGalleryViewer: View {
    let items: [GalleryImageItem]
    @Binding var selectedIndex: Int
    let onSetAsProfile: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.6)

            TabView(selection: $selectedIndex) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    galleryItemView(item)
                        .padding(.horizontal, 30)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack {
                if let onSetAsProfile {
                    Button(action: onSetAsProfile) {
                        Text("Set as profile")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 18)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func galleryItemView(_ item: GalleryImageItem) -> some View {
        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let urlString = item.urlString, let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .empty:
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.12))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
