//
//  LibraryView.swift
//  phore
//
//  Created by Zane on 8/10/24.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var library: LibraryService
    @State private var showError = false
    @State private var showDetailView = false
    @State private var selectedPhotoAssetId: LibraryService.PHAssetLocalIdentifier = ""
    
    var body: some View {
        ZStack {
            libraryView
                .onAppear {
                    requestForAuthorizationIfNecessary()
                }
            if showError {
                ErrorView(icon: "hand.raised.slash.fill", title: "No Photos Access", subtitle: "Come on, man!")
            }
            if showDetailView {
                detailView
            }
        }
    }
}

extension LibraryView {
    func requestForAuthorizationIfNecessary() {
        // Make sure photo library access is granted
        // If not, show error (app is unusable)
        guard library.authorizationStatus != .authorized || library.authorizationStatus != .limited else { return }
        library.requestAuthorization { error in
            guard error != nil else { return }
            showError = true
        }
    }
    
    var libraryView: some View {
        ScrollView {
            // TODO: potentially replace with List for performance benefit
            // https://x.com/johnestropia/status/1353517294538776577
            LazyVGrid(
                // 5-column row with adaptive width of 100 for each grid item
                // 1px space between columns and rows
                columns: Array(
                    repeating: .init(.adaptive(minimum: 100), spacing: 1), 
                    count: 5
                ),
                spacing: 1
            ) {
                ForEach(library.results, id: \.self) { asset in
                    Button {
                        showDetailView = true
                        selectedPhotoAssetId = asset.localIdentifier
                    } label: {
                        ThumbnailView(assetLocalId: asset.localIdentifier)
                    }
                }
            }
        }
            .defaultScrollAnchor(.bottom)
    }
    
    var detailView: some View {
        ForEach(library.results, id: \.self) { asset in
            if asset.localIdentifier == selectedPhotoAssetId {
                DetailView(
                    assetLocalId: selectedPhotoAssetId,
                    showDetailView: $showDetailView
                )
                    .zIndex(1) // render above photo grid
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeIn),
                            removal: .opacity.animation(.easeOut)
                        )
                    )
            }
        }
    }
}

#Preview {
    LibraryView()
}
