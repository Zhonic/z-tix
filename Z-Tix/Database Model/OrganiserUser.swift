//
//  OrganiserUser.swift
//  Z-Tix
//
//  Created by Harnish Patel on 15/10/2025.
//

import Foundation

// MARK: - Organiser User Model

/// User account model for event organisers
/// Stored in Firestore at: /organisers/{userId}
///
/// AUTHENTICATION:
/// - id matches Firebase Auth UID
/// - Created automatically during registration
/// - Firebase Auth handles passwords/tokens
/// - This model stores profile information only
///
/// RELATIONSHIPS:
/// - Has many Events (one-to-many)
/// - Has one ProfilePicture (one-to-one, SwiftData)
/// - Can have many StaffUsers (planned feature)
///
/// PROTOCOL CONFORMANCES:
/// - Identifiable: SwiftUI support
/// - Codable: Firestore encoding/decoding
struct OrganiserUser: Identifiable, Codable {

    // MARK: - Properties

    /// Unique user identifier (Firebase Auth UID)
    /// Matches Firebase Authentication user ID
    /// Used for permissions and ownership queries
    let id: String

    /// User's first name
    /// Collected during registration
    /// Displayed in profile and greetings
    let firstName: String

    /// User's last name
    /// Collected during registration
    /// Displayed in profile
    let lastName: String

    /// User's email address
    /// Used for authentication and communication
    /// Must be unique across all users
    let email: String

    // MARK: - Computed Properties

    /// User's initials for avatar display
    /// Used when no profile picture is uploaded
    /// Uses PersonNameComponentsFormatter for proper name handling
    ///
    /// EXAMPLES:
    /// - "John Smith" → "JS"
    /// - "Mary Jane Watson" → "MW" (first + last only)
    /// - "O'Brien" → "OB" (handles apostrophes)
    ///
    /// FALLBACK: Returns empty string if parsing fails
    var initials: String {
        // Use PersonNameComponentsFormatter for proper name parsing
        let formatter = PersonNameComponentsFormatter()
        let fullName = firstName + " " + lastName

        // Parse name into components
        if let components = formatter.personNameComponents(from: fullName) {
            // Use abbreviated style (initials)
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }

        // Fallback if parsing fails
        return ""
    }
}

// MARK: - Mock Data

extension OrganiserUser {

    /// Mock user for previews and testing
    /// Prevents need for Firebase authentication in development
    static var MOCK_USER = OrganiserUser(
        id: NSUUID().uuidString,
        firstName: "Harnish",
        lastName: "Patel",
        email: "hpatel@gmail.com"
    )
}

// MARK: - Usage Notes

/*
 LIFECYCLE:
 1. User registers via RegistrationView
 2. AuthViewModel.createUser() creates Firebase Auth account
 3. OrganiserUser document created in Firestore
 4. User session maintained until logout
 5. Profile displayed in ProfileView

 FIRESTORE STRUCTURE:
 /organisers/{userId}
   - id: "firebase-auth-uid"
   - firstName: "John"
   - lastName: "Smith"
   - email: "john@example.com"

 AUTHENTICATION FLOW:
 1. Firebase Auth handles password/token
 2. On successful auth, fetch OrganiserUser from Firestore
 3. Store in AuthViewModel.currentUser
 4. Use throughout app for personalisation

 INITIALS ALGORITHM:
 Why use PersonNameComponentsFormatter?
 - Handles international names correctly
 - Respects cultural naming conventions
 - Handles prefixes/suffixes (Dr., Jr., etc.)
 - More robust than simple string splitting

 Example edge cases:
 - "Mary Jane Watson" → "MW" (not "MJW")
 - "O'Brien" → "OB" (handles apostrophe)
 - "José García" → "JG" (handles accents)
 - "van Gogh" → "VG" (handles lowercase prefixes)

 PROFILE PICTURE:
 - Stored separately in SwiftData (ProfilePicture model)
 - File stored in Documents directory
 - Linked via userId
 - See ProfilePictureViewModel for management

 ACCOUNT DELETION:
 When user deletes account:
 1. Delete all events (cascade to tickets/scans)
 2. Delete organiser document from Firestore
 3. Delete profile picture from file system
 4. Delete Firebase Auth account
 See: AuthViewModel.deleteAccount() for implementation

 FUTURE ENHANCEMENTS:
 - Add phoneNumber field
 - Add companyName field
 - Add subscription tier (free/premium)
 - Add emailVerified boolean
 - Add createdAt timestamp
 - Add lastLoginAt timestamp
 */
