//
//  ManageEventView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 20/10/2025.
//

import SwiftUI

// MARK: - Manage Event View

/// Main home screen displaying all user events
/// Features: Event list, ticket status indicators, quick scanner access, empty state
/// Serves as primary navigation hub for event management
struct ManageEventView: View {

    // MARK: - Environment Objects

    /// Shared event view model for fetching and managing events
    @EnvironmentObject private var eventViewModel: EventViewModel

    /// Network monitor for displaying online/offline status
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    /// Ticket view model for checking ticket import status
    @StateObject private var ticketViewModel = TicketViewModel()

    // MARK: - Navigation Properties

    /// Binding to parent tab selection for programmatic navigation
    /// Allows switching to "Add Event" tab from empty state or toolbar
    @Binding var selectedTab: Int

    /// Event selected for scanning - triggers navigation to scanner
    @State private var selectedEventForScanning: Event?

    /// Event selected for editing - triggers navigation to edit form
    @State private var selectedEventForEditing: Event?

    // MARK: - State Properties

    /// Dictionary mapping event IDs to their ticket status
    /// Updated asynchronously after fetching events
    @State private var eventTicketStatuses: [String: EventTicketStatus] = [:]

    /// Controls display of "no tickets" alert when scanner is tapped
    @State private var showNoTicketsAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {

            // MARK: Main Content
            /// Shows loading, empty state, or events list based on data state
            ZStack {
                if eventViewModel.isLoading {
                    // Loading spinner while fetching events
                    ProgressView("Loading events...")

                } else if eventViewModel.events.isEmpty {
                    // Empty state encourages creating first event
                    emptyStateView

                } else {
                    // List of all events with status indicators
                    eventsList
                }
            }
            .navigationTitle("My Events")

            // MARK: Toolbar Items
            .toolbar {

                // MARK: Network Status Indicator (Leading)
                /// Shows offline badge when no internet connection
                /// Informs user that offline mode is active
                ToolbarItem(placement: .navigationBarLeading) {
                    if !networkMonitor.isConnected {
                        HStack(spacing: 4) {
                            Image(systemName: "wifi.slash")
                                .font(.caption2)
                            Text("Offline")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                }

                // MARK: Add Event Button (Trailing)
                /// Plus button navigates to "Add Event" tab
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedTab = 2  // Switch to Add Event tab
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // MARK: Navigation Destinations
            /// Programmatic navigation triggered by state changes
            .navigationDestination(item: $selectedEventForScanning) { event in
                TixScannerView(event: event)
            }
            .navigationDestination(item: $selectedEventForEditing) { event in
                CreateEventView(eventToEdit: event)
            }

            // MARK: Lifecycle Events
            /// Fetch events and ticket statuses when view appears
            .task {
                await eventViewModel.fetchEvents()
                await checkTicketStatusForAllEvents()
            }

            /// Pull-to-refresh functionality
            .refreshable {
                await eventViewModel.fetchEvents()
                await checkTicketStatusForAllEvents()
            }

            /// Refresh ticket statuses when returning to view
            /// Important: Ticket status may have changed after importing
            .onAppear {
                //Refresh statuses when returning to this view
                Task {
                    await checkTicketStatusForAllEvents()
                }
            }

            // MARK: Alerts

            /// General error alerts from event operations
            .alert(item: $eventViewModel.alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: alertItem.dismissButton
                )
            }

            /// Specific alert when user tries to scan without importing tickets
            .alert("No Tickets Imported", isPresented: $showNoTicketsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "Please import tickets for this event before scanning. Go to event details and tap 'Import Tickets'."
                )
            }
        }
    }

    // MARK: - Empty State View

    /// Displayed when user has no events yet
    /// Encourages creating first event with friendly messaging and CTA
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            // Friendly message
            Text("You host no events, that's a bummer 😔")
                .font(.title3)
                .fontWeight(.semibold)

            // Encouraging subtext
            Text("So what are you waiting for...add an event now!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Call-to-action button
            Button {
                selectedTab = 2  // Navigate to Add Event tab
            } label: {
                ZTixButton(
                    title: "Create Your First Event",
                    foregroundColour: .white,
                    backgroundColour: .cyan,
                    opacity: 1
                )
            }
            .padding(.top, 20)
        }
        .padding()
    }

    // MARK: - Events List View

    /// Main list displaying all user events
    /// Each cell is tappable for editing and has scanner quick action
    private var eventsList: some View {
        List {
            ForEach(eventViewModel.events) { event in
                EventListCell(
                    event: event,
                    ticketStatus: eventTicketStatuses[event.id] ?? .notImported,
                    onScanTapped: {
                        handleScanTap(for: event)
                    },
                    onCellTapped: {
                        selectedEventForEditing = event
                    }
                )
                .buttonStyle(.plain)  // Prevents default list row highlighting
            }
        }
        .refreshable {
            await eventViewModel.fetchEvents()
            await checkTicketStatusForAllEvents()
        }
    }

    // MARK: - Helper Methods

    /// Check ticket import status for all events
    /// Queries Firestore for ticket counts and updates status dictionary
    /// Called after fetching events and when view appears
    private func checkTicketStatusForAllEvents() async {
        // Build status dictionary off main thread
        var tempDict: [String: EventTicketStatus] = [:]

        // Query ticket status for each event
        for event in eventViewModel.events {
            let status = await ticketViewModel.getTicketStatus(for: event.id)
            tempDict[event.id] = status
        }

        // Update UI on main thread
        await MainActor.run {
            eventTicketStatuses = tempDict
        }
    }

    /// Handle scanner button tap with ticket validation
    /// Only navigates to scanner if tickets are imported
    /// Shows helpful alert if tickets not yet imported
    ///
    /// - Parameter event: The event whose scanner button was tapped
    private func handleScanTap(for event: Event) {
        let status = eventTicketStatuses[event.id] ?? .notImported

        if status.hasTickets {
            // Tickets are imported - navigate to scanner
            selectedEventForScanning = event
        } else {
            // No tickets - show helpful alert
            showNoTicketsAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    ManageEventView(selectedTab: .constant(0))
        .environmentObject(EventViewModel())
        .environmentObject(NetworkMonitor())
}
