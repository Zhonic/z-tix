//
//  Ticket.swift
//  Z-Tix
//
//  Created by Harnish Patel on 28/10/2025.
//

import Foundation

// MARK: - Ticket Model

/// Individual ticket record for event entry
/// Stored in Firestore as subcollection: /events/{eventId}/tickets/{ticketId}
///
/// SUBCOLLECTION RATIONALE:
/// - Tickets belong to specific event
/// - Automatic cleanup when event deleted (cascade)
/// - Query optimisation (tickets always event-specific)
/// - Better data organization
///
/// LIFECYCLE:
/// 1. Created during CSV import
/// 2. Cached locally for offline scanning
/// 3. Status updated when scanned (valid → used)
/// 4. Deleted when event is deleted (cascade)
///
/// RELATIONSHIPS:
/// - Belongs to Event (many-to-one)
/// - Has many TicketScans (one-to-many) via ticketCode
///
/// PROTOCOL CONFORMANCES:
/// - Identifiable: SwiftUI list support
/// - Codable: Firestore encoding/decoding
struct Ticket: Identifiable, Codable {

    // MARK: - Properties

    /// Unique ticket identifier (Firestore document ID)
    /// Generated as UUID string during import
    let id: String

    /// Event this ticket belongs to
    /// Links to parent Event document
    /// Used for cascade deletion
    let eventId: String

    /// Unique ticket code scanned at entry
    /// Examples: "TIX-001", "ABC123", "123456789012" (barcode)
    /// Must be unique within event for duplicate prevention
    let ticketCode: String

    /// Name of ticket holder (optional)
    /// Displayed during scan for verification
    /// Example: "John Smith"
    let attendeeName: String?

    /// Email of ticket holder (optional)
    /// Could be used for notifications (future feature)
    /// Example: "john@example.com"
    let attendeeEmail: String?

    /// Type/tier of ticket
    /// Examples: "General", "VIP", "Early Bird", "Student"
    /// Used for access control and pricing
    let ticketType: String

    /// Ticket price (optional)
    /// Stored as Double for decimal precision
    /// Example: 50.00, 125.50
    /// Can be nil for free tickets or unknown pricing
    let price: Double?

    /// Current ticket status
    /// Controls whether ticket can be scanned
    /// See TicketStatus enum below
    let status: TicketStatus

    /// When ticket was purchased (optional)
    /// Imported from CSV if available
    /// Could be used for refund policies (future)
    let purchaseDate: Date?

    /// When ticket was scanned and used (optional)
    /// Set when status changes to .used
    /// Timestamp of first successful scan
    /// nil for unscanned tickets
    let usedAt: Date?

    /// When ticket was imported into system
    /// Set automatically during CSV import
    /// Used for audit trail and data lifecycle
    let createdAt: Date
}

// MARK: - Ticket Status

/// Enumeration of possible ticket states
/// Determines scan behavior and validation
///
/// STATE TRANSITIONS:
/// valid → used (successful scan)
/// valid → cancelled (manual cancellation)
/// used/cancelled → no further transitions
enum TicketStatus: String, Codable {

    /// Ticket is valid and can be scanned
    /// Initial state for imported tickets
    case valid = "valid"

    /// Ticket has been scanned and used
    /// Cannot be scanned again (duplicate prevention)
    /// Terminal state
    case used = "used"

    /// Ticket has been cancelled
    /// Could be refund, fraud prevention, or manual void
    /// Cannot be scanned
    /// Terminal state
    case cancelled = "cancelled"

    // MARK: Display Name

