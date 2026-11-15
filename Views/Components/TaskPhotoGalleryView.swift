//
//  TaskPhotoGalleryView.swift
//  Plan4U_iOS
//
//  1-to-1 match with Android TaskEditModal attached photos gallery & Polaroid carousel
//  Comprehensive gallery component for task and notebook photos:
//  - Horizontal scrolling row of 76x76 pt thumbnails
//  - Asynchronous loading with in-memory NSCache
//  - Tap to view full-screen in ImageLightboxModalView
//  - Replace photo button (bottom-left) via PhotosPicker
//  - Delete photo button (top-right red circle) with haptic feedback
//  - Add photo button (Outlined button or "+" card) supporting single & multi-selection
//  - Carousel mode with swipe indicators & quick previews
//

import SwiftUI
import PhotosUI

public enum TaskPhotoGalleryDisplayMode {
    case editableThumbnails // Horizontal row with delete, replace, add buttons
    case carouselPreview    // Swipeable banner with indicators & quick lightbox
    case compactRow         // Miniature badge/row for task cells
}

public struct TaskPhotoGalleryView: View {
    @Binding public var photos: [String]
    public var mode: TaskPhotoGalleryDisplayMode
    public var maxPhotos: Int
    public var isDarkTheme: Bool
    public var accentColor: Color
    public var onPhotosChanged: (([String]) -> Void)?
    public var onTapPhoto: ((Int) -> Void)?

    // PhotosPicker States
    @State private var selectedNewItems: [PhotosPickerItem] = []
    @State private var selectedReplaceItem: PhotosPickerItem? = nil
    @State private var replaceTargetIndex: Int? = nil

    // Lightbox Presentation State
    @State private var activeLightboxIndex: Int? = nil

    // Carousel Page State
    @State private var carouselPageIndex: Int = 0

    public init(
        photos: Binding<[String]>,
        mode: TaskPhotoGalleryDisplayMode = .editableThumbnails,
        maxPhotos: Int = 10,
        isDarkTheme: Bool = false,
        accentColor: Color = Color(hex: 0x6366F1),
        onPhotosChanged: (([String]) -> Void)? = nil,
        onTapPhoto: ((Int) -> Void)? = nil
    ) {
        self._photos = photos
        self.mode = mode
        self.maxPhotos = maxPhotos
        self.isDarkTheme = isDarkTheme
        self.accentColor = accentColor
        self.onPhotosChanged = onPhotosChanged
        self.onTapPhoto = onTapPhoto
    }

    public var body: some View {
        ZStack {
            switch mode {
            case .editableThumbnails:
                editableThumbnailsView
            case .carouselPreview:
                carouselPreviewView
            case .compactRow:
                compactRowView
            }
        }
        // Fullscreen Lightbox Modal Presentation
        .fullScreenCover(isPresented: Binding(
            get: { activeLightboxIndex != nil },
            set: { if !$0 { activeLightboxIndex = nil } }
        )) {
            if let index = activeLightboxIndex {
                ImageLightboxModalView(
                    imageList: photos,
                    initialIndex: index,
                    onDismissRequest: {
                        activeLightboxIndex = nil
                    },
                    onDeletePhoto: { deletedIndex, path in
                        deletePhoto(at: deletedIndex)
                    }
                )
                .background(ClearBackgroundView())
            }
        }
    }

