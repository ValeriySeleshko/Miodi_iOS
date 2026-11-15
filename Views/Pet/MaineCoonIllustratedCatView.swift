//
//  MaineCoonIllustratedCatView.swift
//  Plan4U_iOS
//
//  Authentic 1:1 Hand-Drawn Illustrated Maine Coon Mascot.
//  Uses the official raster WebP/PNG illustrations from Plan4U Android.
//

import SwiftUI

public struct MaineCoonIllustratedCatView: View {
    public var colorScheme: String = "ginger"
    public var poseId: Int? = nil
    public var isSleeping: Bool = false
    public var isPurring: Bool = false
    public var isEating: Bool = false

    // Fallback animation triggers
    @State private var isBreathing: Bool = false
    @State private var purrOffset: CGFloat = 0

    public init(
        colorScheme: String = "ginger",
        poseId: Int? = nil,
        isSleeping: Bool = false,
        isPurring: Bool = false,
        isEating: Bool = false
    ) {
        self.colorScheme = colorScheme
        self.poseId = poseId
        self.isSleeping = isSleeping
        self.isPurring = isPurring
        self.isEating = isEating
    }

    private var effectivePoseId: Int {
        if let explicit = poseId { return max(1, min(49, explicit)) }
        if isEating { return 48 }
        if isPurring { return 44 }
        if isSleeping { return 10 }
        return 21 // Default sit sweet
    }

    private var catImageName: String {
        let prefix = "cat_"
        let safeCoat: String
        let raw = colorScheme.lowercased()
        switch raw {
        case "white", "snow": safeCoat = "white"
        case "tiger", "grey", "silver": safeCoat = "grey"
        case "black", "charcoal", "dark": safeCoat = "black"
        case "chocolate", "mocha", "brown": safeCoat = "brown"
        case "siamese": safeCoat = "siamese"
        case "tortie", "calico": safeCoat = "tortie"
        default: safeCoat = "ginger"
        }

        let numStr = String(format: "%02d", effectivePoseId)
        // Find matching asset or construct name
        return "\(prefix)\(safeCoat)_\(numStr)"
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                if let uiImage = loadCatImage(namePattern: catImageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(y: isBreathing ? 1.02 : 1.0, anchor: .bottom)
                        .offset(x: purrOffset, y: purrOffset * 0.5)
                        .animation(.easeInOut(duration: isSleeping ? 2.2 : 1.8).repeatForever(autoreverses: true), value: isBreathing)
                } else {
                    // Fallback to vector cat if asset file is somehow missing
                    MaineCoonVectorCatView(
                        colorScheme: colorScheme,
                        isSleeping: isSleeping,
                        isPurring: isPurring,
                        isEating: isEating
                    )
                }

                if isSleeping {
                    Text("💤")
                        .font(.system(size: geo.size.width * 0.16))
                        .offset(x: geo.size.width * 0.28, y: -geo.size.height * 0.25)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                isBreathing = true
                if isPurring {
                    withAnimation(.linear(duration: 0.08).repeatForever(autoreverses: true)) {
                        purrOffset = 1.2
                    }
                }
            }
        }
    }

    private func loadCatImage(namePattern: String) -> UIImage? {
        // 1. Try UIImage(named:)
        if let img = UIImage(named: namePattern) { return img }

        // 2. Try looking in Bundle.main for WebP or PNG files
        if let path = Bundle.main.path(forResource: namePattern, ofType: "webp", inDirectory: "Cat") ??
                      Bundle.main.path(forResource: namePattern, ofType: "png", inDirectory: "Cat") {
            return UIImage(contentsOfFile: path)
        }

        // 3. Search Bundle.main resource root or wildcard
        let fm = FileManager.default
        if let resourcePath = Bundle.main.resourcePath {
            let catDir = (resourcePath as NSString).appendingPathComponent("Cat")
            if let files = try? fm.contentsOfDirectory(atPath: catDir) {
                if let match = files.first(where: { $0.hasPrefix(namePattern) }) {
                    let fullPath = (catDir as NSString).appendingPathComponent(match)
                    return UIImage(contentsOfFile: fullPath)
                }
            }
            // Root bundle search
            if let files = try? fm.contentsOfDirectory(atPath: resourcePath) {
                if let match = files.first(where: { $0.hasPrefix(namePattern) }) {
                    let fullPath = (resourcePath as NSString).appendingPathComponent(match)
                    return UIImage(contentsOfFile: fullPath)
                }
            }
        }

        return nil
    }
}
