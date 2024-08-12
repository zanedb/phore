//
//  DetailView.swift
//  phore
//
//  Created by Zane on 8/10/24.
//

import SwiftUI
import Photos

struct DetailView: View {
    @EnvironmentObject var library: LibraryService
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: Image?
    @State private var asset: PHAsset?
    
    private var assetLocalId: LibraryService.PHAssetLocalIdentifier

    @Binding var showDetailView: Bool
    @State private var showOverlay: Bool = true // TODO: change after time delay
    @State private var zoomScale: CGFloat = 1
    @State private var previousZoomScale: CGFloat = 1
    
    private let minZoomScale: CGFloat = 1
    private let maxZoomScale: CGFloat = 5
    
    init(
        assetLocalId: LibraryService.PHAssetLocalIdentifier,
        showDetailView: Binding<Bool>
    ) {
        self.assetLocalId = assetLocalId
        self._showDetailView = showDetailView
    }
    
    var body: some View {
        ZStack {
            // If the overlay is shown, show a white or black bg depending on device colorScheme
            if self.showOverlay {
                if colorScheme == .dark {
                    Color.black
                } else {
                    Color.white
                }
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            // Show image if available
            if let _ = image {
                photoView.ignoresSafeArea()
            } else {
                ProgressView()
            }
        }
        .overlay(
            VStack {
                if self.showOverlay {
                    toolbarView
                } else {
                    EmptyView()
                }
            }
        )
        .task {
            await loadImageAsset()
        }
        .onDisappear {
            image = nil
        }
        // Hides bottom bar while view is present
        //.toolbar(.hidden, for: .tabBar)
        .toolbar(self.showOverlay ? Visibility.visible : Visibility.hidden, for: .tabBar)
        .navigationTitle(assetCreationDate ?? "")
        .toolbar {
            if self.showOverlay {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
//                        let photo = Photo()
//                        photo.assetLocalId = assetLocalId
//                        try? moc.save()
                    }) {
                        Label("Add to Collection", systemImage: "heart")
                    }
                }
            }
        }
    }
}

extension DetailView {
    func loadImageAsset() async {
        guard let uiImage = try? await library.fetchImage(
            byLocalIdentifier: assetLocalId
        ) else {
            image = nil
            return
        }
        image = Image(uiImage: uiImage)
        
        guard let imageAsset = try? await library.fetchAsset(
            byLocalIdentifier: assetLocalId
        ) else {
            asset = nil
            return
        }
        asset = imageAsset
    }
    
    // Resets the zoom scale back to 1
    func resetImageState() {
        withAnimation(.interactiveSpring()) {
            zoomScale = 1
        }
    }
    
    func onImageDoubleTapped() {
        // Zoom photo to 5x scale if not zoomed in
        // Otherwise reset to 1x
        if zoomScale == 1 {
            withAnimation(.spring()) {
                zoomScale = 5
            }
        } else {
            resetImageState()
        }
    }
    
    func onImageTapped() {
        withAnimation {
            showOverlay.toggle()
        }
    }
    
    func onZoomGestureStarted(value: MagnificationGesture.Value) {
        withAnimation(.easeIn(duration: 0.1)) {
            let delta = value / previousZoomScale
            previousZoomScale = value
            let zoomDelta = zoomScale * delta
            var minMaxScale = min(maxZoomScale, zoomDelta)
            minMaxScale = min(maxZoomScale, minMaxScale)
            zoomScale = minMaxScale
        }
    }
    
    func onZoomGestureEnded(value: MagnificationGesture.Value) {
        previousZoomScale = 1
        if zoomScale <= 1 {
            resetImageState()
        } else if zoomScale > 5 {
            zoomScale = 5
        }
    }
    
    var assetCreationDate: String? {
        return asset?.creationDate?.formatted(.dateTime.month(.wide).day(.defaultDigits))
    }
    
    var assetCreationTime: String? {
        return asset?.creationDate?.formatted(.dateTime.hour(.conversationalDefaultDigits(amPM: .abbreviated)).minute(.twoDigits))
    }
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged(onZoomGestureStarted)
            .onEnded(onZoomGestureEnded)
    }
    
    var photoView: some View {
        GeometryReader { proxy in
            // Wrap image in ScrollView
            // Limits scroll to within bounds but keeps pan/gesture support
            ScrollView(
                [.vertical, .horizontal],
                showsIndicators: false
            ) {
                image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture(count: 2, perform: onImageDoubleTapped)
                    .onTapGesture(count: 1, perform: onImageTapped)
                    .gesture(zoomGesture)
                    .frame(width: proxy.size.width * max(minZoomScale, zoomScale))
                    .frame(maxHeight: .infinity)
            }
        }
    }
    
    var toolbarView: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .dark : .light))
                .edgesIgnoringSafeArea(.top)
            HStack {
                Button(action: { showDetailView = false }) {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity, alignment: .leading) // TODO: (maybe) remove extra tap targets caused by maxWidth: .infinity
                }
                
                Spacer()
                
                VStack {
                    Text(assetCreationDate ?? "")
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(assetCreationTime ?? "")
                        .font(.caption)
                        .lineLimit(1)
                }
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                Link(destination: URL(string: "photos-redirect://")!) {
                    Label("Open in Photos", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(height: 44)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    var closeButton: some View {
        Button {
            showDetailView = false
        } label: {
            Image(systemName: "chevron.left")
                .font(.body.bold())
                .aspectRatio(contentMode: .fit)
                //.foregroundColor(.white)
                //.frame(width: 16, height: 16)
                //.padding(.all, 12)
                //.background(.ultraThinMaterial, in: Circle())
        }
    }
}

#Preview {
    DetailView(assetLocalId: "", showDetailView: .constant(true))
}
