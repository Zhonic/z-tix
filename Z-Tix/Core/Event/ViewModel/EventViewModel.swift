//
//  EventViewModel.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Event View Model

/// Central view model managing all event-related operations
/// Handles CRUD operations with Firebase Firestore and offline persistence
/// Implements cascade deletion pattern to maintain data integrity
/// Shared across app via @EnvironmentObject for consistent event data
@MainActor
class EventViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of all events for the current user
    /// Updates trigger UI refresh in event list views
    /// Sorted chronologically by event date
    @Published var events: [Event] = []

    /// Error alert to display to user
    /// Set when operations fail (except minor network issues in offline mode)
    @Published var alertItem: AlertItem?

    /// Loading state for showing progress indicators
    /// True during fetch/create/update/delete operations
    @Published var isLoading = false

    // MARK: - Private Properties

    /// Firestore database reference
    /// Configured with offline persistence in AppDelegate
    private let db = Firestore.firestore()

    // MARK: - Fetch Events

    /// Fetch all events for the current user with offline support
    /// Uses Firestore cache when offline (source: .default)
    /// Gracefully handles network timeouts without showing errors
    ///
    /// Query: events.organiserId == currentUser.uid
    /// Sorted: By event date (chronological)
    func fetchEvents() async {
        // Verify user is authenticated
        guard let userId = Auth.auth().currentUser?.uid else {
            // Print error for debugging
            Logger.error("Failed to fetch events", "No user logged in", code: 0)
            return
        }

        isLoading = true

        do {
            // MARK: Timeout-Protected Fetch
            /// Wrap Firestore query in timeout to prevent indefinite hangs
            /// 5 second timeout is reasonable for event data
            let snapshot = try await withTimeout(seconds: 5) {
                try await self.db.collection("events")
                    .whereField("organiserId", isEqualTo: userId)
                    // source: .default uses cache when offline
                    // This enables offline-first functionality
                    .getDocuments(source: .default)
            }

            // MARK: Parse and Sort Events
            /// Convert Firestore documents to Event objects
            /// compactMap filters out any documents that fail to parse
            self.events = snapshot.documents.compactMap { document in
                try? document.data(as: Event.self)
            }
            // Sort in memory instead of Firestore query
            // This avoids index requirements and works with cache
            .sorted { $0.date < $1.date }

            // MARK: Offline Mode Detection
            /// Log data source for debugging offline behavior
            /// Users see cached data instantly even without internet
            if snapshot.metadata.isFromCache {
                Logger.warning(
                    "Loaded \(self.events.count) events from CACHE (offline mode)"
                )
            } else {
                Logger.success(
                    "Successfully fetched \(self.events.count) events from SERVER"
                )
            }

        } catch let error as NSError {
            Logger.error(
                "Failed to fetch events",
                error.localizedDescription,
                code: error.code
            )

            // MARK: Selective Error Alerting
            /// Only show alerts for serious issues
            /// Network errors and timeouts are common in offline mode
            /// Don't annoy users with errors when cache is working
            if error.code == NSURLErrorNotConnectedToInternet
                || error.code == NSURLErrorTimedOut
            {
                alertItem = AlertContext.fetchEventsFailed
            }
        }

        isLoading = false
    }

    // MARK: - Create Event

    /// Create a new event in Firestore
    /// Generates UUID for event ID and links to current user
    /// Automatically refreshes event list after successful creation
    ///
    /// - Parameters:
    ///   - title: Event name/title
    ///   - description: Event description/details
    ///   - date: Event date (date components only)
    ///   - time: Event time (time components only)
    ///   - address: Venue address (from Google Places)
    /// - Throws: Firestore errors (network, permissions, etc.)
    func createEvent(
        title: String,
        description: String,
        date: Date,
        time: Date,
        address: String
    ) async throws {
        // Verify user is authenticated
        guard let userId = Auth.auth().currentUser?.uid else {
            // Display error to user as alert
            alertItem = AlertContext.noUserLoggedIn

            // Print error for debugging
            Logger.error("Failed to create event", "No user logged in", code: 0)
            return
        }

        isLoading = true

        do {
            // MARK: Create Event Object
            /// Generate unique ID for new event document
            let eventId = UUID().uuidString

            /// Build event object with all required fields
            let event = Event(
                id: eventId,
                organiserId: userId,  // Links event to current user
                title: title,
                description: description,
                date: date,
                time: time,
                address: address
            )

            // MARK: Encode and Upload
            /// Convert Swift object to Firestore-compatible format
            let encodedEvent = try Firestore.Encoder().encode(event)

            /// Upload to Firestore events collection
            /// Document ID = eventId for predictable lookups
            try await db.collection("events").document(eventId).setData(
                encodedEvent
            )

            Logger.success("Successfully created event: \(title)")

            // MARK: Refresh Event List
            /// Fetch events again to include newly created event
            /// Ensures UI shows updated list immediately
            await fetchEvents()

        } catch let error as NSError {
            // Show error to user
            alertItem = AlertContext.createEventFailed

            // Print error for debugging
            Logger.error(
                "Failed to create event",
                error.localizedDescription,
                code: error.code
            )

            // Re-throw so calling code knows operation failed
            throw error
        }

        isLoading = false
    }

    // MARK: - Update Event

    /// Update an existing event in Firestore
    /// Replaces entire document with new data (not a partial update)
    /// Automatically refreshes event list after successful update
    ///
    /// - Parameters:
    ///   - eventId: ID of event to update
    ///   - title: Updated event name/title
    ///   - description: Updated event description
    ///   - date: Updated event date
    ///   - time: Updated event time
    ///   - address: Updated venue address
    /// - Throws: Firestore errors (network, permissions, not found, etc.)
    func updateEvent(
        eventId: String,
        title: String,
        description: String,
        date: Date,
        time: Date,
        address: String
    ) async throws {
        // Verify user is authenticated
        guard let userId = Auth.auth().currentUser?.uid else {
            alertItem = AlertContext.noUserLoggedIn
            Logger.error(
                "Failed to update event",
                "No user logged in",
                code: 0
            )
            return
        }

        isLoading = true

        do {
            // MARK: Create Updated Event Object
            /// Build complete event object with updated fields
            /// Uses same eventId to replace existing document
            let event = Event(
                id: eventId,
                organiserId: userId,
                title: title,
                description: description,
                date: date,
                time: time,
                address: address
            )

            // Encode to Firestore format
            let encodedEvent = try Firestore.Encoder().encode(event)

            // MARK: Replace Document in Firestore
            /// setData replaces entire document (not merge)
            /// This ensures no stale fields remain from old data
            try await db.collection("events").document(eventId).setData(
                encodedEvent
            )

            Logger.success(
                "Successfully updated event: \(title)"
            )

            // Refresh event list to show updated data
            await fetchEvents()

        } catch let error as NSError {
            // Show error to user
            alertItem = AlertContext.updateEventFailed

            Logger.error(
                "Failed to update event",
                error.localizedDescription,
                code: error.code
            )

            // Re-throw so calling code knows operation failed
            throw error
        }

        isLoading = false

    }

    // MARK: - Delete Event

    /// Delete event with cascade deletion of all related data
    /// Deletion order prevents orphaned records in database
    ///
    /// CASCADE DELETION ORDER:
    /// 1. Tickets (subcollection under event)
    /// 2. Scan logs (separate collection, filtered by eventId)
    /// 3. Event document itself
    ///
    /// Uses batch writes for atomic operations within each step
    ///
    /// - Parameter eventId: ID of event to delete
    func deleteEvent(eventId: String) async {
        // Verify user is authenticated
        guard Auth.auth().currentUser?.uid != nil else {
            // Display error to user as alert
            alertItem = AlertContext.noUserLoggedIn

            // Print error for debugging
            Logger.error(
                "Failed to delete event",
                "No user logged in",
                code: 0
            )
            return
        }

        isLoading = true

        Logger.debug("Starting cascading delete for event: \(eventId)", code: 0)

        do {
            // MARK: Step 1 - Delete Tickets Subcollection
            /// Fetch all tickets under this event
            let ticketsSnapshot = try await db.collection("events")
                .document(eventId)
                .collection("tickets")
                .getDocuments()

            Logger.debug(
                "Found \(ticketsSnapshot.documents.count) tickets to delete",
                code: 0
            )

            /// Use batch write for atomic ticket deletion
            /// All tickets deleted together or none at all
            let ticketBatch = db.batch()
            for ticketDoc in ticketsSnapshot.documents {
                ticketBatch.deleteDocument(ticketDoc.reference)
            }
            try await ticketBatch.commit()
            Logger.success(
                "Successfully deleted \(ticketsSnapshot.documents.count) tickets"
            )

            // MARK: Step 2 - Delete Scan Logs
            /// Fetch all scan logs for this event from separate collection
            /// Scan logs are in root collection, not subcollection
            let scansSnapshot = try await db.collection("ticketScans")
                .whereField("eventId", isEqualTo: eventId)
                .getDocuments()

            Logger.debug(
                "Found \(scansSnapshot.documents.count) scan logs to delete",
                code: 0
            )

            /// Use batch write for atomic scan log deletion
            let scanBatch = db.batch()
            for scanDoc in scansSnapshot.documents {
                scanBatch.deleteDocument(scanDoc.reference)
            }
            try await scanBatch.commit()
            Logger.success(
                "Successfully deleted \(scansSnapshot.documents.count) scan logs"
            )

            // MARK: Step 3 - Delete Event Document
            /// Finally delete the event document itself
            /// This is done last to maintain referential integrity
            try await db.collection("events").document(eventId).delete()
            Logger.success("Successfully deleted event document")

            // MARK: Refresh and Notify
            /// Refresh event list to remove deleted event from UI
            await fetchEvents()

            /// Show success alert to user
            alertItem = AlertContext.eventDeletedSuccessfully

            Logger.success("Cascading delete completed successfully!")

        } catch let error as NSError {
            // Show error to user
            alertItem = AlertContext.deleteEventFailed

            Logger.error(
                "Failed to delete event",
                error.localizedDescription,
                code: error.code
            )
        }

        isLoading = false
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
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Operation timed out"]
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
