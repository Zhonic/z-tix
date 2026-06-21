//
//  ZTixApp.swift
//  Z-Tix
//
//  Created by Harnish Patel on 25/9/2025.
//

import Firebase
import FirebaseAuth
import FirebaseCore
import SwiftData
import SwiftUI

// MARK: - Main App Entry Point

/// The main application structure for Z-Tix
/// Handles app lifecycle, Firebase configuration, authentication state, and root view navigation
@main
struct ZTixApp: App {

    // MARK: - Properties

    /// AppDelegate adapter for Firebase configuration and offline persistence setup
    /// This enables Firestore offline caching configured in AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Manages user authentication state and session lifecycle
    /// Published changes trigger UI updates for login/logout navigation
    @StateObject var authViewModel = AuthViewModel()

    // No need for the init to configure Firebase as AppDelegate does it

    // MARK: - SwiftData Configuration

    /// SwiftData model container for local data persistence
    /// Currently stores profile pictures to avoid repeated Firebase Storage calls
    /// Configured for persistent storage (not in-memory)
    var sharedModelContainer: ModelContainer = {
        // Define the data models to be persisted
        let schema = Schema([
            ProfilePicture.self  // User profile pictures stored locally
        ])

        // Configure persistence settings
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // Persist to disk for permanent storage
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Fatal error if container creation fails - app cannot function without data layer
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - App Scene

    var body: some Scene {
        WindowGroup {
            Group {
                // MARK: Navigation Logic

                if authViewModel.userSession != nil {
                    // User is authenticated - show main app interface
                    TixTabView()

                } else if SplashManager.hasSeenSplash {
                    // User has seen splash screen before but is logged out
                    // Navigate directly to login screen
                    NavigationStack {
                        LoginView()
                    }
                } else {
                    // First-time user - show onboarding splash screen
                    // SplashManager tracks whether splash has been shown using UserDefaults
                    NavigationStack {
                        ZTixSplash()
                    }
                }
            }
            // Inject authentication view model into environment for all child views
            .environmentObject(authViewModel)

        }
        // Attach SwiftData model container to the scene
        // Makes ProfilePicture model available throughout the app
        .modelContainer(sharedModelContainer)
    }
}
