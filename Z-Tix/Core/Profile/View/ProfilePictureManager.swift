//
//  ProfilePictureManager.swift
//  Z-Tix
//
//  Created by Harnish Patel on 29/10/2025.
//

import SwiftUI
import UIKit

// MARK: - Profile Picture Manager

/// Singleton manager for profile picture file system operations
/// Handles saving, loading, and deleting profile pictures from Documents directory
/// Images stored as JPEG with 0.8 compression for optimal size/quality balance
///
/// WHY LOCAL STORAGE:
/// - Avoids repeated Firebase Storage downloads
/// - Works offline
/// - Faster load times
/// - No storage API costs
/// - SwiftData tracks metadata, file system stores actual image
class ProfilePictureManager {

    // MARK: - Singleton

    /// Shared instance for app-wide access
    static let shared = ProfilePictureManager()

    /// Private initialiser enforces singleton pattern
    private init() {}

    // MARK: - Save Profile Picture

    /// Saves a profile picture to the Documents directory
    /// Compresses to JPEG format at 0.8 quality (good balance)
    /// Overwrites existing profile picture if present
    ///
    /// FILENAME PATTERN: profile_{userId}.jpg
    /// Example: profile_abc123xyz.jpg
    ///
    /// - Parameters:
    ///   - image: The UIImage to save (cropped 250x250 circle)
    ///   - userId: The user's Firebase UID (ensures unique filename)
    /// - Returns: The filename of saved image, or nil if save failed
    func saveProfilePicture(image: UIImage, userId: String) -> String? {

        // MARK: Compress Image
        /// Convert to JPEG with 0.8 quality
        /// Reduces file size while maintaining visual quality
        /// Typical size: 20-50 KB per profile picture
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            Logger.error(
                "Failed to compress image",
                "Could not convert to JPEG",
                code: 0
            )
            return nil
        }

        // MARK: Generate Filename
        /// Use userId to ensure unique filename per user
        let filename = "profile_\(userId).jpg"

        // MARK: Get Documents Directory
        /// Documents directory persists across app launches
        /// Backed up to iCloud if user has iCloud enabled
        guard
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else {
            Logger.error(
                "Failed to get documents directory",
                "FileManager error",
                code: 0
            )
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(filename)

        do {
            // MARK: Delete Old Image
            /// Remove existing profile picture before saving new one
            /// Prevents accumulation of old profile pictures
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            // MARK: Write New Image
            /// Save compressed JPEG data to file
            try imageData.write(to: fileURL)
            Logger.success("Profile picture saved successfully to \(filename)")
            return filename
        } catch {
            Logger.error(
                "Failed to save profile picture",
                error.localizedDescription,
                code: 0
            )
            return nil
        }
    }

    // MARK: - Load Profile Picture

    /// Loads a profile picture from the Documents directory
    /// Returns nil if file doesn't exist (new user, deleted picture, etc.)
    ///
    /// - Parameter filename: The filename to load (from SwiftData record)
    /// - Returns: UIImage if found, nil otherwise
    func loadProfilePicture(filename: String) -> UIImage? {

        // Get Documents directory
        guard
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(filename)

        // MARK: Check File Exists
        /// Avoid attempting to load non-existent file
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // MARK: Load Image from Path
        /// UIImage can load directly from file path
        return UIImage(contentsOfFile: fileURL.path)
    }

    // MARK: - Delete Profile Picture

    /// Deletes a profile picture from the Documents directory
    /// Called when user removes their profile picture
    /// Silent failure if file doesn't exist (idempotent operation)
    ///
    /// - Parameter filename: The filename to delete
    func deleteProfilePicture(filename: String) {

        // Get Documents directory
        guard
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else {
            return
        }

        let fileURL = documentsDirectory.appendingPathComponent(filename)

        do {
            // Only delete if file exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                Logger.success("Profile picture deleted successfully")
            }
        } catch {
            Logger.error(
                "Failed to delete profile picture",
                error.localizedDescription,
                code: 0
            )
        }
    }
}

// MARK: - Implementation Notes

/*
 STORAGE ARCHITECTURE:

 Two-layer approach for profile pictures:
 1. SwiftData: Stores metadata (userId, filename, lastUpdated)
 2. File System: Stores actual JPEG image data

 WHY NOT JUST SwiftData?
 - SwiftData stores binary data inefficiently
 - Large blobs slow down queries
 - Images should be separate from relational data

 WHY NOT FIREBASE STORAGE?
 - Costs money for downloads
 - Requires network connection
 - Slower than local file system
 - More complex error handling

 FILE LIFECYCLE:
 1. User selects photo → ImageCropperView crops it
 2. saveProfilePicture() saves JPEG to Documents
 3. ProfilePictureViewModel saves filename to SwiftData
 4. loadProfilePicture() reads from Documents on app launch
 5. deleteProfilePicture() removes both file and SwiftData record

 COMPRESSION QUALITY:
 - 1.0 = Maximum quality, larger file (~100KB)
 - 0.8 = High quality, smaller file (~30KB) ← CHOSEN
 - 0.5 = Medium quality, small file (~15KB), visible artifacts
 */
