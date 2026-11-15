//
//  TaskPhotoStorage.swift
//  Plan4U_iOS
//
//  1-to-1 match with Android TaskPhotoStorage.kt
//  Handles parsing, serialization, local file caching, downscaling, and deletion of task attachments.
//  Equipped with high-performance memory cache (NSCache) and asynchronous background decoding.
//

import UIKit

public enum TaskPhotoStorage {
    public static let delimiter = "|"
    private static let photoDirName = "task_photos"
    private static let maxDimension: CGFloat = 1600.0
    private static let compressionQuality: CGFloat = 0.82

    // High-performance memory cache for loaded images & thumbnails
    private static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120 // Up to 120 cached bitmaps
        cache.totalCostLimit = 100 * 1024 * 1024 // ~100 MB max RAM
        return cache
    }()

    public static func parsePhotoUris(_ photoUri: String?) -> [String] {
        guard let uri = photoUri, !uri.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        return uri.components(separatedBy: delimiter)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public static func getPhotoUris(_ photoUri: String?) -> [String] {
        parsePhotoUris(photoUri)
    }

    public static func joinPhotoUris(_ uris: [String]) -> String? {
        let clean = uris
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if clean.isEmpty { return nil }
        return clean.joined(separator: delimiter)
    }

    public static func getPhotoDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent(photoDirName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public static func getAllPhotoFiles() -> [URL] {
        let dir = getPhotoDirectory()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        var validFiles: [URL] = []
        for url in contents {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            if let size = values?.fileSize, size > 0 {
                validFiles.append(url)
            }
        }
        return validFiles
    }

    public static func resolvePhotoPath(_ pathOrName: String) -> String {
        let trimmed = pathOrName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if FileManager.default.fileExists(atPath: trimmed) {
            return trimmed
        }
        let directName = URL(fileURLWithPath: trimmed).lastPathComponent
        let inDir = getPhotoDirectory().appendingPathComponent(directName).path
        if FileManager.default.fileExists(atPath: inDir) {
            return inDir
        }
        return trimmed
    }

    public static func savePhoto(image: UIImage) -> String? {
        let dir = getPhotoDirectory()
        let scaledImage = downscaleIfNeeded(image: image, maxDimension: maxDimension)
        guard let data = scaledImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        let fileName = "photo_\(Int64(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6)).jpg"
        let fileURL = dir.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            // Cache in memory for instant subsequent display
            imageCache.setObject(scaledImage, forKey: fileURL.path as NSString)
            imageCache.setObject(scaledImage, forKey: fileName as NSString)
            return fileURL.path
        } catch {
            return nil
        }
    }

    public static func savePhoto(data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        return savePhoto(image: image)
    }

    public static func savePhotos(images: [UIImage]) -> [String] {
        var paths: [String] = []
        for img in images {
            if let path = savePhoto(image: img) {
                paths.append(path)
            }
        }
        return paths
    }

    public static func loadImage(from path: String) -> UIImage? {
        let resolved = resolvePhotoPath(path)
        let cacheKey = resolved as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        if FileManager.default.fileExists(atPath: resolved),
           let image = UIImage(contentsOfFile: resolved) {
            imageCache.setObject(image, forKey: cacheKey)
            return image
        }
        return nil
    }

    public static func loadImageAsync(from path: String) async -> UIImage? {
        let resolved = resolvePhotoPath(path)
        let cacheKey = resolved as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        return await Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: resolved),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: resolved)),
                  let image = UIImage(data: data) else {
                return nil
            }
            imageCache.setObject(image, forKey: cacheKey)
            return image
        }.value
    }

    public static func deletePhoto(at path: String) {
        let resolved = resolvePhotoPath(path)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: resolved) {
            try? fileManager.removeItem(atPath: resolved)
        }
        let lastComponent = URL(fileURLWithPath: resolved).lastPathComponent
        let inDir = getPhotoDirectory().appendingPathComponent(lastComponent).path
        if fileManager.fileExists(atPath: inDir) {
            try? fileManager.removeItem(atPath: inDir)
        }

        // Evict from memory cache
        imageCache.removeObject(forKey: resolved as NSString)
        imageCache.removeObject(forKey: lastComponent as NSString)
    }

    public static func clearCache() {
        imageCache.removeAllObjects()
    }

    private static func downscaleIfNeeded(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
