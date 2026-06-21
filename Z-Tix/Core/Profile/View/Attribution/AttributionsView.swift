//
//  AttributionsView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 3/11/2025.
//

import SwiftUI

// MARK: - Attributions View

/// Credits and attributions page acknowledging third-party resources
/// Required for:
/// - App Store compliance (acknowledge third-party code/APIs)
/// - Legal requirements (license agreements)
/// - Professional ethics (crediting creators)
/// - Educational transparency (showing learning sources)
///
/// FORMAT:
/// - Full attribution text displayed in cell
/// - Tappable to open external link
/// - Grouped by resource category
/// - External link indicator on right
struct AttributionsView: View {

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {

                // MARK: Introduction Section
                /// Welcoming message explaining the purpose of this page
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            "Z-Tix is built with the help of third-party services, APIs, and educational resources."
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        Text(
                            "We're grateful to the following creators and services:"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // MARK: APIs & Services Section
                /// Third-party services used in production
                Section {

                    // MARK: Firebase
                    /// Backend infrastructure for auth and database
                    FullAttributionRow(
                        text:
                            "Firebase - Google's mobile and web application development platform. Used for Firebase Authentication (user login and account management) and Cloud Firestore (NoSQL database for events, tickets, and scan logs with offline persistence).",
                        url: "https://firebase.google.com"
                    )

                    // MARK: Google Places API
                    /// Address autocomplete and location services
                    FullAttributionRow(
                        text:
                            "Google Places API (New) - Google's location-based services API. Used for address autocomplete when creating events, providing venue suggestions as users type.",
                        url:
                            "https://developers.google.com/maps/documentation/places/web-service/overview"
                    )

                } header: {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.cyan)
                        Text("APIs & Services")
                    }
                }

                // MARK: Educational Resources Section
                /// YouTube tutorials that contributed to development learning
                Section {

                    // MARK: Tutorial 1 - Swift Basics
                    /// Foundation Swift programming course
                    FullAttributionRow(
                        text:
                            "Swift Programming Tutorial – Full Course for Beginners by freeCodeCamp.org - Comprehensive introduction to Swift programming language fundamentals, syntax, and basic concepts.",
                        url: "https://youtu.be/8Xg7E9shq0U"
                    )

                    // MARK: Tutorial 2 - SwiftUI Fundamentals
                    /// SwiftUI framework comprehensive course
                    FullAttributionRow(
                        text:
                            "SwiftUI Fundamentals | FULL COURSE | Beginner Friendly by Sean Allen - Complete course covering SwiftUI framework, views, state management, and modern iOS development patterns.",
                        url: "https://youtu.be/b1oC7sLIgpI"
                    )

                    // MARK: Tutorial 3 - Firebase Integration
                    /// Firebase authentication and async/await patterns
                    FullAttributionRow(
                        text:
                            "COMPLETE User Login / Sign Up App | Swift UI + Firebase | Async / Await by AppStuff - Tutorial demonstrating Firebase Authentication integration with SwiftUI using modern async/await patterns.",
                        url: "https://youtu.be/QJHmhLGv-_0"
                    )

                } header: {
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(.cyan)
                        Text("Educational Resources")
                    }
                }

                // MARK: Documentation & References Section
                /// Official documentation and articles referenced during development
                Section {

                    // MARK: Apple Developer Documentation
                    /// Official Apple framework documentation
                    FullAttributionRow(
                        text:
                            "Apple Developer Documentation - Official documentation for SwiftUI, Swift programming language, iOS SDK, AVFoundation (camera/QR scanning), SwiftData (local data persistence), and all Apple frameworks used in this application.",
                        url: "https://developer.apple.com/documentation"
                    )

                    // MARK: Hacking With Swift
                    /// QR code scanning implementation reference
                    FullAttributionRow(
                        text:
                            "Scanning QR codes with SwiftUI by Paul Hudson (Hacking with Swift) - Article and tutorial demonstrating how to implement QR code scanning using AVFoundation in SwiftUI applications.",
                        url:
                            "https://www.hackingwithswift.com/books/ios-swiftui/scanning-qr-codes-with-swiftui"
                    )

                } header: {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.cyan)
                        Text("Documentation & References")
                    }
                }

                // MARK: Frameworks & SDKs Section
                /// Native Apple frameworks and SDKs used
                Section {

                    // MARK: SwiftUI
                    FullAttributionRow(
                        text:
                            "SwiftUI - Apple's declarative framework for building user interfaces across all Apple platforms. Used for all UI components, navigation, forms, and views throughout the application.",
                        url: "https://developer.apple.com/xcode/swiftui/"
                    )

                    // MARK: SwiftData
                    FullAttributionRow(
                        text:
                            "SwiftData - Apple's framework for data modeling and management. Used for local storage of profile pictures metadata, providing persistent storage independent of network connectivity.",
                        url: "https://developer.apple.com/xcode/swiftdata/"
                    )

                    // MARK: AVFoundation
                    FullAttributionRow(
                        text:
                            "AVFoundation - Apple's framework for working with audiovisual media. Used for camera access and QR/barcode scanning functionality in the ticket scanner feature.",
                        url: "https://developer.apple.com/av-foundation/"
                    )

                } header: {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(.cyan)
                        Text("Apple Frameworks & SDKs")
                    }
                }

                // MARK: Legal Section
                /// Legal disclaimers and copyright notices
                /// Required for App Store compliance
                Section {
                    VStack(alignment: .leading, spacing: 12) {

                        // MARK: Trademark Notice
                        Text(
                            "All trademarks, logos, and brand names are the property of their respective owners. Firebase and Google Places API are trademarks of Google LLC."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)

                        // MARK: Copyright Respect Statement
                        Text(
                            "This application respects all copyrights, licenses, and intellectual property rights. Educational resources are referenced for attribution purposes only."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)

                        // MARK: License Information
                        Text(
                            "All third-party services are used in accordance with their respective terms of service and license agreements."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)

                        // MARK: Contact Information
                        Text(
                            "If you believe any content violates your rights or have licensing questions, please contact the developer."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                } header: {
                    HStack {
                        Image(systemName: "scale.3d")
                            .foregroundColor(.cyan)
                        Text("Legal Notice")
                    }
                }

                // MARK: No Additional Libraries Section
                /// Explicitly state no other third-party libraries used
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            "Z-Tix is built primarily using native Swift and Apple frameworks, with integration of Firebase and Google Places API services. No additional third-party libraries or dependencies are used."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                } header: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.cyan)
                        Text("Additional Information")
                    }
                }
            }
            .navigationTitle("Attributions")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Full Attribution Row Component

