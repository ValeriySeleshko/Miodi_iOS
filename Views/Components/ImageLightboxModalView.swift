//
//  ImageLightboxModalView.swift
//  Plan4U_iOS
//
//  1-to-1 match with Android ImageLightboxModal.kt & PolaroidLightboxModal.kt
//  Pixel-perfect modal for viewing task and notebook photos:
//  - True pinch-to-zoom (MagnificationGesture 1.0x .. 5.0x)
//  - Double-tap to zoom toggle (1.0x <-> 2.5x)
//  - Smooth pan/drag when zoomed
//  - Fluid drag-down-to-dismiss (swipe down with progressive scrim fade and velocity release)
//  - Multi-photo carousel navigation with horizontal swipe, bottom pill bar (‹ 1 / N ›), and thumbnails strip
//  - Native image sharing and deletion with haptic feedback
//

import SwiftUI
import UIKit

public struct ImageLightboxModalView: View {
    public var imagePath: String?
    public var imageList: [String]
    public var initialIndex: Int
    public var onDismissRequest: () -> Void
    public var onDeletePhoto: ((Int, String) -> Void)?

    // Multi-photo state
    @State private var effectiveList: [String] = []
    @State private var currentIndex: Int = 0
    @State private var currentImage: UIImage? = nil
    @State private var isLoading: Bool = true

    // Zoom & Pan state
    @State private var scale: CGFloat = 1.0
    @State private var magnifyBy: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero

    // Drag-down-to-dismiss state
    @State private var dismissDragOffset: CGFloat = 0.0
    @State private var isDismissing: Bool = false

    // UI overlays & sheets
    @State private var showControls: Bool = true
    @State private var isShareSheetPresented: Bool = false
    @State private var isDeleteAlertPresented: Bool = false

    public init(
        imagePath: String? = nil,
        imageList: [String] = [],
        initialIndex: Int = 0,
        onDismissRequest: @escaping () -> Void,
        onDeletePhoto: ((Int, String) -> Void)? = nil
    ) {
        self.imagePath = imagePath
        self.imageList = imageList
        self.initialIndex = initialIndex
        self.onDismissRequest = onDismissRequest
        self.onDeletePhoto = onDeletePhoto
    }

    private var currentPath: String {
        guard !effectiveList.isEmpty, currentIndex < effectiveList.count else { return "" }
        return effectiveList[currentIndex]
    }

    private var effectiveScale: CGFloat {
        max(0.7, scale * magnifyBy)
    }

    private var isZoomed: Bool {
        scale > 1.05 || magnifyBy > 1.05
    }

