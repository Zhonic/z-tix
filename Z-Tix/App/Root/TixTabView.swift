//
//  TixTabView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import SwiftUI

// MARK: - Main Tab View

/// The main tab-based navigation interface for authenticated users
/// Provides access to all primary app features through a bottom tab bar
/// Manages shared view models and state across all tabs
struct TixTabView: View {

    // MARK: - Properties

    /// Shared event view model across tabs for consistent event data
    /// Manages fetching, creating, updating, and deleting events
    @StateObject private var eventViewModel = EventViewModel()

    /// Monitors network connectivity status for offline mode indication
    /// Provides real-time updates on WiFi/Cellular/Offline state
    @StateObject private var networkMonitor = NetworkMonitor()

    /// Tracks the currently selected tab index
    /// Allows programmatic navigation between tabs (e.g., from "Add Event" button in Home)
    @State private var selectedTab = 0

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: Home Tab (Index 0)
            /// Displays list of all events with status indicators and quick scanner access
            ManageEventView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)

            // MARK: Logs Tab (Index 1)
            /// Shows scan history grouped by event with expand/collapse functionality
            TixLogsView()
                .tabItem {
                    Image(systemName: "chart.line.text.clipboard")
                    Text("Logs")
                }
                .tag(1)

            // MARK: Add Event Tab (Index 2)
            /// Event creation form - switches back to Home tab after successful creation
            CreateEventView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "plus")
                    Text("Add Event")
                }
                .tag(2)

            // MARK: Upgrade Tab (Index 4)
            /// Premium features and subscription management
            /// TODO: Implement monetisation strategy
            /// Options being considered:
            /// - Ticket/event limits with paid tiers ($14.99/month or $249 lifetime)
            /// - Consider moving into Account tab as sub-menu
            ShopView()
                .tabItem {
                    Image(systemName: "bag")
                    Text("Upgrade")
                }
                .tag(4)

            // MARK: Account Tab (Index 3)
            /// User profile, settings, and app information
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Account")
                }
                .tag(3)
        }
        // Inject shared view models into environment for all child views
        .environmentObject(eventViewModel)
        .environmentObject(networkMonitor)
        // Apply app's primary accent color to tab bar and interactive elements
        .accentColor(Color(.cyan))
    }
}

// MARK: - Preview

#Preview {
    TixTabView()
        .environmentObject(AuthViewModel())
}
