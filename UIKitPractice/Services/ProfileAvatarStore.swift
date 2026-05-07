//
//  ProfileAvatarStore.swift
//  UIKitPractice
//

import Foundation
import UIKit

protocol ProfileAvatarStoring {
    func loadAvatar() -> UIImage?
    func saveAvatar(_ image: UIImage) throws
    func deleteAvatar() throws
}

final class ProfileAvatarStore: ProfileAvatarStoring {
    static let shared = ProfileAvatarStore()

    private let fileManager: FileManager
    private let avatarFileName = "profile-avatar.jpg"
    private let maxImageSide: CGFloat = 512
    private let jpegCompressionQuality: CGFloat = 0.82

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadAvatar() -> UIImage? {
        guard let data = try? Data(contentsOf: avatarURL) else { return nil }
        return UIImage(data: data)
    }

    func saveAvatar(_ image: UIImage) throws {
        try fileManager.createDirectory(at: avatarDirectoryURL, withIntermediateDirectories: true)

        let normalizedImage = image.resizedToFit(maxSide: maxImageSide)
        guard let data = normalizedImage.jpegData(compressionQuality: jpegCompressionQuality) else {
            throw AvatarStoreError.encodingFailed
        }

        try data.write(to: avatarURL, options: [.atomic])
    }

    func deleteAvatar() throws {
        guard fileManager.fileExists(atPath: avatarURL.path) else { return }
        try fileManager.removeItem(at: avatarURL)
    }

    private var avatarDirectoryURL: URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("InventiX/Profile", isDirectory: true)
    }

    private var avatarURL: URL {
        avatarDirectoryURL.appendingPathComponent(avatarFileName)
    }
}

private enum AvatarStoreError: Error {
    case encodingFailed
}

private extension UIImage {
    func resizedToFit(maxSide: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxSide else { return normalizedForStorage() }

        let scale = maxSide / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            normalizedForStorage().draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func normalizedForStorage() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
