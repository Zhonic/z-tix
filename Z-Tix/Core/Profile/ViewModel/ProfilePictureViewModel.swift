//
//  ProfilePictureViewModel.swift
//  Z-Tix
//
//  Created by Harnish Patel on 29/10/2025.
//

import PhotosUI
import SwiftData
import SwiftUI

// MARK: - Profile Picture View Model

/// View model managing profile picture operations with two-layer storage
/// ARCHITECTURE:
/// - Layer 1: SwiftData stores metadata (userId, filename, lastUpdated)
/// - Layer 2: File System stores actual JPEG image
///
/// This separation provides:
/// - Efficient database queries (no large blobs)
/// - Fast image loading (direct file access)
/// - Offline functionality (local storage)
/// - Cost savings (no Firebase Storage downloads)
@MainActor
class ProfilePictureViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Currently loaded profile image
    /// Updates trigger UI refresh in ProfileView
    @Published var profileImage: UIImage?

    /// Legacy picker flag (unused, kept for future reference)
    @Published var showImagePicker = false

    /// Controls display of image cropper modal
    @Published var showCropper = false

    /// Temporarily holds selected image before cropping
    /// Cleared after crop or cancel
    @Published var selectedImage: UIImage?

    /// PhotosPicker selection item
    /// Automatically triggers photo loading when set
    @Published var photoPickerItem: PhotosPickerItem?

    // MARK: - Private Properties

    /// SwiftData context for database operations
    /// Set by ProfileView on appear
    private var modelContext: ModelContext?

    // MARK: - Context Setup

    /// Inject SwiftData context from environment
    /// Must be called before any database operations
    ///
    /// - Parameter context: ModelContext from @Environment
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Logger.debug("Model context set successfully", code: 0)
    }

    // MARK: - Load Profile Picture

    /// Load profile picture for a specific user
    /// TWO-STEP PROCESS:
    /// 1. Query SwiftData for filename
    /// 2. Load image from file system using filename
    ///
    /// - Parameter userId: User's Firebase UID
    func loadProfilePicture(userId: String) {
        Logger.debug("Loading profile picture for user: \(userId)", code: 0)

        // Verify context is set
        guard let context = modelContext else {
            Logger.error(
                "Model context not set",
                "Cannot load profile picture",
                code: 0
            )
            return
        }

        // MARK: Query SwiftData
        /// Build query predicate to find profile picture by userId
        let descriptor = FetchDescriptor<ProfilePicture>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let results = try context.fetch(descriptor)
            Logger.debug(
                "SwiftData query returned \(results.count) results",
                code: 0
            )

            if let profilePicture = results.first {
                Logger.debug(
                    "Found profile picture record with path: \(profilePicture.imagePath)",
                    code: 0
                )

                // MARK: Load from File System
                /// Use ProfilePictureManager to load actual image
                if let image = ProfilePictureManager.shared.loadProfilePicture(
                    filename: profilePicture.imagePath
                ) {
                    self.profileImage = image
                    Logger.success("Profile picture loaded successfully")
                } else {
                    // File exists in SwiftData but missing from file system
                    // This can happen if user deleted app data
                    Logger.error(
                        "Failed to load image file from disk",
                        profilePicture.imagePath,
                        code: 0
                    )
                }
            } else {
                // No profile picture record - user hasn't uploaded one yet
                Logger.debug(
                    "No profile picture found in SwiftData for this user",
                    code: 0
                )
            }
        } catch {
            Logger.error(
                "Failed to fetch profile picture from SwiftData",
                error.localizedDescription,
                code: 0
            )
        }
    }

    // MARK: - Save Profile Picture

    /// Save cropped profile picture with two-layer storage
    /// PROCESS:
    /// 1. Save image to file system (ProfilePictureManager)
    /// 2. Save metadata to SwiftData (filename, userId, timestamp)
    /// 3. Update UI with new image
    /// 4. Verify save succeeded
    ///
    /// - Parameters:
    ///   - image: Cropped 250x250 UIImage
    ///   - userId: User's Firebase UID
    func saveProfilePicture(image: UIImage, userId: String) {
        Logger.debug("Saving profile picture for user: \(userId)", code: 0)

        // Verify context is set
        guard let context = modelContext else {
            Logger.error(
                "Model context not set",
                "Cannot save profile picture",
                code: 0
            )
            return
        }

        // MARK: Step 1 - Save to File System
        /// ProfilePictureManager handles JPEG compression and file writing
        guard
            let filename = ProfilePictureManager.shared.saveProfilePicture(
                image: image,
                userId: userId
            )
        else {
            Logger.error(
                "Failed to save profile picture to file system",
                "",
                code: 0
            )
            return
        }

        Logger.debug(
            "Image saved to file system with filename: \(filename)",
            code: 0
        )

        // MARK: Step 2 - Save Metadata to SwiftData
        /// Query for existing record to update or insert new
        let descriptor = FetchDescriptor<ProfilePicture>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let results = try context.fetch(descriptor)

            if let existingRecord = results.first {
                // MARK: Update Existing Record
                /// User is changing their profile picture
                Logger.debug("Updating existing SwiftData record", code: 0)
                existingRecord.imagePath = filename
                existingRecord.lastUpdated = Date()

            } else {
                // MARK: Create New Record
                /// User's first profile picture upload
                Logger.debug("Creating new SwiftData record", code: 0)
                let newRecord = ProfilePicture(
                    userId: userId,
                    imagePath: filename
                )
                context.insert(newRecord)
            }

            // MARK: Commit to Database
            /// Explicitly save context to persist changes
            /// SwiftData auto-save may not be immediate
            try context.save()
            Logger.success("SwiftData context saved successfully")

            // MARK: Update UI
            /// Immediately show new profile picture
            self.profileImage = image

            // MARK: Verification Step
            /// Critical for debugging SwiftData issues
            /// Ensures save actually worked
            let verifyResults = try context.fetch(descriptor)
            if verifyResults.isEmpty {
                Logger.error(
                    "CRITICAL: SwiftData save verification failed - record not found after save!",
                    "",
                    code: 0
                )
            } else {
                Logger.success("SwiftData save verified successfully")
            }

        } catch {
            Logger.error(
                "Failed to save to SwiftData",
                error.localizedDescription,
                code: 0
            )
        }
    }

    // MARK: - Delete Profile Picture

    /// Delete profile picture from both layers
    /// PROCESS:
    /// 1. Delete from file system
    /// 2. Delete from SwiftData
    /// 3. Clear UI
    ///
    /// - Parameter userId: User's Firebase UID
    func deleteProfilePicture(userId: String) {
        Logger.debug("Deleting profile picture for user: \(userId)", code: 0)

        // Verify context is set
        guard let context = modelContext else {
            Logger.error(
                "Model context not set",
                "Cannot delete profile picture",
                code: 0
            )
            return
        }

        // Query for existing record
        let descriptor = FetchDescriptor<ProfilePicture>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let results = try context.fetch(descriptor)

            if let profilePicture = results.first {
                Logger.debug(
                    "Found profile picture to delete: \(profilePicture.imagePath)",
                    code: 0
                )

                // MARK: Delete from File System
                /// Remove JPEG file from Documents directory
                ProfilePictureManager.shared.deleteProfilePicture(
                    filename: profilePicture.imagePath
                )

                // MARK: Delete from SwiftData
                /// Remove metadata record
                context.delete(profilePicture)
                try context.save()

                // MARK: Clear UI
                /// Show initials fallback
                self.profileImage = nil
                Logger.success("Profile picture deleted successfully")

            } else {
                // No profile picture to delete (idempotent operation)
                Logger.debug("No profile picture found to delete", code: 0)
            }
        } catch {
            Logger.error(
                "Failed to delete profile picture",
                error.localizedDescription,
                code: 0
            )
        }
    }

    // MARK: - Handle Photo Selection

    /// Process photo selection from PhotosPicker
    /// ASYNC FLOW:
    /// 1. Load image data from PhotosPickerItem
    /// 2. Convert to UIImage
    /// 3. Show cropper modal
    ///
    /// Called automatically when photoPickerItem changes
    func handlePhotoSelection() {
        Task {
            guard let photoPickerItem else { return }

            Logger.debug("Photo selected, loading...", code: 0)

            do {
                // MARK: Load Image Data
                /// PhotosPickerItem loads image asynchronously
                /// Uses Transferable protocol for type-safe loading
                if let data = try await photoPickerItem.loadTransferable(
                    type: Data.self
                ),
                    let uiImage = UIImage(data: data)
                {
                    // MARK: Prepare for Cropping
                    /// Store image temporarily and show cropper
                    selectedImage = uiImage
                    showCropper = true
                    Logger.success("Photo loaded successfully, showing cropper")
                }
            } catch {
                Logger.error(
                    "Failed to load photo",
                    error.localizedDescription,
                    code: 0
                )
            }
        }
    }
}

