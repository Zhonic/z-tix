//
//  Event.swift
//  Z-Tix
//
//  Created by Harnish Patel on 20/10/2025.
//

// MARK: - Event Model

/// Core event data model representing a ticketed event
/// Stored in Firestore at: /events/{eventId}
///
/// RELATIONSHIPS:
/// - Belongs to OrganiserUser (one-to-many)
/// - Has many Tickets (one-to-many) in subcollection
/// - Has many TicketScans (one-to-many) via eventId
///
/// FIRESTORE STRUCTURE:
/// events/
///   {eventId}/
///     - id, organiserId, title, description, date, time, address
///     tickets/  (subcollection)
///       {ticketId}/
///         - ticketCode, attendeeName, status, etc.
///
/// PROTOCOL CONFORMANCES:
/// - Identifiable: SwiftUI list/ForEach support
/// - Codable: Firestore encoding/decoding
/// - Hashable: Set operations and comparison
import Foundation

struct Event: Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique event identifier (Firestore document ID)
    /// Generated as UUID string on creation
    let id: String

    /// User ID of event organiser (Firebase Auth UID)
    /// Links event to creator for permissions and queries
    let organiserId: String

    /// Event name displayed in UI
    /// Example: "Summer Music Festival 2025"
    let title: String

    /// Detailed event description
    /// Shown in event details view
    let description: String

    /// Event date (day/month/year only)
    /// Stored separately from time for date picker UX
    /// Combined with time via dateTime computed property
    let date: Date

    /// Event time (hour/minute only)
    /// Stored separately from date for time picker UX
    /// Combined with date via dateTime computed property
    let time: Date

    /// Event venue address
    /// Populated by Google Places API autocomplete
    /// Example: "123 Superhero Club, Stark City, Marvel, Universe"
    let address: String

    // MARK: - Computed Properties

    /// Combined date and time as single Date object
    /// Used for sorting events chronologically
    /// Used for determining if event is past/future
    ///
    /// ALGORITHM:
    /// 1. Extract date components (year, month, day) from date
    /// 2. Extract time components (hour, minute) from time
    /// 3. Combine into single DateComponents
    /// 4. Convert back to Date
    ///
    /// FALLBACK: Returns date if combination fails (should never happen)
    ///
    /// Example:
    /// - date: 2025-12-25 (any time)
    /// - time: (any date) 19:30
    /// - dateTime: 2025-12-25 19:30
    var dateTime: Date {
        let calendar = Calendar.current

        // Extract date components (year, month, day)
        let dateComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        // Extract time components (hour, minute)
        let timeComponents = calendar.dateComponents(
            [.hour, .minute],
            from: time
        )

        // Combine components
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        // Convert to Date (fallback to date if nil)
        return calendar.date(from: combined) ?? date
    }
}

// MARK: - Mock Data

extension Event {

    /// Mock event for previews and testing
    /// Prevents need for Firebase connection in development
    static var MOCK_EVENT = Event(
        id: NSUUID().uuidString,
        organiserId: "mock-user-id",
        title: "Harnish's Party",
        description: "This is Harnish's party and it's going to be the best.",
        date: Date(),
        time: Date(),
        address: "24 Spectrum Crescent, Clyde North, VIC, 3978"
    )

    /// Array of mock events for list previews
    /// All same event for simplicity
    static let events = [MOCK_EVENT, MOCK_EVENT, MOCK_EVENT, MOCK_EVENT]
}

// MARK: - Usage Notes

/*
 LIFECYCLE:
 1. User creates event in CreateEventView
 2. EventViewModel.createEvent() saves to Firestore
 3. Event appears in ManageEventView list
 4. User can edit via CreateEventView (edit mode)
 5. User can delete via EventViewModel.deleteEvent()

 FIRESTORE QUERIES:
 - Fetch user's events: .whereField("organiserId", isEqualTo: userId)
 - Sort chronologically: .order(by: "date") or sort in-memory
 - Limit to active: Filter by dateTime > Date()

 DATE/TIME STORAGE:
 Why separate date and time properties?
 - Better UX: Separate pickers for date and time
 - Simpler validation: Date must be future, time is independent
 - Common pattern: Many ticket platforms use separate fields

 Alternative: Single dateTime property
 - Pros: Simpler data model, one field
 - Cons: More complex pickers, harder validation
 - Decision: Current approach prioritises UX

 CASCADE DELETE:
 When event is deleted:
 1. Delete all tickets in subcollection
 2. Delete all scan logs (separate collection)
 3. Delete event document
 See: EventViewModel.deleteEvent() for implementation

 FUTURE ENHANCEMENTS:
 - Add status enum (draft/published/cancelled/completed)
 - Add capacity/maxTickets field
 - Add category (concert/sports/conference)
 - Add imageURL for event poster
 - Add ticketSales (current sold count)
 */
