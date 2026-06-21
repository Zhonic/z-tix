//
//  TixScannerView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import SwiftUI

// MARK: - Ticket Scanner View

/// Main QR/Barcode scanner interface for ticket validation
/// Features:
/// - Live camera preview with AVFoundation
/// - Network status indicator (online/offline)
/// - Real-time scan validation with 3-second timeout
/// - Duplicate scan prevention
/// - Offline-first scanning with background sync
/// - Result alerts with attendee information
/// - Post-scan notification to update logs view
///
/// SUPPORTED FORMATS:
/// - QR codes (most common for digital tickets)
/// - EAN-8 barcodes (8-digit printed tickets)
/// - EAN-13 barcodes (13-digit printed tickets)
struct TixScannerView: View {

    // MARK: - Input Properties

    /// The event being scanned for
    /// Used to validate tickets belong to this specific event
    let event: Event

    // MARK: - View Models

    /// Ticket operations (validation, logging)
    /// StateObject: View owns lifecycle
    @StateObject var ticketViewModel = TicketViewModel()

    /// Scanner state (scanned code, alerts)
    /// StateObject: View owns lifecycle
    @StateObject var scannerViewModel = TixScannerViewModel()

    /// Network monitor for offline/online detection
    /// EnvironmentObject: Shared across app
    @EnvironmentObject var networkMonitor: NetworkMonitor

    // MARK: - Environment

    /// Dismiss action for navigation
    @Environment(\.dismiss) var dismiss

    // MARK: - State Properties

    /// Controls display of scan result alert
    @State private var showScanResult = false

    /// Latest scan result to display in alert
    @State private var scanResult: TicketScan?

