//
//  TicketScan.swift
//  Z-Tix
//
//  Created by Harnish Patel on 29/10/2025.
//

import Foundation
import SwiftUI

// MARK: - Ticket Scan Model

/// Log entry for each ticket scan attempt (successful or failed)
/// Stored in Firestore at: /ticketScans/{scanId}
///
/// PURPOSE:
/// - Audit trail of all scan attempts
/// - Display in TixLogsView for monitoring
/// - Analytics (scans per hour, success rate, etc.)
/// - Fraud detection (duplicate scan attempts)
/// - Customer service (verify entry, dispute resolution)
///
/// STORED AS TOP-LEVEL COLLECTION (not subcollection):
/// - Need to query across all events for user
/// - Faster cross-event queries
/// - Independent lifecycle from events
/// - Can survive event deletion (optional)
///
/// STORAGE PATTERN:
/// 1. Save to recentScans array immediately (instant UI)
/// 2. Sync to Firestore in background (non-blocking)
/// 3. Query from Firestore for historical logs
///
/// RELATIONSHIPS:
/// - References Event via eventId (many-to-one)
/// - References Ticket via ticketId (many-to-one, nullable)
///
/// PROTOCOL CONFORMANCES:
/// - Identifiable: SwiftUI list support
/// - Codable: Firestore encoding/decoding
struct TicketScan: Identifiable, Codable {

    // MARK: - Properties

    /// Unique scan log identifier
    /// Generated as UUID string for each scan
    let id: String

    /// Event where scan occurred
    /// Links to Event document
    /// Used for grouping logs by event
    let eventId: String

    /// Event name at time of scan
    /// Denormalised for display without additional query
    /// Prevents issues if event is renamed/deleted
    let eventTitle: String

    /// Ticket code that was scanned
    /// QR/barcode string from camera
    /// Recorded even if ticket not found
    let ticketCode: String

    /// Reference to Ticket document (if found)
    /// nil for "Ticket Not Found" scans
    /// Used to link back to ticket details
    let ticketId: String?

    /// Name of attendee (if ticket found)
    /// nil for "Ticket Not Found" scans
    /// Displayed in scan result and logs
    let attendeeName: String?

    /// Email of attendee (if ticket found)
    /// nil for "Ticket Not Found" scans
    /// Could be used for notifications (future)
    let attendeeEmail: String?

    /// Result of scan validation
    /// See ScanStatus enum below
    /// Determines display color and icon
    let status: ScanStatus

    /// Timestamp when scan occurred
    /// Used for chronological sorting
    /// Local device time (consider timezone handling)
    let scannedAt: Date
}

// MARK: - Scan Status

/// Enumeration of possible scan results
/// Determines UI feedback and logging behavior
///
/// VISUAL INDICATORS:
/// - Each status has associated color and icon
/// - Used in TixLogsView and scan result alerts
/// - Traffic light pattern (green/yellow/red)
enum ScanStatus: String, Codable {

    /// Ticket valid and successfully scanned
    /// Ticket status updated to .used
    /// Entry granted
    case success = "success"

    /// Ticket found but already used
    /// Duplicate scan attempt
    /// Entry denied
    case alreadyScanned = "alreadyScanned"

    /// Ticket code doesn't exist for this event
    /// Could be wrong event, invalid code, or fraud
    /// Entry denied
    case notFound = "notFound"

    /// Validation failed due to error
    /// Network timeout, database error, etc.
    /// Entry denied (safety default)
    case error = "error"

    // MARK: - Display Properties

    /// User-friendly status text
    var displayName: String {
        switch self {
        case .success: return "Success"
        case .alreadyScanned: return "Already Scanned"
        case .notFound: return "Ticket Not Found"
        case .error: return "Error"
        }
    }

    /// Color for status badge and text
    /// Traffic light system for quick recognition
    var color: Color {
        switch self {
        case .success: return .green  // ✅ Good
        case .alreadyScanned: return .orange  // ⚠️ Warning
        case .notFound: return .red  // ❌ Error
        case .error: return .red  // ❌ Error
        }
    }

    /// SF Symbol icon for visual indicator
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .alreadyScanned: return "exclamationmark.triangle.fill"
        case .notFound: return "xmark.circle.fill"
        case .error: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Mock Data

extension TicketScan {

