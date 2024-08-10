//
//  PhotoDetailView.swift
//  phore
//
//  Created by Zane on 1/23/23.
//

import SwiftUI
import Photos

struct PhotoDetailView: View {
    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var colorScheme
    
    /// The image view that will render the photo that we'll fetch
    /// later on. It is set to optional since we don't have an actual
    /// photo when this scene starts to render. We need to give time
    /// for the photo library service to fetch a cached copy
    /// of the photo using the asset id, so we'll set the image with
    /// the fetching photo at a later time.
    ///
    /// Fetching is generally fast, as photos are cached at this
    /// point. So you don't need to worry about photo rendering.
    ///
    /// Also, we would want to free up the image from the memory when
    /// this view disappears to save up memory.
    @State private var image: Image?
    @State private var asset: PHAsset?
    
    /// The reference id of the selected photo
    private var assetLocalId: PhotoLibraryService.PHAssetLocalIdentifier
    
    /// Flag that will close the detail view if set to false
    @Binding var showDetailView: Bool
    @State private var showOverlay: Bool = true
    
    // TODO: change this variable after time delay
    
    /// Zooming value modifiers that are set by pinching to zoom
    /// gestures
    @State private var zoomScale: CGFloat = 1
    @State private var previousZoomScale: CGFloat = 1
    private let minZoomScale: CGFloat = 1
    private let maxZoomScale: CGFloat = 5
    
    init(
        assetLocalId: PhotoLibraryService.PHAssetLocalIdentifier,
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
            
            // Show the image if it's available
            if let _ = image {
                photoView
                    .ignoresSafeArea()
            } else {
                // otherwise, show a spinning progress view
                ProgressView()
            }
        }
        .onTapGesture {
            // TODO: probably a better solution here
            withAnimation {
                showOverlay.toggle()
            }
        }
        // The toolbar view holds the close button
        .overlay(
            VStack {
                if self.showOverlay {
                    toolbarView
                } else {
                    EmptyView()
                }
            }
        )
        // We need to use the task to work on a concurrent request to
        // load the image from the photo library service, which is an
        // asynchronous work.
        .task {
            await loadImageAsset()
        }
        // Finally, when the view disappears, we need to free it up
        // from the memory
        .onDisappear {
            image = nil
        }
        // Hides bottom bar while view is present
        //.toolbar(.hidden, for: .tabBar)
        .toolbar(self.showOverlay ? Visibility.visible : Visibility.hidden, for: .tabBar)
        .navigationTitle(assetCreationDate ?? "")
        .toolbar {
//            ToolbarItemGroup(placement: .navigation) {
//                Button(action: { showDetailView = false }) {
//                    Label("Back", systemImage: "chevron.left")
//                }
//            }
            if self.showOverlay {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        /// begin implementing CoreData
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

extension PhotoDetailView {
    func loadImageAsset() async {
        guard let uiImage = try? await photoLibraryService.fetchImage(
            byLocalIdentifier: assetLocalId
        ) else {
            image = nil
            return
        }
        image = Image(uiImage: uiImage)
        
        guard let imageAsset = try? await photoLibraryService.fetchAsset(
            byLocalIdentifier: assetLocalId
        ) else {
            asset = nil
            return
        }
        asset = imageAsset
    }
    
    /// Resets the zoom scale back to 1 – the photo scale at 1x zoom
    func resetImageState() {
        withAnimation(.interactiveSpring()) {
            zoomScale = 1
        }
    }

    /// On double tap
    func onImageDoubleTapped() {
        /// Zoom the photo to 5x scale if the photo isn't zoomed in
        if zoomScale == 1 {
            withAnimation(.spring()) {
                zoomScale = 5
            }
        } else {
            /// Otherwise, reset the photo zoom to 1x
            resetImageState()
        }
    }
    
    func onZoomGestureStarted(value: MagnificationGesture.Value) {
        withAnimation(.easeIn(duration: 0.1)) {
            let delta = value / previousZoomScale
            previousZoomScale = value
            let zoomDelta = zoomScale * delta
            var minMaxScale = max(minZoomScale, zoomDelta)
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
            // Wrap the image with a scroll view.
            // Doing so would limit the photo scroll within the
            // bounds of the scroll view, but will still have
            // the same functionality of adding pan gesture support.
            ScrollView(
                [.vertical, .horizontal],
                showsIndicators: false
            ) {
                image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture(count: 2, perform: onImageDoubleTapped)
                    .gesture(zoomGesture)
                    .frame(width: proxy.size.width * max(minZoomScale, zoomScale))
                    .frame(maxHeight: .infinity)
            }
        }
    }
    
    var toolbarView: some View {
        ZStack {
            // TODO: fix how this looks in light mode
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .dark : .light))
                .edgesIgnoringSafeArea(.top)
            HStack {
                Button(action: { showDetailView = false }) {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // TODO: (maybe) remove extra tap targets caused by maxWidth: .infinity
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

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
//        ZStack {
//            Text("example")
//        }
//        .overlay(
//            PhotoDetailView.toolbarView
//        )
        PhotoDetailView(assetLocalId: "", showDetailView: .constant(true))
    }
}
