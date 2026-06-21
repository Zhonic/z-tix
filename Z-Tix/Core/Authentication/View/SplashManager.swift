//
//  SplashManager.swift
//  Z-Tix
//
//  Created by Harnish Patel on 20/10/2025.
//

import Foundation

// MARK: - Splash Manager

/// Utility class for managing splash screen display state using UserDefaults
/// Ensures splash screen is only shown once per app installation
/// Used by ZTixApp to determine initial navigation route
class SplashManager {

    // MARK: - Constants

    /// UserDefaults key for tracking splash screen visibility
    /// Private to encapsulate implementation details
    private static let hasSeenSplashKey = "hasSeenSplash"

    // MARK: - Computed Property

    /// Boolean flag indicating whether user has seen the splash screen
    /// Uses UserDefaults for persistent storage across app launches
    /// - Returns: true if splash has been seen, false for first-time users
    static var hasSeenSplash: Bool {
        get {
            // Retrieves stored value, defaults to false if not set
            return UserDefaults.standard.bool(forKey: hasSeenSplashKey)
        }
        set {
            // Persists new value to UserDefaults
            UserDefaults.standard.set(newValue, forKey: hasSeenSplashKey)
        }
    }

    // MARK: - Public Methods

    /// Marks the splash screen as seen by the user
    /// Should be called when user taps "Get Started" button
    /// Prevents splash from showing on subsequent app launches
    static func markSplashAsSeen() {
        hasSeenSplash = true
    }

    /// Resets the splash screen state to show it again
    /// Currently used when user deletes their account
    /// Future use cases: testing, user preference resets
    static func resetSplash() {
        hasSeenSplash = false
    }
}

// MARK: - Usage Notes

/*
 USAGE PATTERN:

 1. App Launch (ZTixApp):
    - Check SplashManager.hasSeenSplash
    - If false → Show ZTixSplash (first-time user)
    - If true → Show LoginView directly (returning user)

 2. Splash Screen (ZTixSplash):
    - User taps "Get Started"
    - Call SplashManager.markSplashAsSeen()
    - Navigate to LoginView

 3. Account Deletion (AuthViewModel):
    - User deletes account
    - Call SplashManager.resetSplash()
    - Next launch shows splash screen again

 PERSISTENCE:
 - Uses UserDefaults.standard for lightweight, persistent storage
 - Survives app restarts but not app deletion/reinstallation
 - This is intentional: first install should always show splash

 ALTERNATIVES CONSIDERED:
 - Keychain: Overkill for non-sensitive boolean flag
 - File System: More complex than necessary
 - In-Memory: Would reset on every launch (not desired)
 */