    /// Mock scan for previews and testing
    /// Represents successful scan scenario
    static var MOCK_SCAN = TicketScan(
        id: UUID().uuidString,
        eventId: "mock-event",
        eventTitle: "Mock Event",
        ticketCode: "TIX-001",
        ticketId: "ticket-id",
        attendeeName: "John Smith",
        attendeeEmail: "john@example.com",
        status: .success,
        scannedAt: Date()
    )
}

// MARK: - Scan Creation Patterns

/*
 CREATING SCANS IN TICKETVIEWMODEL:

 1. SUCCESS SCAN (Ticket valid):
    - ticketId: Ticket document ID
    - attendeeName: From ticket
    - attendeeEmail: From ticket
    - status: .success

 2. ALREADY SCANNED (Ticket used):
    - ticketId: Ticket document ID
    - attendeeName: From ticket (for reference)
    - attendeeEmail: From ticket
    - status: .alreadyScanned

 3. NOT FOUND (Invalid code):
    - ticketId: nil (ticket doesn't exist)
    - attendeeName: nil
    - attendeeEmail: nil
    - status: .notFound

 4. ERROR (Validation failed):
    - ticketId: nil (couldn't verify)
    - attendeeName: nil
    - attendeeEmail: nil
    - status: .error

 Example:
 func createSuccessScan(ticket: Ticket, ...) -> TicketScan {
     return TicketScan(
         id: UUID().uuidString,
         eventId: eventId,
         eventTitle: eventTitle,
         ticketCode: ticket.ticketCode,
         ticketId: ticket.id,           // ← Present
         attendeeName: ticket.attendeeName,
         attendeeEmail: ticket.attendeeEmail,
         status: .success
         scannedAt: Date()
     )
 }
 */

// MARK: - Display in TixLogsView

/*
 LOG DISPLAY LOGIC:

 1. GROUPING:
    - Scans grouped by eventId
    - Each event shows section header
    - Sorted newest first within event

 2. ROW CONTENT:
    - Icon with status color
    - Ticket code (bold)
    - Attendee name (if available)
    - Status text and timestamp

 3. FILTERING (Future):
    - Show only successes
    - Show only errors
    - Filter by date range
    - Search by ticket code/name

 4. ACTIONS (Future):
    - Tap to view full details
    - Export to CSV
    - Void scan (admin feature)
    - Resend entry confirmation

 Example Row:
 ✅ TIX-001
 John Smith
 Success • 2:34 PM
 */

// MARK: - Firestore Structure

/*
 DOCUMENT PATH:
 /ticketScans/{scanId}

 TOP-LEVEL COLLECTION RATIONALE:
 - Query all scans across events
 - Independent lifecycle from events
 - Faster cross-event queries
 - Better for analytics

 QUERY EXAMPLES:

 // Get all scans for event
 db.collection("ticketScans")
   .whereField("eventId", isEqualTo: eventId)
   .order(by: "scannedAt", descending: true)
   .getDocuments()

 // Get scans for multiple events
 db.collection("ticketScans")
   .whereField("eventId", in: [event1, event2, event3])
   .getDocuments()

 // Get scans by status
 db.collection("ticketScans")
   .whereField("status", isEqualTo: "success")
   .whereField("eventId", isEqualTo: eventId)
   .getDocuments()

 // Get recent scans
 db.collection("ticketScans")
   .whereField("eventId", isEqualTo: eventId)
   .order(by: "scannedAt", descending: true)
   .limit(to: 10)
   .getDocuments()
 */

// MARK: - Analytics Potential

/*
 METRICS FROM SCAN LOGS:

 1. SUCCESS RATE:
    - Total scans vs successful scans
    - Identify problematic ticket batches
    - Quality control for scanning process

 2. ENTRY FLOW:
    - Scans per time interval (15min buckets)
    - Identify peak entry times
    - Staff allocation planning

 3. DUPLICATE ATTEMPTS:
    - Count of alreadyScanned status
    - Fraud detection
    - Customer service issues

 4. ERROR RATE:
    - Network issues during event
    - Device problems
    - Training needs for staff

 5. AVERAGE SCAN TIME:
    - Time between consecutive scans
    - Efficiency metrics
    - Bottleneck identification

 Example Queries:
 - Success rate: (success scans / total scans) * 100
 - Peak hour: Group by hour(scannedAt), count
 - Duplicate rate: (alreadyScanned / total scans) * 100
 */

// MARK: - Future Enhancements

/*
 POTENTIAL ADDITIONS:

 - scannedBy: String? (staff member ID)
 - deviceId: String? (which device performed scan)
 - location: GeoPoint? (GPS coordinates)
 - connectionType: String? (online/offline)
 - syncedAt: Date? (when synced to Firestore)
 - voidedAt: Date? (manual override)
 - voidedBy: String? (admin who voided)
 - notes: String? (admin notes)

 BUSINESS LOGIC:
 - Void scans (admin override)
 - Export to CSV for accounting
 - Real-time dashboard
 - Push notifications on issues
 - Automated alerts (high duplicate rate)
 */
