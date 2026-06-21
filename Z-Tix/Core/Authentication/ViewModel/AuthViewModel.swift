//
//  AuthViewModel.swift
//  Z-Tix
//
//  Created by Harnish Patel on 15/10/2025.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Authentication Form Protocol

/// Protocol for form validation across authentication views
/// Ensures consistent validation patterns between LoginView and RegistrationView
/// Views implementing this protocol must provide a computed 'formIsValid' property
protocol AuthenticationFormProtocol {
    /// Boolean indicating whether the form meets all validation requirements
    /// Used to enable/disable submit buttons
    var formIsValid: Bool { get }
}

// MARK: - Authentication View Model

/// Central view model managing all authentication and user account operations
/// Handles Firebase Authentication and Firestore user profile synchronization
/// Published properties trigger SwiftUI view updates for reactive UI
@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current Firebase Auth user session
    /// Nil when logged out, populated when authenticated
    /// Changes to this property trigger navigation in ZTixApp
    @Published var userSession: FirebaseAuth.User?

    /// Current user's profile data from Firestore
    /// Contains firstName, lastName, email, etc.
    /// Nil until fetchUser() completes after authentication
    @Published var currentUser: OrganiserUser?

    /// Flag to trigger "Create Account" confirmation dialog
    /// Set to true when sign-in fails due to non-existent account
    /// LoginView observes this to show helpful account creation prompt
    @Published var showCreateAccountPrompt = false

    /// Error alert to display to user
    /// Set by various authentication operations when errors occur
    /// Views display this using .alert(item:) modifier
    @Published var alertItem: AlertItem?

    // MARK: - Initialisation

    /// Initialise view model and restore existing session if present
    /// Checks for existing Firebase Auth session on app launch
    /// Automatically fetches user profile if session exists
    init() {
        // Restore persisted Firebase Auth session (if exists)
        self.userSession = Auth.auth().currentUser

        // Fetch user profile data if session exists
        Task {
            await fetchUser()
        }
    }

    // MARK: - Sign In

    /// Authenticate user with email and password
    /// On success: sets userSession and fetches user profile
    /// On failure: provides specific error feedback or offers account creation
    ///
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Throws: Firebase authentication errors
    func signIn(withEmail email: String, password: String) async throws {
        // Reset create account prompt at start of each sign-in attempt
        // Prevents lingering prompts from previous failed attempts
        showCreateAccountPrompt = false

        do {
            // Attempt Firebase authentication
            let result = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )
            // Store authenticated user session
            self.userSession = result.user

            // Fetch user's Firestore profile data
            await fetchUser()

            // MARK: Orphaned Account Detection
            // Verify Firestore document exists for this user
            // This catches edge case where Firebase Auth account exists
            // but Firestore profile was deleted or never created
            if self.currentUser == nil {
                Logger.error(
                    "User document missing",
                    "Firestore document not found",
                    code: 0
                )
                // Show error to user
                alertItem = AlertContext.corruptedAccount

                // Sign user out to prevent broken state
                try Auth.auth().signOut()
                self.userSession = nil
            }

        } catch let error as NSError {
            Logger.error(
                "Failed to login",
                error.localizedDescription,
                code: error.code
            )

            // MARK: Error Code Parsing
            // Parse Firebase error codes to provide specific user feedback
            // Some errors trigger helpful prompts instead of just showing error
            switch error.code {
            case AuthErrorCode.userNotFound.rawValue:
                // User doesn't exist - offer to create account instead of just showing error
                // This provides better UX than "user not found" message
                showCreateAccountPrompt = true
                Logger.authError("userNotFound", code: error.code)
                return  // Don't throw - confirmation dialog will handle navigation

            case AuthErrorCode.invalidCredential.rawValue:
                // Could mean user doesn't exist OR wrong password
                // Offer account creation as it's likely a non-existent account
                showCreateAccountPrompt = true
                Logger.authError("invalidCredential", code: error.code)
                return  // Don't throw - confirmation dialog will handle navigation

            case AuthErrorCode.wrongPassword.rawValue:
                // Specific wrong password error
                alertItem = AlertContext.incorrectPassword
                Logger.authError("wrongPassword", code: error.code)

            case AuthErrorCode.invalidEmail.rawValue:
                // Email format is invalid
                alertItem = AlertContext.invalidEmail
                Logger.authError("invalidEmail", code: error.code)

            case AuthErrorCode.userDisabled.rawValue:
                // Account has been disabled by admin
                alertItem = AlertContext.accountDisabled
                Logger.authError("userDisabled", code: error.code)

            case AuthErrorCode.networkError.rawValue:
                // Network connectivity issue
                alertItem = AlertContext.networkError
                Logger.authError("networkError", code: error.code)

            case AuthErrorCode.tooManyRequests.rawValue:
                // Rate limiting - too many failed attempts
                alertItem = AlertContext.tooManyAttempts
                Logger.authError("tooManyRequests", code: error.code)

            default:
                // Unhandled error - show generic failure message
                alertItem = AlertContext.loginFailed
                Logger.debug("Unhandled error", code: error.code)
            }

            // Re-throw error so calling code knows operation failed
            throw error
        }

        Logger.success("Successfully signed in")
    }

    // MARK: - Create User

    /// Create new user account with Firebase Auth and Firestore profile
    /// Two-step process:
    /// 1. Create Firebase Authentication account
    /// 2. Create Firestore document with user profile data
    ///
    /// - Parameters:
    ///   - email: User's email address (used for authentication)
    ///   - password: User's chosen password (min 8 characters)
    ///   - firstName: User's first name (stored in Firestore)
    ///   - lastName: User's last name (stored in Firestore)
    /// - Throws: Firebase authentication or Firestore errors
    func createUser(
        withEmail email: String,
        password: String,
        firstName: String,
        lastName: String
    ) async throws {
        do {
            // MARK: Step 1 - Firebase Authentication
            // Create authentication account in Firebase Auth
            // This enables user to sign in with email/password
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )

            // Store authenticated user session
            self.userSession = result.user

            // MARK: Step 2 - Firestore Profile
            // Create user profile object with additional information
            // Firebase Auth only stores email/password, we need more data
            let user = OrganiserUser(
                id: result.user.uid,  // Use Firebase Auth UID as document ID
                firstName: firstName,
                lastName: lastName,
                email: email
            )

            // Encode user object to Firestore-compatible format
            let encodedUser = try Firestore.Encoder().encode(user)

            // Upload profile document to Firestore
            // Document ID matches Firebase Auth UID for easy lookup
            try await Firestore.firestore().collection("organisers").document(
                user.id
            ).setData(encodedUser)

            // Fetch the newly created user profile
            await fetchUser()

        } catch let error as NSError {
            Logger.error(
                "Failed to create user",
                error.localizedDescription,
                code: error.code
            )

            // MARK: Account Creation Error Handling
            // Parse specific Firebase errors for user-friendly messages
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                // Email is already registered
                alertItem = AlertContext.emailAlreadyExists
                Logger.authError("emailAlreadyInUse", code: error.code)

            case AuthErrorCode.weakPassword.rawValue:
                // Password doesn't meet Firebase requirements
                alertItem = AlertContext.weakPassword
                Logger.authError("weakPassword", code: error.code)

            case AuthErrorCode.invalidEmail.rawValue:
                // Email format is invalid
                alertItem = AlertContext.invalidEmail
                Logger.authError("invalidEmail", code: error.code)

            case AuthErrorCode.networkError.rawValue:
                // Network connectivity issue
                alertItem = AlertContext.networkError
                Logger.authError("networkError", code: error.code)

            default:
                // Unhandled error - show generic failure message
                alertItem = AlertContext.signupFailed
                Logger.debug("Unhandled error", code: error.code)
            }

            // Re-throw so calling code knows operation failed
            throw error
        }

        Logger.success("Successfully signed up")
    }

    // MARK: - Sign Out

    /// Sign out current user and clear all session data
    /// Clears both Firebase Auth session and local user data
    /// Failure to sign out shows alert but doesn't throw
    func signOut() {
        do {
            // Sign out from Firebase Authentication
            // This invalidates the auth token on the backend
            try Auth.auth().signOut()

            // Clear local session data
            // This triggers navigation back to login screen in ZTixApp
            self.userSession = nil

            // Clear user profile data
            self.currentUser = nil

        } catch let error as NSError {
            // Sign out failure is rare but possible with network issues
            alertItem = AlertContext.signoutFailed

            Logger.error(
                "Failed to sign out",
                error.localizedDescription,
                code: error.code
            )
        }
    }

    // MARK: - Delete Account

    /// Permanently delete user account and all associated data
    /// Implements cascade deletion pattern to maintain data integrity
    /// Deletion order: Tickets → Scan Logs → Events → Firestore Profile → Auth Account
    ///
    /// CRITICAL: This operation is irreversible
    /// All user data is permanently deleted from Firebase
    func deleteAccount() async {
        // Verify user is authenticated
        guard let user = Auth.auth().currentUser else {
            // Display error to user as alert
            alertItem = AlertContext.noUserLoggedIn
            return
        }

        // Get user ID for Firestore queries
        guard let uid = user.uid as String? else {
            // Display error to user as alert
            alertItem = AlertContext.unableToRetrieveUserInfo
            return
        }

        do {
            // MARK: Step 1 - Find All User Events
            // Query all events created by this user
            let eventsSnapshot = try await Firestore.firestore()
                .collection("events")
                .whereField("organiserId", isEqualTo: uid)
                .getDocuments()

            Logger.debug(
                "Found \(eventsSnapshot.documents.count) events to cascade delete",
                code: 0
            )

            // MARK: Step 2 - Cascade Delete Each Event
            // For each event, delete all related data to prevent orphaned records
            for eventDoc in eventsSnapshot.documents {
                let eventId = eventDoc.documentID

                // MARK: Delete Tickets Subcollection
                // Get all tickets for this event
                let ticketsSnapshot = try await Firestore.firestore()
                    .collection("events")
                    .document(eventId)
                    .collection("tickets")
                    .getDocuments()

                // Use batch write for efficient deletion
                let ticketBatch = Firestore.firestore().batch()
                for ticketDoc in ticketsSnapshot.documents {
                    ticketBatch.deleteDocument(ticketDoc.reference)
                }

                try await ticketBatch.commit()
                Logger.success(
                    "Deleted \(ticketsSnapshot.documents.count) tickets for event \(eventId)"
                )

                // MARK: Delete Scan Logs
                // Get all scan logs for this event (stored in separate collection)
                let scansSnapshot = try await Firestore.firestore()
                    .collection("ticketScans")
                    .whereField("eventId", isEqualTo: eventId)
                    .getDocuments()

                // Use batch write for efficient deletion
                let scanBatch = Firestore.firestore().batch()
                for scanDoc in scansSnapshot.documents {
                    scanBatch.deleteDocument(scanDoc.reference)
                }
                try await scanBatch.commit()
                Logger.success(
                    "Deleted \(scansSnapshot.documents.count) scan logs for event \(eventId)"
                )

                // MARK: Delete Event Document
                // Delete the event document itself
                try await eventDoc.reference.delete()
                Logger.success("Deleted event document \(eventId)")
            }

            Logger.success(
                "Cascade deleted all \(eventsSnapshot.documents.count) events with their tickets and scans"
            )

            // MARK: Step 3 - Delete Firestore User Profile
            // Delete the user's profile document from organisers collection
            try await Firestore.firestore()
                .collection("organisers")
                .document(uid)
                .delete()
            Logger.success("Deleted organiser document from Firestore")

            // MARK: Step 4 - Delete Firebase Auth Account
            // Finally delete the authentication account
            // This must be done last as it invalidates the auth token
            try await user.delete()
            Logger.success("Deleted user from Firebase Authentication")

            // MARK: Step 5 - Clear Local State
            // Clear local session data
            self.userSession = nil
            self.currentUser = nil

            // Reset splash screen so it shows again on next install
            // This provides fresh onboarding experience
            SplashManager.resetSplash()

            Logger.success("Successfully deleted account with full cascade")

        } catch let error as NSError {
            Logger.error(
                "Failed to delete account",
                error.localizedDescription,
                code: error.code
            )

            // MARK: Re-authentication Required
            // Firebase requires recent authentication for sensitive operations
            // If session is too old, user must sign in again
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                // User needs to sign in again before deleting
                alertItem = AlertContext.requiresRecentLogin
                Logger.authError("requiresRecentLogin", code: error.code)
            } else {
                // Generic deletion failure
                alertItem = AlertContext.deleteAccountFailed
            }
        }
    }

    // MARK: - Fetch User Profile

    /// Fetch user's Firestore profile document
    /// Called after authentication to load user data
    /// Silently fails if user document doesn't exist (logged for debugging)
    func fetchUser() async {
        // Get current user's ID
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Fetch user document from Firestore
        guard
            let snapshot = try? await Firestore.firestore().collection(
                "organisers"
            ).document(uid).getDocument()
        else {
            Logger.error("Failed to fetch user", "Document not found", code: 0)
            return
        }

        // Decode Firestore document to OrganiserUser model
        self.currentUser = try? snapshot.data(as: OrganiserUser.self)

        print("DEBUG: Current user is \(String(describing: self.currentUser))")
    }
}
