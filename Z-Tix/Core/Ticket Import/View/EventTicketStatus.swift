//
//  EventTicketStatus.swift
//  Z-Tix
//
//  Created by Harnish Patel on 29/10/2025.
//

import SwiftUI

// MARK: - Event Ticket Status

/// Represents the ticket import status for an event
/// Used in event list cells to show ticket availability
///
/// STATES:
/// - notImported: No tickets uploaded yet (red, blocks scanning)
/// - imported(count): Tickets uploaded successfully (green, enables scanning)
/// - importIssue: Import failed or file was empty (orange, blocks scanning)
///
/// VISUAL INDICATORS:
/// - Color-coded badges
/// - Status text with ticket count
/// - Icon indicators (planned for future)
enum EventTicketStatus {

    // MARK: - Cases

    /// No tickets have been imported for this event
    /// User must import tickets before scanning
    case notImported

    /// Tickets successfully imported
    /// Associated value contains ticket count
    case imported(count: Int)

    /// Import attempted but failed or file was empty
    /// User should try importing again
    case importIssue

    // MARK: - Display Text

    /// User-friendly status text for UI display
    var displayText: String {
        switch self {
        case .notImported:
            return "Tickets Not Imported"
        case .imported(let count):
            return "Tickets Imported (\(count))"
        case .importIssue:
            return "Import Issue"
        }
    }

    // MARK: - Color Coding

    /// Color for status badge and text
    /// Uses traffic light system:
    /// - Red: Cannot proceed (not imported)
    /// - Green: Ready to go (imported)
    /// - Orange: Warning/issue (import problem)
    var color: Color {
        switch self {
        case .notImported:
            return .red
        case .imported:
            return .green
        case .importIssue:
            return .orange
        }
    }

    // MARK: - Scanning Permission

    /// Determines if QR scanner should be enabled
    /// Only allows scanning when tickets are successfully imported
    ///
    /// LOGIC:
    /// - Must be .imported case
    /// - Count must be greater than 0
    /// - Returns false for notImported and importIssue
    ///
    /// - Returns: true if scanning is allowed
    var hasTickets: Bool {
        if case .imported(let count) = self, count > 0 {
            return true
        }
        return false
    }
}

// MARK: - Usage Examples

/*
 TYPICAL USAGE IN EVENT LIST:

 // In EventListCell:
 EventListCell(
     event: event,
     ticketStatus: .imported(count: 150),  // Shows "Tickets Imported (150)" in green
     onScanTapped: { /* Enable scanner */ }
 )

 // Scanner button state:
 Button(action: onScanTapped) {
     Image(systemName: "qrcode.viewfinder")
         .foregroundColor(ticketStatus.hasTickets ? .cyan : .gray)  // Cyan if has tickets
 }
 .disabled(!ticketStatus.hasTickets)  // Disabled if no tickets

 DETERMINING STATUS:

 let ticketCount = await ticketViewModel.getTicketCount(for: eventId)

 if ticketCount > 0 {
     status = .imported(count: ticketCount)
 } else {
     status = .notImported  // Or .importIssue if import was attempted
 }

 FUTURE ENHANCEMENTS:
 - Add icon property for visual indicators
 - Add .syncing state for offline uploads
 - Add .expired state for past events
 - Add detailed error messages for importIssue
 */
