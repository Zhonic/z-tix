//
//  EventListCell.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import SwiftUI

// MARK: - Event List Cell

/// Reusable list cell component for displaying event information
/// Shows event details, ticket status, and provides quick access to scanner
/// Used in ManageEventView to display all user events
struct EventListCell: View {

    // MARK: - State Properties

    /// Tracks if scanner view is presented (currently unused but available for future)
    @State private var showScanner = false

    /// Tracks visual press state for tap feedback
    /// Provides subtle gray background during tap gesture
    @State private var isPressed = false

    // MARK: - Input Properties

    /// The event to display in this cell
    let event: Event

    /// Current ticket import status for this event
    /// Determines scanner button state and status text color
    let ticketStatus: EventTicketStatus

    /// Closure called when QR scanner button is tapped
    /// Parent view handles navigation to scanner
    let onScanTapped: () -> Void

    /// Closure called when the cell itself is tapped
    /// Parent view handles navigation to event details/edit
    let onCellTapped: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {

            // MARK: Event Information Section
            /// Left side: All event details in vertical stack
            VStack(alignment: .leading, spacing: 4) {

                // Event Title
                Text(event.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Event Description
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)  // Truncate long descriptions

                // MARK: Date and Time Row
                /// Shows formatted date and time with calendar icon
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(
                        "\(event.date.formatted(date: .abbreviated, time: .omitted)) at \(event.time.formatted(date: .omitted, time: .shortened))"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                // MARK: Address Row
                /// Shows venue address with map pin icon
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text(event.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)  // Truncate long addresses
                }

                // MARK: Ticket Status Indicator
                /// Color-coded status text showing ticket import state
                /// Green: Tickets imported, Red: Not imported, Orange: Import issue
                Text("Status: \(ticketStatus.displayText)")
                    .font(.caption)
                    .foregroundColor(ticketStatus.color)
            }

            Spacer()

            // MARK: Scanner Quick Action Button
            /// Right side: QR scanner icon button
            /// Enabled only when tickets are imported
            Button(action: onScanTapped) {
                Image(systemName: "qrcode.viewfinder")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(ticketStatus.hasTickets ? .cyan : .gray)
            }
            .buttonStyle(.plain)  // Removes default button styling
            .opacity(ticketStatus.hasTickets ? 1.0 : 0.5)  // Visual disabled state
        }
        .padding(.vertical, 8)

        // MARK: Tap Feedback
        /// Subtle gray background appears during tap
        .background(isPressed ? Color.gray.opacity(0.3) : Color.clear)

        // MARK: Cell Tap Gesture
        /// Entire cell is tappable for navigation to event details
        /// Provides visual feedback before triggering navigation
        .onTapGesture {
            // Show visual feedback
            isPressed = true

            // Reset visual feedback after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }

            // Trigger parent's navigation handler
            onCellTapped()
        }
    }
}

// MARK: - Preview

/// Demonstrates cell in different states for development
#Preview {
    List {
        // Cell with imported tickets (enabled scanner)
        EventListCell(
            event: Event.MOCK_EVENT,
            ticketStatus: .imported(count: 50),
            onScanTapped: { print("Scan tapped") },
            onCellTapped: { print("Cell tapped") }
        )

        // Cell without tickets (disabled scanner)
        EventListCell(
            event: Event.MOCK_EVENT,
            ticketStatus: .notImported,
            onScanTapped: { print("Scan tapped") },
            onCellTapped: { print("Cell tapped") }
        )

        // Cell with import issue (disabled scanner)
        EventListCell(
            event: Event.MOCK_EVENT,
            ticketStatus: .importIssue,
            onScanTapped: { print("Scan tapped") },
            onCellTapped: { print("Cell tapped") }
        )
    }
}
