//
//  TixLogsView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import Combine
import SwiftUI

// MARK: - Ticket Logs View

/// Displays comprehensive scan history for all events
/// Features:
/// - Real-time updates via NotificationCenter
/// - Offline mode indicator with sync count
/// - Expand/collapse for long log lists
/// - Empty states for guidance
/// - Pull-to-refresh functionality
struct TixLogsView: View {

    // MARK: - Environment Objects

    /// Event view model for accessing user's events
    @EnvironmentObject var eventViewModel: EventViewModel

    /// Network monitor for offline/online status display
    @EnvironmentObject var networkMonitor: NetworkMonitor

    /// Log view model managing scan log data
    @StateObject private var logViewModel = LogViewModel()

    /// Ticket view model for accessing recent local scans
    /// Provides instant display before Firestore sync completes
    @StateObject private var ticketViewModel = TicketViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {

            // MARK: Main Content
            /// Conditional content based on data availability
            Group {
                if eventViewModel.events.isEmpty {
                    // No events exist yet
                    emptyEventsView

                } else if logViewModel.scansByEvent.isEmpty
                    || logViewModel.scansByEvent.values.allSatisfy({
                        $0.isEmpty
                    })
                {
                    // Events exist but no scans yet
                    if logViewModel.isLoading {
                        ProgressView("Loading logs...")
                    } else {
                        noLogsView
                    }
                } else {
                    // Show log list grouped by event
                    logsListView
                }
            }
            .navigationTitle("Ticket Logs")

            // MARK: Toolbar
            .toolbar {

                // MARK: Network Status (Leading)
                /// Shows offline indicator when not connected
                ToolbarItem(placement: .navigationBarLeading) {
                    // Network status indicator
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

                // MARK: Loading Indicator (Trailing)
                /// Shows spinner while syncing with Firestore
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Show loading indicator when syncing
                    if logViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }

            // MARK: Lifecycle Events

            /// Initial load when view appears
            .task {
                // Initial load
                await loadLogs()
            }

            /// Pull-to-refresh manual reload
            .refreshable {
                // Manual refresh
                await loadLogs()
            }

            /// Refresh when navigating back to this tab
            /// Important: Logs may have changed after scanning
            .onAppear {
                // Refresh when view appears
                Task {
                    await loadLogs()
                }
            }

            // MARK: Real-Time Updates
            /// Listen for scan completion notifications
            /// Triggered by TixScannerView after successful scan
            /// Provides instant log updates without manual refresh
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSNotification.Name("ScanCompleted")
                )
            ) { _ in
                Task {
                    await loadLogs()
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Load logs with local scans for instant display
    /// LOCAL-FIRST PATTERN:
    /// 1. Show local scans immediately (instant UI)
    /// 2. Fetch from Firestore in background (full history)
    /// 3. Merge and deduplicate results
    private func loadLogs() async {
        await logViewModel.fetchAllLogs(
            for: eventViewModel.events,
            includeLocal: ticketViewModel.recentScans
        )
    }

    // MARK: - Empty Events View

    /// Displayed when user has no events created yet
    /// Guides user to create their first event
    private var emptyEventsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Events Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Create an event first to start scanning tickets")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - No Logs View

    /// Displayed when events exist but no tickets scanned yet
    /// Encourages user to start scanning
    private var noLogsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Scans Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Start scanning tickets to see logs here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Logs List View

    /// Main list displaying all scan logs grouped by event
    /// Features: Offline indicator, expand/collapse, timestamp display
    private var logsListView: some View {
        List {

            // MARK: Offline Sync Banner
            /// Shows pending scan count when offline
            /// Informs user that scans will sync when connection returns
            if !networkMonitor.isConnected
                && !ticketViewModel.recentScans.isEmpty
            {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.slash")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Offline Mode")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text(
                                "\(ticketViewModel.recentScans.count) scan(s) will sync when online"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // MARK: Event Sections
            /// Group logs by event with collapsible sections
            ForEach(eventViewModel.events) { event in
                let logs = logViewModel.scansByEvent[event.id] ?? []

                // Only show section if event has logs
                if !logs.isEmpty {
                    Section {
                        // Check if this event is expanded
                        let isExpanded = logViewModel.expandedEvents.contains(
                            event.id
                        )

                        // Show top 10 or all logs based on expansion state
                        let displayLogs =
                            isExpanded
                            ? logs : logViewModel.getTopLogs(for: event.id)

                        // MARK: Log Rows
                        /// Display each scan log with status, timestamp, and attendee
                        ForEach(displayLogs) { scan in
                            LogRowView(scan: scan)
                        }

                        // MARK: Show More/Less Button
                        /// Appears when event has more than 10 logs
                        /// Toggles between showing top 10 and all logs
                        if logViewModel.hasMoreLogs(for: event.id) {
                            Button {
                                logViewModel.toggleEventExpansion(for: event.id)
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(
                                        isExpanded
                                            ? "Show Less"
                                            : "Show More (\(logs.count - 10) more)"
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.cyan)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        // MARK: Section Header
                        /// Shows event name and total scan count
                        HStack {
                            Text(event.title)
                            Spacer()
                            Text("\(logs.count) scans")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Log Row View

/// Individual scan log entry displaying scan details
/// Shows: Status icon, ticket code, attendee name, timestamp
struct LogRowView: View {

    /// The ticket scan to display
    let scan: TicketScan

    var body: some View {
        HStack(spacing: 12) {

            // MARK: Status Icon
            /// Color-coded icon indicating scan result
            /// Green checkmark: Success
            /// Orange warning: Already scanned
            /// Red X: Not found or error
            Image(systemName: scan.status.icon)
                .foregroundColor(scan.status.color)
                .font(.title3)

            // MARK: Scan Details
            VStack(alignment: .leading, spacing: 4) {

                // Ticket Code (Primary identifier)
                Text(scan.ticketCode)
                    .font(.headline)

                // Attendee Name (Optional)
                /// Only shown if ticket has attendee information
                if let name = scan.attendeeName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // MARK: Status and Timestamp Row
                /// Shows scan status, time, and date in compact format
                HStack {
                    // Status text (Success, Already Scanned, etc.)
                    Text(scan.status.displayName)
                        .font(.caption)
                        .foregroundColor(scan.status.color)

                    // Bullet separator
                    Text("•")
                        .foregroundColor(.secondary)

                    // Time (HH:MM AM/PM)
                    Text(scan.scannedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Date (MMM DD, YYYY)
                    Text(scan.scannedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    TixLogsView()
        .environmentObject(EventViewModel())
}