// MARK: - Architecture Notes

/*
 TWO-LAYER STORAGE PATTERN:

 Why not store images directly in SwiftData?
 - Binary data stored in database is inefficient
 - Slows down all queries even when not accessing images
 - SwiftData/CoreData not optimised for large blobs
 - File system access is faster for images

 Why not use Firebase Storage?
 - Costs money per download
 - Requires network connection
 - Slower than local file system
 - More complex error handling
 - Offline mode would be limited

 Current approach (hybrid):
 - SwiftData: Lightweight metadata (userId, filename, timestamp)
 - File System: Heavy image data (JPEG files)
 - Best of both worlds: Fast queries + fast image loading

 PHOTO SELECTION FLOW:
 1. User taps camera icon → PhotosPicker opens
 2. User selects photo → photoPickerItem changes
 3. onChange triggers handlePhotoSelection()
 4. Photo loads asynchronously → selectedImage set
 5. ImageCropperView presents full-screen
 6. User crops → onCrop callback fires
 7. saveProfilePicture() saves to both layers
 8. UI updates with new profile picture

 ERROR HANDLING:
 - Missing context → Log error, return early
 - File save fails → Log error, don't create SwiftData record
 - SwiftData save fails → Log error, but file is saved (can retry)
 - Verification fails → Critical log, investigate SwiftData issues

 MEMORY MANAGEMENT:
 - UIImage kept in memory while view is active
 - Cleared when view disappears
 - Reloaded from file system on next view appearance
 - File system provides persistent cache
 */
