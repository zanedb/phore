//
//  ThumbnailView.swift
//  phore
//
//  Created by Zane on 8/10/24.
//

import SwiftUI
import Photos

struct ThumbnailView: View {
    @EnvironmentObject var library: LibraryService
    @State private var image: Image?
    
    private var assetLocalId: String
    
    init(assetLocalId: String) {
        self.assetLocalId = assetLocalId
    }
    
    var body: some View {
        ZStack {
            if let image = image {
                GeometryReader { proxy in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.width
                        )
                        .clipped()
                }
                    .aspectRatio(1, contentMode: .fit)
            } else {
                Rectangle()
                    .foregroundColor(.primary)
                    .colorInvert()
                    .aspectRatio(1, contentMode: .fit)
                ProgressView()
            }
        }
            .task {
                await loadImageAsset()
            }
            .onDisappear {
                image = nil
            }
    }
}

extension ThumbnailView {
    func loadImageAsset(
        targetSize: CGSize = PHImageManagerMaximumSize
    ) async {
        guard let uiImage = try? await library
            .fetchImage(
                byLocalIdentifier: assetLocalId,
                targetSize: targetSize
            ) else {
                image = nil
                return
            }
        image = Image(uiImage: uiImage)
    }
}

#Preview {
    ThumbnailView(assetLocalId: "")
}
