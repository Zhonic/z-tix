//
//  ProfilePicture.swift
//  Z-Tix
//
//  Created by Harnish Patel on 29/10/2025.
//

import Foundation
import SwiftData

// MARK: - Profile Picture Model

/// SwiftData model for profile picture metadata
/// Actual image stored in Documents directory as JPEG file
///
/// TWO-LAYER STORAGE:
/// - SwiftData: Stores metadata (userId, filename, timestamp)
/// - File System: Stores actual JPEG image data
///
/// WHY NOT STORE IMAGE IN SWIFTDATA?
/// - Binary data in database is inefficient
/// - Slows down all queries even when not loading images
/// - File system access is faster for images
/// - SwiftData/CoreData not optimised for large blobs
///
/// WHY NOT USE FIREBASE STORAGE?
/// - Costs money per download
/// - Requires network connection
/// - Slower than local file system
/// - Offline mode would be limited
///
/// RELATIONSHIP:
/// - Belongs to OrganiserUser (one-to-one via userId)
///
/// @Model MACRO:
/// - Marks class as SwiftData persistent model
/// - Generates schema automatically
/// - Enables database operations
/// - Must be class (not struct) for SwiftData
@Model
final class ProfilePicture {

    // MARK: - Properties

    /// User ID linking to OrganiserUser
    /// Firebase Auth UID for unique identification
    /// Used to query profile picture for specific user
    var userId: String

    /// Filename of image in Documents directory
    /// Pattern: "profile_{userId}.jpg"
    /// Example: "profile_abc123xyz.jpg"
    var imagePath: String

    /// Last update timestamp
    /// Tracks when profile picture was changed
    /// Useful for cache invalidation and sync
    var lastUpdated: Date

    // MARK: - Initialisation

    /// Initialise profile picture record
    /// - Parameters:
    ///   - userId: User's Firebase Auth UID
    ///   - imagePath: Filename in Documents directory
    ///   - lastUpdated: Update timestamp (defaults to now)
    init(userId: String, imagePath: String, lastUpdated: Date = Date()) {
        self.userId = userId
        self.imagePath = imagePath
        self.lastUpdated = lastUpdated
    }
}

// MARK: - SwiftData Configuration

/*
 SCHEMA DEFINITION:
 Location: ZTixApp.swift

 var sharedModelContainer: ModelContainer = {
     let schema = Schema([
         ProfilePicture.self
     ])
     let modelConfiguration = ModelConfiguration(
         schema: schema,
         isStoredInMemoryOnly: false  // Persist to disk
     )
     return try ModelContainer(
         for: schema,
         configurations: [modelConfiguration]
     )
 }()

 STORAGE LOCATION:
 - SwiftData database: App's Application Support directory
 - Image files: App's Documents directory

 QUERYING:
 let descriptor = FetchDescriptor<ProfilePicture>(
     predicate: #Predicate { $0.userId == userId }
 )
 let results = try context.fetch(descriptor)
 */

// MARK: - File System Integration

/*
 IMAGE STORAGE FLOW:

 1. UPLOAD:
    - User selects photo via PhotosPicker
    - Photo cropped in ImageCropperView
    - ProfilePictureManager.saveProfilePicture():
      * Compress to JPEG (0.8 quality)
      * Save to Documents/profile_{userId}.jpg
      * Return filename
    - ProfilePictureViewModel.saveProfilePicture():
      * Create or update ProfilePicture record
      * Save SwiftData context

 2. LOAD:
    - ProfilePictureViewModel.loadProfilePicture():
      * Query SwiftData for ProfilePicture record
      * Get imagePath from record
      * ProfilePictureManager.loadProfilePicture(filename):
        - Load UIImage from Documents directory
      * Update @Published profileImage

 3. DELETE:
    - ProfilePictureViewModel.deleteProfilePicture():
      * Delete file from Documents directory
      * Delete ProfilePicture record from SwiftData
      * Clear @Published profileImage

 FILE NAMING:
 - Pattern: profile_{userId}.jpg
 - Ensures unique filename per user
 - Easy to locate and clean up
 - .jpg extension for compression

 COMPRESSION:
 - Quality: 0.8 (good balance)
 - Typical size: 20-50 KB
 - Format: JPEG (better compression than PNG for photos)
 - Original size: 250x250 pixels (from cropper)

 PERSISTENCE:
 - Survives app restarts
 - Survives iOS updates
 - Not backed up to iCloud (can be re-uploaded)
 - Deleted when app is deleted
 */

// MARK: - Usage Example

/*
 TYPICAL USAGE IN PROFILEVIEW:

 @StateObject private var profilePictureVM = ProfilePictureViewModel()
 @Environment(\.modelContext) private var modelContext

 // On view appear:
 profilePictureVM.setModelContext(modelContext)
 profilePictureVM.loadProfilePicture(userId: user.id)

 // Display:
 if let image = profilePictureVM.profileImage {
     Image(uiImage: image)
         .resizable()
         .scaledToFill()
         .frame(width: 72, height: 72)
         .clipShape(Circle())
 } else {
     // Show initials fallback
     Text(user.initials)
 }
 */

// MARK: - Performance Considerations

/*
 MEMORY USAGE:
 - SwiftData record: ~100 bytes (userId + filename + date)
 - Image in memory: ~250KB uncompressed UIImage
 - Image on disk: ~30KB compressed JPEG

 QUERY PERFORMANCE:
 - Fast: SwiftData queries are optimised
 - Query by userId uses index
 - Should complete in <1ms typically

 IMAGE LOADING:
 - Fast: File system access is quick
 - Should complete in <10ms typically
 - No network latency
 - Works offline

 SCALABILITY:
 - One record per user
 - No cascade issues
 - Clean deletion
 - No orphaned files (userId in filename)
 */