/// Row component displaying full attribution text inline
/// Features:
/// - Full attribution text visible in cell
/// - Tappable to open external URL
/// - External link indicator
/// - Multi-line text support
struct FullAttributionRow: View {

    // MARK: - Properties

    /// Complete attribution text displayed in cell
    let text: String

    /// URL to open when tapped
    let url: String

    // MARK: - Body

    var body: some View {
        Button {
            // Open URL in Safari
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {

                // MARK: Attribution Text
                /// Full text displayed with proper formatting
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)  // Allow vertical expansion

                Spacer()

                // MARK: External Link Indicator
                /// Arrow icon indicating external navigation
                /// Aligned to top of text
                Image(systemName: "arrow.up.right.square")
                    .font(.body)
                    .foregroundColor(.cyan)
                    .padding(.top, 2)  // Slight alignment adjustment
            }
            .padding(.vertical, 8)  // Vertical padding for readability
        }
        .buttonStyle(.plain)  // Remove default button styling
    }
}

// MARK: - Preview

#Preview {
    AttributionsView()
}

// MARK: - Attribution Requirements

/*
 WHAT THIS PAGE ACCOMPLISHES:

 1. LEGAL COMPLIANCE:
    - Acknowledges Firebase usage (Google Cloud Services)
    - Credits Google Places API (required by TOS)
    - References educational resources used
    - Provides copyright notices

 2. ACADEMIC REQUIREMENTS:
    - Clearly lists all third-party services
    - Includes educational resources that aided development
    - Shows no additional libraries beyond Firebase/Google
    - Accessible from profile page

 3. PROFESSIONAL ETHICS:
    - Credits content creators (YouTube tutorials)
    - Acknowledges documentation sources
    - Shows respect for intellectual property
    - Transparent about dependencies

 4. APP STORE REQUIREMENTS:
    - Firebase: Google recommends attribution
    - Google Places: Required by Terms of Service
    - Third-party resources properly credited
    - Legal disclaimers included

 ACTUAL RESOURCES USED IN Z-TIX:

 APIs & Services:
 ✅ Firebase Authentication
 ✅ Firebase Firestore
 ✅ Google Places API (New)

 Educational Resources:
 ✅ freeCodeCamp Swift Tutorial
 ✅ Sean Allen SwiftUI Course
 ✅ AppStuff Firebase Tutorial

 Documentation:
 ✅ Apple Developer Documentation
 ✅ Hacking with Swift Article (QR Scanning)

 Apple Frameworks:
 ✅ SwiftUI (UI framework)
 ✅ SwiftData (local storage)
 ✅ AVFoundation (camera/scanning)

 Third-Party Libraries:
 ❌ NONE - No CocoaPods, SPM packages, or other dependencies

 WHY THIS FORMAT:

 The unit specifically requested:
 - Full attribution visible in the cell
 - Not just title/subtitle format
 - Link still available on tap
 - Clear, readable format

 This new format shows:
 - Complete description of what each resource is
 - How it's used in Z-Tix specifically
 - Proper credit to creators
 - Tappable links to sources

 MAINTENANCE:

 If new resources are added:
 1. Identify which category it belongs to
 2. Add a FullAttributionRow with complete description
 3. Explain specifically how it's used in Z-Tix
 4. Ensure URL is correct and accessible
 5. Update legal section if new licenses involved
 */