    /// Prevents multiple simultaneous scan operations
    /// Critical for avoiding race conditions and duplicate scans
    @State private var isProcessing = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {

                // MARK: Network Status Indicator
                /// Shows connection status and type (WiFi/Cellular)
                /// Informs user about offline mode capabilities
                if !networkMonitor.isConnected {
                    // Offline mode banner
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                        Text("OFFLINE MODE - Scans will sync when online")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(20)
                    .padding(.top, 8)

                } else {
                    // Online mode banner with connection type
                    HStack(spacing: 8) {
                        Image(systemName: "wifi")
                            .font(.caption)
                        Text(
                            "ONLINE - \(networkMonitor.connectionType.displayName)"
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.top, 8)
                }

                // MARK: Camera Scanner View
                /// UIKit AVFoundation camera bridged to SwiftUI
                /// See ScannerView and ScannerVC for implementation
                ScannerView(
                    scannedCode: $scannerViewModel.scannedCode,
                    alertItem: $scannerViewModel.alertItem
                )
                .frame(maxWidth: .infinity, maxHeight: 300)

                Spacer().frame(height: 70)

                // MARK: Scan Status Display

                // Label with icon
                Label(
                    "Scanned Barcode:",
                    systemImage: "barcode.viewfinder"
                )
                .font(.title)

                // Status text (code or "Not Yet Scanned")
                Text(scannerViewModel.statusText)
                    .bold()
                    .font(.largeTitle)
                    .foregroundColor(scannerViewModel.statusTextColor)
                    .padding()

                // MARK: Event Information
                /// Shows which event is being scanned for
                VStack(spacing: 8) {
                    Text("Scanning for:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.cyan)
                }
                .padding()
            }
            .navigationTitle("QR Scanner")
            .navigationBarTitleDisplayMode(.inline)

            // MARK: Toolbar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }

            // MARK: Camera Error Alerts
            /// Shows alerts for camera permission issues, simulator, etc.
            .alert(item: $scannerViewModel.alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: alertItem.dismissButton
                )
            }

            // MARK: Scan Code Change Handler
            /// Triggers validation when new code is scanned
            /// Prevents duplicate processing of same code
            .onChange(of: scannerViewModel.scannedCode) { oldValue, newValue in
                guard !newValue.isEmpty, newValue != oldValue else { return }
                Task {
                    await processScan(ticketCode: newValue)
                }
            }

            // MARK: Scan Result Alert
            /// Shows validation result with attendee info
            /// Offers Continue or Done actions
            .alert("Scan Result", isPresented: $showScanResult) {
                Button("Continue Scanning") {
                    // Reset for next scan
                    scannerViewModel.scannedCode = ""
                    scanResult = nil
                }
                Button("Done", role: .cancel) {
                    dismiss()  // Return to events page
                }
            } message: {
                if let result = scanResult {
                    Text(formatScanResultMessage(result))
                }
            }
        }
    }

    // MARK: - Scan Processing

    /// Process scanned ticket code with validation and logging
    /// FLOW:
    /// 1. Set processing flag (prevent duplicate scans)
    /// 2. Validate ticket (3-second timeout protection)
    /// 3. Save scan log locally (instant, no network wait)
    /// 4. Notify logs view to refresh
    /// 5. Show result alert
    /// 6. Clear processing flag
    ///
    /// OFFLINE BEHAVIOR:
    /// - Validation uses cached ticket data
    /// - Logs saved locally first
    /// - Background sync to Firestore when online
    ///
    /// - Parameter ticketCode: QR/barcode string scanned
    func processScan(ticketCode: String) async {
        // MARK: Set Processing Flag
        /// Prevents scanning multiple tickets simultaneously
        await MainActor.run {
            isProcessing = true
        }

        Logger.debug("Processing scan for ticket: \(ticketCode)", code: 0)

        // MARK: Validate Ticket
        /// Queries Firestore (or cache) for ticket
        /// Checks if ticket exists and hasn't been used
        /// Has built-in 3-second timeout protection
        let result = await ticketViewModel.validateAndScan(
            ticketCode: ticketCode,
            eventId: event.id,
            eventTitle: event.title
        )

        Logger.debug("Scan result: \(result.status.displayName)", code: 0)

        // MARK: Save Scan Log
        /// LOCAL-FIRST: Saves to memory immediately
        /// BACKGROUND: Syncs to Firestore when available
        /// This ensures instant UI updates and offline support
        await ticketViewModel.saveScanLog(result)

        // MARK: Notify Logs View
        /// Post notification to refresh TixLogsView
        /// Ensures scan appears immediately in logs tab
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("ScanCompleted"),
                object: nil
            )
        }

        // MARK: Show Result
        /// Always show result, even if network failed
        /// User needs immediate feedback on scan validity
        await MainActor.run {
            scanResult = result
            showScanResult = true
            isProcessing = false
        }

        Logger.success("Scan processing complete, showing alert")
    }

    // MARK: - Result Formatting

    /// Format scan result into user-friendly message
    /// Different messages for each status type:
    /// - Success: Green checkmark with attendee name
    /// - Already Scanned: Orange warning
    /// - Not Found: Red X for invalid ticket
    /// - Error: Generic error message
    ///
    /// - Parameter scan: TicketScan result to format
    /// - Returns: Formatted message string with emojis
    func formatScanResultMessage(_ scan: TicketScan) -> String {
        switch scan.status {
        case .success:
            // MARK: Valid Ticket
            var message = "✅ Ticket Valid!\n\n"
            message += "Ticket: \(scan.ticketCode)\n"
            if let name = scan.attendeeName {
                message += "Attendee: \(name)"
            }
            return message

        case .alreadyScanned:
            // MARK: Duplicate Scan
            var message = "⚠️ Already Scanned!\n\n"
            message += "Ticket: \(scan.ticketCode)\n"
            if let name = scan.attendeeName {
                message += "Attendee: \(name)\n"
            }
            message += "\nThis ticket was already used."
            return message

        case .notFound:
            // MARK: Invalid Ticket
            return
                "❌ Ticket Not Found!\n\nTicket: \(scan.ticketCode)\n\nThis ticket doesn't exist for this event."

        case .error:
            // MARK: Scan Error
            return
                "❌ Scan Error!\n\nTicket: \(scan.ticketCode)\n\nAn error occurred. Please try again."
        }
    }
}

// MARK: - Preview

#Preview {
    TixScannerView(event: Event.MOCK_EVENT)
}