    /// User-friendly status text for UI display
    var displayName: String {
        switch self {
        case .valid: return "Valid"
        case .used: return "Used"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Mock Data

extension Ticket {

    /// Mock ticket for previews and testing
    /// Represents a typical general admission ticket
    static var MOCK_TICKET = Ticket(
        id: UUID().uuidString,
        eventId: "mock-event-id",
        ticketCode: "TIX-001",
        attendeeName: "John Smith",
        attendeeEmail: "john@example.com",
        ticketType: "General",
        price: 50.00,
        status: .valid,
        purchaseDate: Date(),
        usedAt: nil,
        createdAt: Date()
    )
}

// MARK: - CSV Import Mapping

/*
 CSV COLUMN MAPPING:

 CSV Header          → Ticket Property
 ------------------------------------------
 ticketCode (req)    → ticketCode
 attendeeName (opt)  → attendeeName
 attendeeEmail (opt) → attendeeEmail
 ticketType (req)    → ticketType
 price (opt)         → price
 status (opt)        → status (default: valid)

 EXAMPLE CSV:
 ticketCode,attendeeName,attendeeEmail,ticketType,price,status
 TIX-001,John Smith,john@example.com,General,50.00,valid
 TIX-002,Jane Doe,jane@example.com,VIP,100.00,valid
 TIX-003,Bob Johnson,,General,50.00,valid

 REQUIRED FIELDS:
 - ticketCode: Must be unique within event
 - ticketType: Classification/tier

 OPTIONAL FIELDS:
 - attendeeName: Can be empty
 - attendeeEmail: Can be empty
 - price: Can be empty (nil)
 - status: Defaults to "valid" if empty

 VALIDATION RULES:
 - ticketCode cannot be empty
 - ticketType cannot be empty
 - status must be valid/used/cancelled (defaults to valid)
 - price must be valid decimal or empty
 */

// MARK: - Scanning Logic

/*
 TICKET VALIDATION FLOW:

 1. SCAN DETECTED:
    - Camera scans QR/barcode
    - Extracts ticketCode string

 2. TICKET LOOKUP:
    - Query: events/{eventId}/tickets
    - Where: ticketCode == scannedCode
    - Source: Cache first (offline support)

 3. VALIDATION CHECKS:
    a) Ticket exists?
       - Yes: Continue
       - No: Return "Ticket Not Found"

    b) Status == valid?
       - Yes: Continue
       - No: Return "Already Scanned" or "Cancelled"

 4. MARK AS USED:
    - Update status: valid → used
    - Set usedAt: Current timestamp
    - Queued if offline (syncs later)

 5. CREATE SCAN LOG:
    - Save to TicketScan collection
    - Status: success
    - Include attendee info for display

 6. SHOW RESULT:
    - Display success with attendee name
    - Visual/audio feedback
    - Allow continuing to next scan

 DUPLICATE PREVENTION:
 - Status check prevents rescanning
 - Already-used tickets rejected
 - Scan log created even for duplicates
 - Organiser can see all scan attempts
 */

// MARK: - Firestore Structure

/*
 DOCUMENT PATH:
 /events/{eventId}/tickets/{ticketId}

 BENEFITS OF SUBCOLLECTION:
 - Automatic cascade deletion with event
 - Query optimisation (always event-specific)
 - Clear data hierarchy
 - Offline cache per event

 QUERY EXAMPLES:

 // Get all tickets for event
 db.collection("events").document(eventId)
   .collection("tickets")
   .getDocuments()

 // Find specific ticket code
 db.collection("events").document(eventId)
   .collection("tickets")
   .whereField("ticketCode", isEqualTo: scannedCode)
   .getDocuments()

 // Get ticket count
 db.collection("events").document(eventId)
   .collection("tickets")
   .count

 // Filter by status
 db.collection("events").document(eventId)
   .collection("tickets")
   .whereField("status", isEqualTo: "valid")
   .getDocuments()
 */

// MARK: - Future Enhancements

/*
 POTENTIAL ADDITIONS:

 - seatNumber: String? (for seated events)
 - section: String? (General/VIP/Balcony)
 - row: String? (A, B, C)
 - qrCodeImage: String? (URL to QR code image)
 - transferredFrom: String? (original purchaser)
 - transferredAt: Date? (transfer timestamp)
 - refundedAt: Date? (refund timestamp)
 - notes: String? (admin notes)
 - checkInCount: Int (allow multiple check-ins)
 - allowReentry: Bool (can scan multiple times)

 BUSINESS LOGIC:
 - Refund processing
 - Ticket transfers
 - Upgrade/downgrade ticket types
 - Group tickets (family packages)
 - Season passes (multiple events)
 */
