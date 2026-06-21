//
//  AppDelegate.swift
//  Z-Tix
//
//  Created by Harnish Patel on 5/11/2025.
//

import Firebase
import FirebaseFirestore
import UIKit

// MARK: - App Delegate

/// Application delegate for handling app lifecycle events and core service initialisation
/// Primary responsibility: Configure Firebase and enable offline persistence before any views load
/// Attached to ZTixApp via @UIApplicationDelegateAdaptor
class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - App Launch Configuration

    /// Called when the application finishes launching
    /// This is the FIRST point in the app lifecycle - runs before any views are created
    /// Perfect for initialising critical services like Firebase
    ///
    /// - Parameters:
    ///   - application: The singleton app instance
    ///   - launchOptions: Dictionary with launch-time information (e.g., notification payload)
    /// - Returns: Boolean indicating successful launch (true = continue, false = abort)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // MARK: Firebase Initialisation

        /// Initialise Firebase SDK with configuration from GoogleService-Info.plist
        /// Must be called before any Firebase services are accessed
        FirebaseApp.configure()

        // MARK: Offline Persistence Configuration

        /// Configure Firestore settings for offline-first functionality
        let settings = FirestoreSettings()

        /// Set cache size to 100 MB for local data storage
        /// This allows the app to:
        /// - Store events, tickets, and scan logs locally
        /// - Function fully without internet connection
        /// - Auto-sync changes when connectivity returns
        ///
        /// Size calculation: 100 MB = 100 * 1024 * 1024 bytes
        /// Sufficient for thousands of tickets and events
        let cacheSize = NSNumber(value: 100 * 1024 * 1024)  // 100 MB
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: cacheSize)

        /// Apply the settings to Firestore instance
        /// This MUST be done before any Firestore operations
        Firestore.firestore().settings = settings

        // Log successful configuration for debugging
        Logger.success("Firebase configured with offline persistence enabled")

        // Return true to indicate successful launch
        return true
    }
}
