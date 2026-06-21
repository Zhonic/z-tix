//
//  LogViewModel.swift
//  Z-Tix
//
//  Created by Harnish Patel on 29/10/2025.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Log View Model

/// View model managing scan log data with offline-first architecture
/// Implements local-first pattern for instant UI updates
/// Features:
/// - Local scan display before Firestore sync
/// - Deduplication of local vs synced scans
/// - Timeout protection for network calls
/// - Expand/collapse state management
@MainActor
class LogViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Dictionary mapping event IDs to their scan logs
    /// Key: Event ID, Value: Array of scans (sorted newest first)
    @Published var scansByEvent: [String: [TicketScan]] = [:]

    /// Loading state for showing progress indicators
    /// True during Firestore fetch operations
    @Published var isLoading = false

    /// Set of event IDs that are currently expanded to show all logs
    /// Events not in this set show only top 10 logs
    @Published var expandedEvents: Set<String> = []

    /// Local scans for instant display before Firestore sync
    /// Populated from TicketViewModel's recent scans
    @Published var localScans: [TicketScan] = []

    // MARK: - Private Properties

    /// Firestore database reference
    private let db = Firestore.firestore()

    // MARK: - Fetch All Logs

    /// Fetch scan logs for all events with local-first pattern
    /// TWO-PHASE LOADING:
    /// 1. INSTANT: Display local scans immediately (no network wait)
    /// 2. BACKGROUND: Fetch from Firestore and merge with local scans
    ///
    /// This provides instant UI updates while ensuring data completeness
    ///
    /// - Parameters:
    ///   - events: Array of events to fetch logs for
    ///   - includeLocal: Recent local scans to display immediately
    func fetchAllLogs(for events: [Event], includeLocal: [TicketScan] = [])
        async
    {
        // Verify user is authenticated
        guard Auth.auth().currentUser?.uid != nil else {
            Logger.error("Failed to fetch logs", "No user logged in", code: 0)
            return
        }

        // MARK: Phase 1 - Show Local Scans Immediately
        /// Display local scans instantly without waiting for network
        /// Provides perceived instant loading for better UX
        if !includeLocal.isEmpty {
            await MainActor.run {
                // Group local scans by event ID
                for event in events {
                    let localScansForEvent = includeLocal.filter {
                        $0.eventId == event.id
                    }

                    // Only update if we have local scans for this event
                    if !localScansForEvent.isEmpty {
                        // Sort newest first
                        scansByEvent[event.id] = localScansForEvent.sorted {
                            $0.scannedAt > $1.scannedAt
                        }
                    }
                }
            }
        }

        // MARK: Phase 2 - Fetch from Firestore in Background
        /// Fetch complete history from Firestore
        /// Merges with local scans and deduplicates
        isLoading = true

        // Fetch logs for each event
        for event in events {
            await fetchLogsForEvent(
                eventId: event.id,
                eventTitle: event.title,
                includeLocal: includeLocal
            )
        }

        isLoading = false
    }

    // MARK: - Fetch Logs for Event

    /// Fetch scan logs for a specific event with timeout protection
    /// Combines Firestore data with local scans and deduplicates
    ///
    /// DEDUPLICATION LOGIC:
    /// - Local scans are added first (instant display)
    /// - Firestore scans are fetched (complete history)
    /// - Duplicates removed by comparing scan IDs
    /// - Final list sorted newest first
    ///
    /// - Parameters:
    ///   - eventId: Event to fetch logs for
    ///   - eventTitle: Event name for logging
    ///   - includeLocal: Recent local scans to merge
    func fetchLogsForEvent(
        eventId: String,
        eventTitle: String,
        includeLocal: [TicketScan] = []
    ) async {
        do {
            // MARK: Timeout-Protected Fetch
            /// 2-second timeout per event prevents indefinite hangs
            /// Shorter than event fetch (5s) as logs are less critical
            let snapshot = try await withTimeout(seconds: 2) {
                try await self.db.collection("ticketScans")
                    .whereField("eventId", isEqualTo: eventId)
                    // source: .default uses cache when offline
                    .getDocuments(source: .default)
            }

            // Parse Firestore documents to TicketScan objects
            let scans = snapshot.documents.compactMap { document in
                try? document.data(as: TicketScan.self)
            }

            // MARK: Local Scans Filtering
            /// Extract local scans that match this event
            let localScansForEvent = includeLocal.filter {
                $0.eventId == eventId
            }

            // MARK: Merge and Deduplicate
            /// Combine Firestore and local scans
            /// Remove duplicates (local scans that synced to Firestore)
            var allScans = scans
            for localScan in localScansForEvent {
                // Only add if not already in Firestore results
                if !allScans.contains(where: { $0.id == localScan.id }) {
                    allScans.append(localScan)
                }
            }

            // MARK: Sort and Store
            /// Always sort in-memory (newest first)
            /// Descending order: most recent scans at top
            allScans.sort { $0.scannedAt > $1.scannedAt }

            // Update published property
            scansByEvent[eventId] = allScans

            // MARK: Data Source Logging
            /// Log whether data came from cache or server
            if snapshot.metadata.isFromCache {
                Logger.warning(
                    "Fetched \(allScans.count) logs for event: \(eventTitle) from CACHE (offline mode) + \(localScansForEvent.count) local"
                )
            } else {
                Logger.success(
                    "Fetched \(allScans.count) logs for event: \(eventTitle) from SERVER + \(localScansForEvent.count) local"
                )
            }

        } catch {
            // MARK: Timeout/Error Fallback
            /// If Firestore fetch fails or times out, keep local scans
            /// This ensures UI still shows recent data even without network
            let localScansForEvent = includeLocal.filter {
                $0.eventId == eventId
            }

            if !localScansForEvent.isEmpty {
                let sorted = localScansForEvent.sorted {
                    $0.scannedAt > $1.scannedAt
                }
                scansByEvent[eventId] = sorted
                Logger.warning(
                    "Using only local scans (\(sorted.count)) for event: \(eventTitle) - Firestore timed out"
                )
            } else {
                // No local scans either - complete failure
                Logger.error(
                    "Failed to fetch logs for event",
                    error.localizedDescription,
                    code: 0
                )
            }
        }
    }

    // MARK: - Helper Methods

    /// Get the first N logs for an event (for collapsed view)
    /// Default: Top 10 most recent scans
    ///
    /// - Parameters:
    ///   - eventId: Event to get logs for
    ///   - limit: Maximum number of logs to return
    /// - Returns: Array of most recent scans up to limit
    func getTopLogs(for eventId: String, limit: Int = 10) -> [TicketScan] {
        return Array((scansByEvent[eventId] ?? []).prefix(limit))
    }

    /// Check if an event has more logs than the display limit
    /// Used to show/hide "Show More" button
    ///
    /// - Parameters:
    ///   - eventId: Event to check
    ///   - limit: Display limit to compare against
    /// - Returns: true if event has more than limit logs
    func hasMoreLogs(for eventId: String, than limit: Int = 10) -> Bool {
        return (scansByEvent[eventId]?.count ?? 0) > limit
    }

    /// Toggle expansion state for an event's log list
    /// Expanded: Shows all logs
    /// Collapsed: Shows top 10 logs
    ///
    /// - Parameter eventId: Event to toggle
    func toggleEventExpansion(for eventId: String) {
        if expandedEvents.contains(eventId) {
            expandedEvents.remove(eventId)
        } else {
            expandedEvents.insert(eventId)
        }
    }

    // MARK: - Timeout Helper

    /// Wraps an async operation with a timeout
    /// Same implementation as EventViewModel for consistency
    /// Prevents indefinite hangs from network issues
    ///
    /// - Parameters:
    ///   - seconds: Maximum time to wait
    ///   - operation: Async operation to execute
    /// - Returns: Result of operation if completed in time
    /// - Throws: Operation error or timeout error
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in

            // Add actual operation task
            group.addTask {
                try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(
                    nanoseconds: UInt64(seconds * 1_000_000_000)
                )
                throw NSError(
                    domain: "Timeout",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Operation timed out"]
                )
            }

            // Return first completed task
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
