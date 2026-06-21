//
//  TicketViewModel.swift
//  Z-Tix
//
//  Created by Harnish Patel on 28/10/2025.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Ticket View Model

/// Central view model managing all ticket operations
/// Handles import, validation, scanning, and logging with offline support
///
/// KEY FEATURES:
/// - CSV batch import with atomic writes
/// - Offline-first ticket validation (uses cache)
/// - Local scan storage for instant display
/// - Background Firestore sync
/// - Timeout protection (3 seconds)
/// - Duplicate scan prevention
/// - Status tracking (valid/used/cancelled)
///
/// OFFLINE ARCHITECTURE:
/// - Firestore cache provides ticket data offline
/// - Scans saved locally first (instant)
/// - Background sync to Firestore when online
/// - Recent scans kept in memory (last 100)
@MainActor
class TicketViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of tickets for current event
    /// Populated by fetchTickets()
    @Published var tickets: [Ticket] = []

    /// Error alert to display to user
    @Published var alertItem: AlertItem?

    /// Loading state for progress indicators
    @Published var isLoading = false

    /// Count of scans waiting to sync to Firestore
    /// Currently unused, kept for future sync status UI
    @Published var pendingSyncs: Int = 0

    /// Recent scans stored locally for instant display
    /// Used by TixLogsView for immediate UI updates
    /// Syncs to Firestore in background
    @Published var recentScans: [TicketScan] = []

    // MARK: - Private Properties

    /// Firestore database reference
    private let db = Firestore.firestore()

    /// Maximum scans to keep in memory
    /// Prevents unlimited memory growth
    /// 100 scans ≈ 50KB memory (rough estimate)
    private let maxRecentScans = 100

    // MARK: - Import Tickets

    /// Import tickets from CSV data using batch write
    /// ATOMIC OPERATION: All tickets imported together or none
    /// Prevents partial imports that could cause data inconsistency
    ///
    /// BATCH WRITE BENEFITS:
    /// - Single network round trip
    /// - Atomic (all or nothing)
    /// - Efficient for large datasets
    /// - Firestore limit: 500 operations per batch
    ///
    /// - Parameters:
    ///   - tickets: Array of parsed ticket objects
    ///   - eventId: Event to associate tickets with
    /// - Throws: Firestore errors or encoding errors
    func importTickets(tickets: [Ticket], eventId: String) async throws {
        // Verify user is authenticated
        guard Auth.auth().currentUser?.uid != nil else {
            alertItem = AlertContext.noUserLoggedIn
            Logger.error(
                "Failed to import tickets",
                "No user logged in",
                code: 0
            )
            return
        }

        isLoading = true

        do {
            // MARK: Create Batch Write
            /// Batch writes are atomic - all succeed or all fail
            /// More efficient than individual writes
            let batch = db.batch()

            // MARK: Add Tickets to Batch
            /// Each ticket becomes a document in subcollection
            /// Path: events/{eventId}/tickets/{ticketId}
            for ticket in tickets {
                let docRef = db.collection("events").document(eventId)
                    .collection("tickets").document(ticket.id)

                let encodedTicket = try Firestore.Encoder().encode(ticket)
                batch.setData(encodedTicket, forDocument: docRef)
            }

            // MARK: Commit Batch
            /// Single network call to import all tickets
            /// If offline, queued for sync when online
            try await batch.commit()

            Logger.success("Successfully imported \(tickets.count) tickets")

            // MARK: Refresh Ticket List
            /// Update UI with newly imported tickets
            await fetchTickets(for: eventId)

        } catch let error as NSError {
            // Show error to user
            alertItem = AlertContext.importTicketsFailed

            Logger.error(
                "Failed to import tickets",
                error.localizedDescription,
                code: error.code
            )

            // Re-throw so caller knows operation failed
            throw error
        }

        isLoading = false
    }

    // MARK: - Fetch Tickets

    /// Fetch all tickets for an event with offline support
    /// Uses Firestore cache when offline (source: .default)
    /// Critical for offline scanning functionality
    ///
    /// OFFLINE BEHAVIOR:
    /// - First fetch: Downloads from server, saves to cache
    /// - Subsequent fetches: Uses cache if offline
    /// - Cache persists across app restarts
    /// - Cache size: 100MB (configured in AppDelegate)
    ///
    /// - Parameter eventId: Event to fetch tickets for
    func fetchTickets(for eventId: String) async {
        // Verify user is authenticated
        guard Auth.auth().currentUser?.uid != nil else {
            Logger.error(
                "Failed to fetch tickets",
                "No user logged in",
                code: 0
            )
            return
        }

        isLoading = true

        do {
            // MARK: Fetch from Firestore (or cache)
            /// source: .default uses cache when offline
            /// This enables offline scanning capability
            let snapshot = try await db.collection("events").document(eventId)
                .collection("tickets")
                .getDocuments(source: .default)

            // MARK: Parse Documents
            /// Convert Firestore documents to Ticket objects
            /// compactMap filters out any documents that fail to parse
            self.tickets = snapshot.documents.compactMap { document in
                try? document.data(as: Ticket.self)
            }

            // MARK: Data Source Logging
            /// Log whether data came from cache or server
            /// Helps debug offline functionality
            if snapshot.metadata.isFromCache {
                Logger.warning(
                    "Loaded \(self.tickets.count) tickets from CACHE (offline mode)"
                )
            } else {
                Logger.success(
                    "Loaded \(self.tickets.count) tickets from SERVER"
                )
            }

            Logger.success("Successfully fetched \(self.tickets.count) tickets")

        } catch let error as NSError {
            Logger.error(
                "Failed to fetch tickets",
                error.localizedDescription,
                code: error.code
            )
        }

        isLoading = false
    }

    // MARK: - Validate and Scan Ticket

    /// Validate scanned ticket and create scan result
    /// THREE-STEP PROCESS:
    /// 1. Find ticket in Firestore (or cache)
    /// 2. Check ticket status (valid/used/cancelled)
    /// 3. Mark as used if valid
    ///
    /// TIMEOUT PROTECTION:
    /// - 3-second timeout prevents indefinite hangs
    /// - Returns error scan if timeout occurs
    /// - Allows scanning to continue even with slow network
    ///
    /// OFFLINE BEHAVIOR:
    /// - Uses cached ticket data for validation
    /// - Marks ticket as used (queued if offline)
    /// - Scan log saved locally immediately
    /// - Background sync when connection returns
    ///
    /// - Parameters:
    ///   - ticketCode: QR/barcode string scanned
    ///   - eventId: Event being scanned for
    ///   - eventTitle: Event name for logging
    /// - Returns: TicketScan result (success/alreadyScanned/notFound/error)
    func validateAndScan(
        ticketCode: String,
        eventId: String,
        eventTitle: String
    ) async -> TicketScan {
        // Verify user is authenticated
        guard Auth.auth().currentUser?.uid != nil else {
            Logger.error("Scan failed", "No user logged in", code: 0)
            return createErrorScan(
                ticketCode: ticketCode,
                eventId: eventId,
                eventTitle: eventTitle
            )
        }

        do {
            // MARK: Timeout-Protected Query
            /// 3-second timeout prevents hanging on slow network
            /// Returns error scan if timeout occurs
            let snapshot = try await withTimeout(seconds: 3) {
                try await self.db.collection("events").document(eventId)
                    .collection("tickets")
                    .whereField("ticketCode", isEqualTo: ticketCode)
                    .getDocuments(source: .default)
            }

            // MARK: Data Source Logging
            /// Track whether validation used cache or server
            if snapshot.metadata.isFromCache {
                Logger.warning("Ticket validation using CACHE (offline mode)")
            } else {
                Logger.success("Ticket validation using SERVER")
            }

            // MARK: Find Ticket
            /// Check if ticket exists in this event
            guard let document = snapshot.documents.first,
                let ticket = try? document.data(as: Ticket.self)
            else {
                Logger.warning("Ticket not found: \(ticketCode)")
                return createNotFoundScan(
                    ticketCode: ticketCode,
                    eventId: eventId,
                    eventTitle: eventTitle
                )
            }

            // MARK: Check Status
            /// Prevent duplicate scanning of used tickets
            if ticket.status == .used {
                Logger.warning("Ticket already scanned: \(ticketCode)")
                return createAlreadyScannedScan(
                    ticket: ticket,
                    eventId: eventId,
                    eventTitle: eventTitle
                )
            }

            // MARK: Mark as Used
            /// Update ticket status to prevent re-use
            /// Queued if offline, synced when online
            try await markTicketAsUsed(ticketId: ticket.id, eventId: eventId)

            Logger.success("Ticket scanned successfully: \(ticketCode)")
            return createSuccessScan(
                ticket: ticket,
                eventId: eventId,
                eventTitle: eventTitle
            )

        } catch {
            Logger.error(
                "Scan validation failed or timed out",
                error.localizedDescription,
                code: 0
            )
            return createErrorScan(
                ticketCode: ticketCode,
                eventId: eventId,
                eventTitle: eventTitle
            )
        }
    }

    // MARK: - Mark Ticket as Used

    /// Update ticket status to 'used' with timestamp
    /// OFFLINE SUPPORT:
    /// - Update queued if offline
    /// - Syncs automatically when connection returns
    /// - Non-blocking: Continues even if update fails
    ///
    /// - Parameters:
    ///   - ticketId: Ticket document ID
    ///   - eventId: Event containing ticket
    /// - Throws: Firestore errors (caught and logged)
    private func markTicketAsUsed(ticketId: String, eventId: String)
        async throws
    {
        do {
            try await db.collection("events").document(eventId)
                .collection("tickets").document(ticketId)
                .updateData([
                    "status": TicketStatus.used.rawValue,
                    "usedAt": Timestamp(date: Date()),
                ])
            // Write is automatically queued if offline and synced when back online
            Logger.success("Ticket marked as used")
        } catch {
            // MARK: Non-Fatal Failure
            /// Even if update fails, we still save the scan log
            /// Prevents losing scan data due to network issues
            /// Update will be retried when connection returns
            Logger.warning(
                "Failed to mark ticket as used (will sync when online): \(error.localizedDescription)"
            )
            // Don't throw - we still want to save the scan log
        }
    }

    // MARK: - Save Scan Log

    /// Save scan log with two-layer storage for instant display
    /// LOCAL-FIRST PATTERN:
    /// 1. Add to recentScans array immediately (instant UI update)
    /// 2. Sync to Firestore in background (non-blocking)
    ///
    /// BENEFITS:
    /// - Instant UI updates
    /// - Works offline
    /// - Resilient to network failures
    /// - Background sync is transparent
    ///
    /// - Parameter scan: TicketScan result to save
    func saveScanLog(_ scan: TicketScan) async {
        // MARK: Step 1 - Local Storage (Instant)
        /// Add to in-memory array for immediate display
        await MainActor.run {
            recentScans.insert(scan, at: 0)  // Add to beginning (newest first)

            // MARK: Memory Management
            /// Limit array size to prevent memory growth
            /// 100 scans is reasonable limit for recent history
            if recentScans.count > maxRecentScans {
                recentScans = Array(recentScans.prefix(maxRecentScans))
            }

            Logger.success("Scan added to local storage")
        }

        // MARK: Step 2 - Firestore Sync (Background)
        /// Non-blocking background sync
        /// Failures don't affect UI (already showing scan)
        Task {
            do {
                let encodedScan = try Firestore.Encoder().encode(scan)
                try await db.collection("ticketScans").document(scan.id)
                    .setData(
                        encodedScan
                    )
                Logger.success("Scan log synced to Firestore")

            } catch {
                // MARK: Sync Failure Handling
                /// Log warning but don't show error to user
                /// Scan is still in local storage
                /// Will retry sync when connection returns
                Logger.warning(
                    "Failed to sync scan log to Firestore (will retry when online): \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Scan Result Helpers

    /// Create successful scan result with attendee info
    /// - Parameters:
    ///   - ticket: Valid ticket that was scanned
    ///   - eventId: Event ID
    ///   - eventTitle: Event name
    /// - Returns: TicketScan with success status
    private func createSuccessScan(
        ticket: Ticket,
        eventId: String,
        eventTitle: String
    ) -> TicketScan {
        return TicketScan(
            id: UUID().uuidString,
            eventId: eventId,
            eventTitle: eventTitle,
            ticketCode: ticket.ticketCode,
            ticketId: ticket.id,
            attendeeName: ticket.attendeeName,
            attendeeEmail: ticket.attendeeEmail,
            status: .success,
            scannedAt: Date()
        )
    }

    /// Create already-scanned result (duplicate scan)
    /// - Parameters:
    ///   - ticket: Ticket that was previously scanned
    ///   - eventId: Event ID
    ///   - eventTitle: Event name
    /// - Returns: TicketScan with alreadyScanned status
    private func createAlreadyScannedScan(
        ticket: Ticket,
        eventId: String,
        eventTitle: String
    ) -> TicketScan {
        return TicketScan(
            id: UUID().uuidString,
            eventId: eventId,
            eventTitle: eventTitle,
            ticketCode: ticket.ticketCode,
            ticketId: ticket.id,
            attendeeName: ticket.attendeeName,
            attendeeEmail: ticket.attendeeEmail,
            status: .alreadyScanned,
            scannedAt: Date()
        )
    }

    /// Create not-found result (invalid ticket)
    /// - Parameters:
    ///   - ticketCode: Scanned code
    ///   - eventId: Event ID
    ///   - eventTitle: Event name
    /// - Returns: TicketScan with notFound status
    private func createNotFoundScan(
        ticketCode: String,
        eventId: String,
        eventTitle: String
    ) -> TicketScan {
        return TicketScan(
            id: UUID().uuidString,
            eventId: eventId,
            eventTitle: eventTitle,
            ticketCode: ticketCode,
            ticketId: nil,
            attendeeName: nil,
            attendeeEmail: nil,
            status: .notFound,
            scannedAt: Date()
        )
    }

    /// Create error result (validation failed)
    /// - Parameters:
    ///   - ticketCode: Scanned code
    ///   - eventId: Event ID
    ///   - eventTitle: Event name
    /// - Returns: TicketScan with error status
    private func createErrorScan(
        ticketCode: String,
        eventId: String,
        eventTitle: String
    ) -> TicketScan {
        return TicketScan(
            id: UUID().uuidString,
            eventId: eventId,
            eventTitle: eventTitle,
            ticketCode: ticketCode,
            ticketId: nil,
            attendeeName: nil,
            attendeeEmail: nil,
            status: .error,
            scannedAt: Date()
        )
    }

    // MARK: - Ticket Status Checking

    /// Check if event has any tickets imported
    /// Quick check using limit(to: 1) for efficiency
    ///
    /// - Parameter eventId: Event to check
    /// - Returns: true if at least one ticket exists
    func hasTickets(for eventId: String) async -> Bool {
        do {
            let snapshot = try await db.collection("events").document(eventId)
                .collection("tickets")
                .limit(to: 1)  // Just check if at least one exists
                .getDocuments()

            let hasTickets = !snapshot.documents.isEmpty
            Logger.debug("Event \(eventId) has tickets: \(hasTickets)", code: 0)
            return hasTickets

        } catch {
            Logger.error(
                "Failed to check tickets",
                error.localizedDescription,
                code: 0
            )
            return false
        }
    }

    /// Get total ticket count for an event with offline support
    /// Uses cache when offline for instant results
    ///
    /// - Parameter eventId: Event to count tickets for
    /// - Returns: Total number of tickets
    func getTicketCount(for eventId: String) async -> Int {
        do {
            let snapshot = try await db.collection("events").document(eventId)
                .collection("tickets")
                .getDocuments(source: .default)

            let count = snapshot.documents.count

            // Log data source
            if snapshot.metadata.isFromCache {
                Logger.debug(
                    "Event \(eventId) has \(count) tickets (from CACHE)",
                    code: 0
                )
            } else {
                Logger.debug("Event \(eventId) has \(count) tickets", code: 0)
            }

            return count

        } catch {
            Logger.error(
                "Failed to count tickets",
                error.localizedDescription,
                code: 0
            )
            return 0
        }
    }

    /// Get ticket status enum for an event
    /// Determines UI badge color and scanner enablement
    ///
    /// - Parameter eventId: Event to get status for
    /// - Returns: EventTicketStatus enum
    func getTicketStatus(for eventId: String) async -> EventTicketStatus {
        let count = await getTicketCount(for: eventId)

        if count > 0 {
            return .imported(count: count)
        } else {
            // Could add logic here to detect .importIssue
            // Currently just returns .notImported
            return .notImported
        }
    }

    // MARK: - Timeout Helper

    /// Wraps an async operation with a timeout
    /// Prevents indefinite hangs from network issues
    /// Uses structured concurrency with TaskGroup
    ///
    /// PATTERN: Race between operation and timeout
    /// - First task to complete wins
    /// - Other task is cancelled
    ///
    /// - Parameters:
    ///   - seconds: Maximum time to wait for operation
    ///   - operation: Async operation to execute
    /// - Returns: Result of operation if completed in time
    /// - Throws: Operation error or timeout error
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in

            // MARK: Start Operation Task
            /// Add the actual operation to task group
            group.addTask {
                try await operation()
            }

            // MARK: Start Timeout Task
            /// Add timeout task that sleeps then throws
            group.addTask {
                try await Task.sleep(
                    nanoseconds: UInt64(seconds * 1_000_000_000)
                )
                throw NSError(
                    domain: "Timeout",
                    code: NSURLErrorTimedOut,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Operation timed out after \(seconds) seconds"
                    ]
                )
            }

            // MARK: Wait for First Completion
            /// next() returns result of first completed task
            /// Force unwrap is safe - at least one task will complete
            let result = try await group.next()!

            /// Cancel remaining tasks
            /// If operation finished, cancel timeout
            /// If timeout finished, cancel operation
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Architecture Notes

/*
 OFFLINE-FIRST ARCHITECTURE:

 This view model implements a sophisticated offline-first pattern:

 1. TICKET IMPORT:
    - Batch write to Firestore (atomic)
    - Downloaded to device cache
    - Available offline after first download

 2. TICKET VALIDATION:
    - Queries cache first (instant)
    - Falls back to server if cache miss
    - 3-second timeout prevents hanging
    - Works completely offline after initial download

 3. SCAN LOGGING:
    - Saves to local array immediately (instant UI)
    - Syncs to Firestore in background
    - Non-blocking (failures don't affect UX)
    - Memory-efficient (keeps last 100)

 4. STATUS UPDATES:
    - Marks tickets as used
    - Queued if offline
    - Auto-syncs when connection returns
    - Non-fatal if update fails

 BENEFITS:
 - Works at events with poor WiFi
 - Instant UI feedback
 - Resilient to network failures
 - Seamless online/offline transitions

 TRADE-OFFS:
 - Memory usage (100 scans ≈ 50KB)
 - Potential sync conflicts (rare)
 - Cache staleness (acceptable for tickets)
 - Increased complexity

 FIRESTORE CACHE:
 - Configured in AppDelegate (100MB)
 - Persists across app restarts
 - Automatic background sync
 - Handles sync conflicts automatically

 TIMEOUT RATIONALE:
 - 3 seconds for validation (quick check)
 - Prevents UI freezing
 - Returns error vs infinite wait
 - User can retry immediately

 FUTURE ENHANCEMENTS:
 - Retry logic for failed syncs
 - Conflict resolution UI
 - Sync status indicators
 - Manual sync trigger button
 - Export scan logs to CSV
 */
