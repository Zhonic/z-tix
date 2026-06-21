//
//  Alert.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import SwiftUI

// MARK: - Alert Item Model

/// Identifiable alert model for SwiftUI .alert(item:) modifier
/// Allows presenting alerts reactively with @Published properties
///
/// PATTERN:
/// @Published var alertItem: AlertItem?
/// .alert(item: $alertItem) { alertItem in
///     Alert(...)
/// }
///
/// BENEFITS:
/// - Type-safe alert management
/// - Centralised alert definitions
/// - Consistent messaging
/// - Easy to update alert text
struct AlertItem: Identifiable {

    /// Unique identifier for Identifiable conformance
    /// Auto-generated UUID for each alert
    let id = UUID()

    /// Alert title (bold header)
    /// Example: "Login Failed", "Success!"
    let title: String

    /// Alert message (body text)
    /// Example: "Unable to sign in. Please check your credentials."
    let message: String

    /// Dismiss button configuration
    /// Typically .default(Text("OK"))
    let dismissButton: Alert.Button
}

// MARK: - Alert Context (Central Alert Definitions)

/// Centralised alert definitions for entire app
/// Prevents duplicate alert text and ensures consistency
///
/// ORGANISATION:
/// Grouped by feature area with MARK comments
/// Each alert is a static property for easy access
///
/// USAGE:
/// viewModel.alertItem = AlertContext.loginFailed
struct AlertContext {
    // MARK: - Camera Alerts

    /// Camera not available (simulator or permission denied)
    /// Shown when AVCaptureSession fails to start
    static let invalidDeviceInput = AlertItem(
        title: "Invalid Device Input",
        message:
            "Something is wrong with the camera. We are unable to capture the input.",
        dismissButton: .default(Text("OK"))
    )

    /// Scanned code is unsupported format
    /// Should rarely occur (QR, EAN-8, EAN-13 supported)
    static let invalidScannedType = AlertItem(
        title: "Invalid Scan Type",
        message:
            "The value scanned is not valid. This app scans QR, EAN-8 and EAN-13.",
        dismissButton: .default(Text("OK"))
    )

    // MARK: - Authentication Alerts