    // MARK: - Mode 1: Editable Thumbnails Horizontal Row
    private var editableThumbnailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Existing Photo Thumbnails
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, path in
                            thumbnailCard(index: index, path: path)
                        }

                        // Add "+" Card at the end of the row if below maxPhotos
                        if photos.count < maxPhotos {
                            addPhotoCard
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                // Outlined "📷 Прикрепить фото" Button (Matches Android when photos list is empty)
                PhotosPicker(
                    selection: $selectedNewItems,
                    maxSelectionCount: maxPhotos,
                    matching: .images
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                            .font(.system(size: 15))

                        Text("📷 Прикрепить фото")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .foregroundStyle(accentColor)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(accentColor.opacity(0.5), lineWidth: 1)
                    )
                }
                .onChange(of: selectedNewItems) { _, items in
                    handleNewPhotosPicked(items)
                }
            }
        }
    }

    // MARK: - Thumbnail Card with Replace & Delete Badges
    private func thumbnailCard(index: Int, path: String) -> some View {
        ZStack {
            // Base Thumbnail Button (Tapping opens Lightbox)
            Button {
                MiodiHapticFeedback.lightClick()
                if let customTap = onTapPhoto {
                    customTap(index)
                } else {
                    activeLightboxIndex = index
                }
            } label: {
                TaskAsyncThumbnail(path: path, isDarkTheme: isDarkTheme)
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xE5E7EB), lineWidth: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                    )
            }
            .buttonStyle(.plain)

            // Replace Button (Bottom-Left)
            VStack {
                Spacer()
                HStack {
                    PhotosPicker(selection: $selectedReplaceItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0x1E293B).opacity(0.85))
                                .frame(width: 24, height: 24)

                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        replaceTargetIndex = index
                    })
                    .padding(3)
                    Spacer()
                }
            }
            .frame(width: 76, height: 76)

            // Delete Button (Top-Right)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        MiodiHapticFeedback.warning()
                        deletePhoto(at: index)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0xDC2626).opacity(0.88))
                                .frame(width: 24, height: 24)

                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(3)
                }
                Spacer()
            }
            .frame(width: 76, height: 76)
        }
        .frame(width: 76, height: 76)
        .onChange(of: selectedReplaceItem) { _, item in
            if let item = item, let target = replaceTargetIndex {
                handleReplacePhotoPicked(item, at: target)
            }
        }
    }

    // Add Photo Card in the horizontal row
    private var addPhotoCard: some View {
        PhotosPicker(
            selection: $selectedNewItems,
            maxSelectionCount: max(1, maxPhotos - photos.count),
            matching: .images
        ) {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor)

                Image(systemName: "camera")
                    .font(.system(size: 12))
                    .foregroundStyle(accentColor.opacity(0.8))
            }
            .frame(width: 76, height: 76)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDarkTheme ? Color(hex: 0x1E2433).opacity(0.5) : Color(hex: 0xF8FAFC))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                            )
                            .foregroundStyle(accentColor.opacity(0.55))
                    )
            )
        }
        .onChange(of: selectedNewItems) { _, items in
            handleNewPhotosPicked(items)
        }
    }

    // MARK: - Mode 2: Carousel Banner with Paging & Indicators
    private var carouselPreviewView: some View {
        VStack(spacing: 8) {
            if !photos.isEmpty {
                ZStack(alignment: .bottomTrailing) {
                    TabView(selection: $carouselPageIndex) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, path in
                            Button {
                                MiodiHapticFeedback.lightClick()
                                activeLightboxIndex = index
                            } label: {
                                TaskAsyncThumbnail(path: path, isDarkTheme: isDarkTheme)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 180)

                    // Page Indicator Badge: "1 / 4"
                    if photos.count > 1 {
                        Text("\(carouselPageIndex + 1) / \(photos.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }

                // Dot Indicators
                if photos.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<photos.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == carouselPageIndex ? accentColor : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mode 3: Compact Row / Badge
    private var compactRowView: some View {
        HStack(spacing: 4) {
            Text("📷")
                .font(.system(size: 12))
            if photos.count > 1 {
                Text("\(photos.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
            }
        }
        .onTapGesture {
            if !photos.isEmpty {
                MiodiHapticFeedback.lightClick()
                activeLightboxIndex = 0
            }
        }
    }

    // MARK: - Photo Actions & Handlers
    private func handleNewPhotosPicked(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var newPaths: [String] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let path = TaskPhotoStorage.savePhoto(image: image) {
                    newPaths.append(path)
                }
            }

            await MainActor.run {
                if !newPaths.isEmpty {
                    photos.append(contentsOf: newPaths)
                    onPhotosChanged?(photos)
                    MiodiHapticFeedback.success()
                }
                selectedNewItems = []
            }
        }
    }

    private func handleReplacePhotoPicked(_ item: PhotosPickerItem, at index: Int) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let newPath = TaskPhotoStorage.savePhoto(image: image) {
                await MainActor.run {
                    guard index < photos.count else { return }
                    let oldPath = photos[index]
                    TaskPhotoStorage.deletePhoto(at: oldPath)
                    photos[index] = newPath
                    onPhotosChanged?(photos)
                    MiodiHapticFeedback.success()
                    selectedReplaceItem = nil
                    replaceTargetIndex = nil
                }
            }
        }
    }

    private func deletePhoto(at index: Int) {
        guard index < photos.count else { return }
        let path = photos.remove(at: index)
        TaskPhotoStorage.deletePhoto(at: path)
        onPhotosChanged?(photos)

        // Adjust carousel page if needed
        if carouselPageIndex >= photos.count && photos.count > 0 {
            carouselPageIndex = photos.count - 1
        }
    }
}

// MARK: - Asynchronous Cached Thumbnail View
public struct TaskAsyncThumbnail: View {
    public let path: String
    public var isDarkTheme: Bool = false

    @State private var image: UIImage? = nil
    @State private var hasFailed: Bool = false

    public init(path: String, isDarkTheme: Bool = false) {
        self.path = path
        self.isDarkTheme = isDarkTheme
    }

    public var body: some View {
        ZStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if hasFailed {
                VStack(spacing: 2) {
                    Text("🐾")
                        .font(.system(size: 20))
                    Text("Ошибка")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.gray)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: path) { _, _ in
            loadImage()
        }
    }

    private func loadImage() {
        if let cached = TaskPhotoStorage.loadImage(from: path) {
            self.image = cached
            self.hasFailed = false
        } else {
            Task {
                if let loaded = await TaskPhotoStorage.loadImageAsync(from: path) {
                    await MainActor.run {
                        self.image = loaded
                        self.hasFailed = false
                    }
                } else {
                    await MainActor.run {
                        self.hasFailed = true
                    }
                }
            }
        }
    }
}

// Helper to allow fullscreen modal backdrop transparency
public struct ClearBackgroundView: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}