    // Background scrim opacity fades proportionally when user pulls down to dismiss
    private var scrimOpacity: Double {
        let base: Double = 0.94
        if dismissDragOffset > 0 {
            let progress = min(1.0, Double(dismissDragOffset) / 450.0)
            return max(0.1, base * (1.0 - progress))
        }
        return base
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Dark translucent scrim background
                Color(red: 10/255, green: 12/255, blue: 18/255)
                    .opacity(scrimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if !isZoomed {
                            triggerDismiss()
                        } else {
                            resetZoom()
                        }
                    }

                // 2. Main Image Canvas with Zoom, Pan and Swipe-to-Dismiss
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    ZStack {
                        if let image = currentImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    maxWidth: geometry.size.width * 0.92,
                                    maxHeight: geometry.size.height * 0.74
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .shadow(
                                    color: Color.black.opacity(0.55),
                                    radius: 36,
                                    x: 0,
                                    y: 18
                                )
                                .scaleEffect(effectiveScale)
                                .offset(
                                    x: isZoomed ? (panOffset.width + dragOffset.width) : 0,
                                    y: isZoomed ? (panOffset.height + dragOffset.height) : dismissDragOffset
                                )
                                .gesture(gestures(geometry: geometry))
                                .onTapGesture(count: 2) {
                                    handleDoubleTap()
                                }
                                .onTapGesture(count: 1) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showControls.toggle()
                                    }
                                }
                        } else if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .frame(width: 140, height: 140)
                        } else {
                            // Fallback placeholder card
                            VStack(spacing: 12) {
                                Text("🐾")
                                    .font(.system(size: 48))
                                Text("Фото недоступно")
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            .frame(width: 220, height: 220)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: 0x1E2433).opacity(0.85))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }

                        // Floating Close Button (Android-styled white badge at top-right of image)
                        if showControls && !isZoomed {
                            VStack {
                                HStack {
                                    Spacer()
                                    Button {
                                        triggerDismiss()
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 38, height: 38)
                                                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)

                                            Image(systemName: "xmark")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(Color(hex: 0x1E293B))
                                        }
                                    }
                                    .padding(.trailing, 10)
                                    .padding(.top, -14)
                                }
                                Spacer()
                            }
                            .frame(
                                maxWidth: geometry.size.width * 0.92,
                                maxHeight: geometry.size.height * 0.74
                            )
                            .transition(.opacity)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 3. Top Action Bar: Index counter, Share & Delete buttons
                if showControls && !isZoomed {
                    VStack {
                        HStack(spacing: 12) {
                            // Back / Close
                            Button {
                                triggerDismiss()
                            } label: {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Circle())
                            }

                            if effectiveList.count > 1 {
                                Text("\(currentIndex + 1) из \(effectiveList.count)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.35))
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            // Share Button
                            if let image = currentImage {
                                Button {
                                    MiodiHapticFeedback.lightClick()
                                    isShareSheetPresented = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Circle())
                                }
                            }

                            // Delete Button (if callback provided)
                            if onDeletePhoto != nil {
                                Button {
                                    MiodiHapticFeedback.warning()
                                    isDeleteAlertPresented = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color(hex: 0xEF4444))
                                        .frame(width: 40, height: 40)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 8)

                        Spacer()
                    }
                    .transition(.opacity)
                }

                // 4. Bottom Controls: Navigation Pill (‹ 1 / N ›) & Thumbnails
                if showControls && !isZoomed && effectiveList.count > 1 {
                    VStack(spacing: 14) {
                        Spacer()

                        // Multi-photo bottom navigation pill
                        HStack(spacing: 20) {
                            Button {
                                navigatePrevious()
                            } label: {
                                Text("‹")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(currentIndex > 0 ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 32, height: 32)
                            }
                            .disabled(currentIndex <= 0)

                            Text("\(currentIndex + 1) / \(effectiveList.count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            Button {
                                navigateNext()
                            } label: {
                                Text("›")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(currentIndex < effectiveList.count - 1 ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 32, height: 32)
                            }
                            .disabled(currentIndex >= effectiveList.count - 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0x1E293B).opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 10, y: 5)

                        // Quick horizontal thumbnails strip
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(effectiveList.enumerated()), id: \.offset) { index, path in
                                        Button {
                                            if index != currentIndex {
                                                MiodiHapticFeedback.selection()
                                                withAnimation(.easeInOut(duration: 0.22)) {
                                                    currentIndex = index
                                                }
                                                loadActiveImage()
                                            }
                                        } label: {
                                            LightboxThumbnailItem(
                                                path: path,
                                                isSelected: index == currentIndex
                                            )
                                        }
                                        .id(index)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .onChange(of: currentIndex) { _, newIndex in
                                withAnimation {
                                    scrollProxy.scrollTo(newIndex, anchor: .center)
                                }
                            }
                        }
                        .frame(height: 52)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            setupList()
            loadActiveImage()
        }
        .alert("Удалить фото?", isPresented: $isDeleteAlertPresented) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                performDeleteCurrentPhoto()
            }
        } message: {
            Text("Это фото будет удалено безвозвратно.")
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let image = currentImage {
                ActivityShareSheet(items: [image])
            }
        }
    }

    // MARK: - Gestures Setup
    private func gestures(geometry: GeometryProxy) -> some Gesture {
        // Combined Magnification + Pan + Swipe Down
        let pinch = MagnificationGesture()
            .onChanged { value in
                magnifyBy = value
            }
            .onEnded { value in
                let newScale = scale * value
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    if newScale <= 1.0 {
                        scale = 1.0
                        magnifyBy = 1.0
                        panOffset = .zero
                        dragOffset = .zero
                    } else if newScale > 5.0 {
                        scale = 5.0
                        magnifyBy = 1.0
                    } else {
                        scale = newScale
                        magnifyBy = 1.0
                    }
                }
            }

        let panOrDismiss = DragGesture()
            .onChanged { value in
                if isZoomed {
                    // Pan around the zoomed image
                    dragOffset = value.translation
                } else {
                    // Check if downward swipe dominates
                    if value.translation.height > 0 {
                        dismissDragOffset = value.translation.height
                    }
                }
            }
            .onEnded { value in
                if isZoomed {
                    panOffset.width += dragOffset.width
                    panOffset.height += dragOffset.height
                    dragOffset = .zero

                    // Rubber-band clamp pan boundaries
                    let maxPanX = max(0, (geometry.size.width * (scale - 1)) / 2)
                    let maxPanY = max(0, (geometry.size.height * (scale - 1)) / 2)

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        panOffset.width = min(max(panOffset.width, -maxPanX), maxPanX)
                        panOffset.height = min(max(panOffset.height, -maxPanY), maxPanY)
                    }
                } else {
                    // Check swipe-down-to-dismiss threshold or downward flick
                    let translationY = value.translation.height
                    let velocityY = value.predictedEndTranslation.height - translationY

                    if translationY > 120 || velocityY > 300 {
                        // Dismiss!
                        triggerDismiss()
                    } else if translationY < -60 {
                        // User swiped up, bounce back
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dismissDragOffset = 0
                        }
                    } else {
                        // Check horizontal swipe to switch photos
                        let translationX = value.translation.width
                        if effectiveList.count > 1 && abs(translationX) > 50 {
                            if translationX < -50 && currentIndex < effectiveList.count - 1 {
                                navigateNext()
                            } else if translationX > 50 && currentIndex > 0 {
                                navigatePrevious()
                            }
                        }

                        // Spring back to center
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dismissDragOffset = 0
                        }
                    }
                }
            }

        return SimultaneousGesture(pinch, panOrDismiss)
    }

    // MARK: - Actions & Logic
    private func setupList() {
        if !imageList.isEmpty {
            effectiveList = imageList
        } else if let path = imagePath, !path.isEmpty {
            effectiveList = TaskPhotoStorage.parsePhotoUris(path)
        } else {
            effectiveList = []
        }

        if !effectiveList.isEmpty {
            currentIndex = min(max(0, initialIndex), effectiveList.count - 1)
        }
    }

    private func loadActiveImage() {
        guard !currentPath.isEmpty else {
            currentImage = nil
            isLoading = false
            return
        }

        isLoading = true
        resetZoom()

        Task {
            if let cached = TaskPhotoStorage.loadImage(from: currentPath) {
                await MainActor.run {
                    self.currentImage = cached
                    self.isLoading = false
                }
            } else if let asyncLoaded = await TaskPhotoStorage.loadImageAsync(from: currentPath) {
                await MainActor.run {
                    self.currentImage = asyncLoaded
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.currentImage = nil
                    self.isLoading = false
                }
            }
        }
    }

    private func handleDoubleTap() {
        MiodiHapticFeedback.lightClick()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            if scale > 1.05 {
                scale = 1.0
                magnifyBy = 1.0
                panOffset = .zero
                dragOffset = .zero
            } else {
                scale = 2.5
                magnifyBy = 1.0
                panOffset = .zero
                dragOffset = .zero
            }
        }
    }

    private func resetZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            scale = 1.0
            magnifyBy = 1.0
            panOffset = .zero
            dragOffset = .zero
        }
    }

    private func navigatePrevious() {
        guard currentIndex > 0 else { return }
        MiodiHapticFeedback.selection()
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex -= 1
        }
        loadActiveImage()
    }

    private func navigateNext() {
        guard currentIndex < effectiveList.count - 1 else { return }
        MiodiHapticFeedback.selection()
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
        }
        loadActiveImage()
    }

    private func triggerDismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        MiodiHapticFeedback.lightClick()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            dismissDragOffset = 800
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismissRequest()
        }
    }

    private func performDeleteCurrentPhoto() {
        guard !currentPath.isEmpty else { return }
        let deletedIndex = currentIndex
        let deletedPath = currentPath

        onDeletePhoto?(deletedIndex, deletedPath)
        effectiveList.remove(at: deletedIndex)

        if effectiveList.isEmpty {
            triggerDismiss()
        } else {
            currentIndex = min(deletedIndex, effectiveList.count - 1)
            loadActiveImage()
        }
    }
}

// MARK: - Thumbnail Bar Item
private struct LightboxThumbnailItem: View {
    let path: String
    let isSelected: Bool

    @State private var thumbImage: UIImage? = nil

    var body: some View {
        ZStack {
            if let image = thumbImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 44, height: 44)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .onAppear {
            if let cached = TaskPhotoStorage.loadImage(from: path) {
                thumbImage = cached
            } else {
                Task {
                    if let loaded = await TaskPhotoStorage.loadImageAsync(from: path) {
                        await MainActor.run {
                            self.thumbImage = loaded
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Native Activity Share Sheet
public struct ActivityShareSheet: UIViewControllerRepresentable {
    public var items: [Any]

    public init(items: [Any]) {
        self.items = items
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