    /// Wrong password entered
    /// Firebase Auth error code: wrongPassword
    static let incorrectPassword = AlertItem(
        title: "Incorrect Password",
        message: "The password you entered is incorrect. Please try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Email format invalid
    /// Firebase Auth error code: invalidEmail
    static let invalidEmail = AlertItem(
        title: "Incorrect Email",
        message:
            "The email address is poorly formatted. Please check and try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Account has been disabled by admin
    /// Firebase Auth error code: userDisabled
    static let accountDisabled = AlertItem(
        title: "Account Disabled",
        message:
            "This account has been disabled. Please contact support.",
        dismissButton: .default(Text("OK"))
    )

    /// Network connection issue
    /// Firebase Auth error code: networkError
    static let networkError = AlertItem(
        title: "Network Error",
        message:
            "Please check your internet connection and try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Too many failed login attempts
    /// Firebase Auth error code: tooManyRequests
    /// Account temporarily locked for security
    static let tooManyAttempts = AlertItem(
        title: "Too Many Attempts",
        message:
            "Too many failed login attempts. Please try again later.",
        dismissButton: .default(Text("OK"))
    )

    /// Generic login failure
    /// Fallback for unhandled Firebase Auth errors
    static let loginFailed = AlertItem(
        title: "Login Failed",
        message:
            "Unable to sign in. Please check your credentials and try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Email already registered
    /// Firebase Auth error code: emailAlreadyInUse
    /// User should sign in instead
    static let emailAlreadyExists = AlertItem(
        title: "Email Already Exists",
        message:
            "An account with that email already exists. Please sign in instead or create a new account if this is not your email.",
        dismissButton: .default(Text("OK"))
    )

    /// Password doesn't meet requirements
    /// Firebase Auth error code: weakPassword
    /// Requires 8+ characters
    static let weakPassword = AlertItem(
        title: "Weak Password",
        message:
            "You password is too weak. Please use at least 8 characters with a mix of letters and numbers.",
        dismissButton: .default(Text("OK"))
    )

    /// Generic signup failure
    /// Fallback for unhandled registration errors
    static let signupFailed = AlertItem(
        title: "Signup Failed",
        message:
            "Unable to create account. Please check your information and try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Sign out operation failed
    /// Rare occurrence, typically local state issue
    static let signoutFailed = AlertItem(
        title: "Signout Failed",
        message:
            "Unable to sign out. Please try again.",
        dismissButton: .default(Text("OK"))
    )

    /// No authenticated user session
    /// Guards against operations requiring auth
    static let noUserLoggedIn = AlertItem(
        title: "Error",
        message:
            "No user is currently logged in.",
        dismissButton: .default(Text("OK"))
    )

    /// Unable to fetch user profile data
    /// Firestore query failed or document missing
    static let unableToRetrieveUserInfo = AlertItem(
        title: "Error",
        message:
            "Unable to retrieve user information.",
        dismissButton: .default(Text("OK"))
    )

    /// Account deletion failed
    /// Often requires re-authentication for security
    static let deleteAccountFailed = AlertItem(
        title: "Error",
        message:
            "Unable to delete account. You may need to sign in again to perform this action.",
        dismissButton: .default(Text("OK"))
    )

    /// Feature not yet implemented
    /// Shown for "Coming Soon" features
    static let comingSoon = AlertItem(
        title: "Coming Soon",
        message:
            "This feature is coming soon!",
        dismissButton: .default(Text("OK"))
    )

    // MARK: - Event Alerts

    /// Failed to load events from Firestore
    /// Network issue or query error
    static let fetchEventsFailed = AlertItem(
        title: "Failed to Load Events",
        message:
            "Unable to fetch your events. Please check your connection and try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Event creation failed
    /// Firestore write error
    static let createEventFailed = AlertItem(
        title: "Failed to Create Event",
        message: "Unable to create event. Please try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Event created successfully
    /// Positive feedback (rarely used - success overlay preferred)
    static let eventCreatedSuccessfully = AlertItem(
        title: "Success!",
        message: "Your event has been created successfully.",
        dismissButton: .default(Text("OK"))
    )

    /// Event update failed
    /// Firestore write error
    static let updateEventFailed = AlertItem(
        title: "Failed to Update Event",
        message: "Unable to update event. Please try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Event updated successfully
    /// Positive feedback (rarely used - success overlay preferred)
    static let eventUpdatedSuccessfully = AlertItem(
        title: "Success!",
        message: "Your event has been updated successfully.",
        dismissButton: .default(Text("OK"))
    )

    /// Event deletion failed
    /// Firestore write error or permission issue
    static let deleteEventFailed = AlertItem(
        title: "Failed to Delete Event",
        message: "Unable to delete event. Please try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Event deleted successfully
    /// Confirms cascade deletion completed
    static let eventDeletedSuccessfully = AlertItem(
        title: "Success!",
        message: "Your event has been deleted successfully.",
        dismissButton: .default(Text("OK"))
    )

    /// Account deletion requires recent login
    /// Firebase Auth error code: requiresRecentLogin
    /// Security measure for sensitive operations
    static let requiresRecentLogin = AlertItem(
        title: "Re-Authentication Required",
        message:
            "For security reasons, please sign out and sign back in before deleting your account.",
        dismissButton: .default(Text("OK"))
    )

    /// User document missing from Firestore
    /// Auth exists but profile data corrupted
    static let corruptedAccount = AlertItem(
        title: "Account Error",
        message:
            "Your account data is missing or corrupted. Please contact support or create a new account.",
        dismissButton: .default(Text("OK"))
    )

    // MARK: - Ticket Alerts

    /// CSV import failed
    /// Firestore batch write error
    static let importTicketsFailed = AlertItem(
        title: "Import Failed",
        message: "Unable to import tickets. Please try again.",
        dismissButton: .default(Text("OK"))
    )

    /// Unable to read selected file
    /// File access permission or format error
    static let fileReadFailed = AlertItem(
        title: "File Read Error",
        message: "Unable to read the selected file. Please try again.",
        dismissButton: .default(Text("OK"))
    )
}

// MARK: - Usage Pattern

/*
 TYPICAL IMPLEMENTATION:

 1. VIEW MODEL:
 @MainActor
 class AuthViewModel: ObservableObject {
     @Published var alertItem: AlertItem?

     func signIn() async throws {
         do {
             try await Auth.auth().signIn(...)
         } catch let error as NSError {
             switch error.code {
             case AuthErrorCode.wrongPassword.rawValue:
                 alertItem = AlertContext.incorrectPassword
             case AuthErrorCode.invalidEmail.rawValue:
                 alertItem = AlertContext.invalidEmail
             default:
                 alertItem = AlertContext.loginFailed
             }
         }
     }
 }

 2. VIEW:
 struct LoginView: View {
     @EnvironmentObject var authViewModel: AuthViewModel

     var body: some View {
         // UI content
         .alert(item: $authViewModel.alertItem) { alertItem in
             Alert(
                 title: Text(alertItem.title),
                 message: Text(alertItem.message),
                 dismissButton: alertItem.dismissButton
             )
         }
     }
 }

 3. TRIGGERING ALERT:
 authViewModel.alertItem = AlertContext.loginFailed

 4. DISMISSING ALERT:
 - User taps OK button
 - alertItem automatically set to nil
 - Alert dismissed
 */

// MARK: - Design Benefits

/*
 CENTRALISATION ADVANTAGES:

 1. CONSISTENCY:
    - All alerts have same structure
    - Message tone is consistent
    - Easy to review all app messages

 2. LOCALISATION:
    - Single file to translate
    - No scattered alert text
    - Easier internationalisation

 3. MAINTENANCE:
    - Update message in one place
    - Fix typos globally
    - Refine messaging easily

 4. DISCOVERABILITY:
    - Developers can browse available alerts
    - No duplicate alert creation
    - Reuse existing alerts

 5. TESTING:
    - Easy to trigger specific alerts
    - Consistent error handling
    - Predictable user feedback
 */

// MARK: - Future Enhancements

/*
 POTENTIAL IMPROVEMENTS:

 1. CUSTOM BUTTONS:
    - Add action buttons
    - Primary + secondary actions
    - Cancel options

 2. ALERT TYPES:
    enum AlertType {
        case error
        case warning
        case success
        case info
    }

    - Consistent icons per type
    - Color coding

 3. RETRY ACTIONS:
    - Add retry callbacks
    - Automatic retry logic
    - Progressive backoff

 4. ANALYTICS:
    - Track which alerts shown
    - Identify common errors
    - Improve user experience

 5. CUSTOM STYLING:
    - Brand colors
    - Custom fonts
    - Themed alerts
 */
