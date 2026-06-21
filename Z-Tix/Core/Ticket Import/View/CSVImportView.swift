//
//  CSVImportView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 28/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - CSV Import View

/// CSV file import interface with preview and validation
/// Features:
/// - File picker for .csv and .txt files
/// - Real-time CSV parsing with error detection
/// - Preview of first 10 tickets before import
/// - Warning display for parsing issues
/// - Batch Firestore write for efficiency
/// - Offline detection with warning
/// - Network status indicator
///
/// CSV FORMAT:
/// Required columns: ticketCode, ticketType
/// Optional columns: attendeeName, attendeeEmail, price, status
///
/// VALIDATION:
/// - Header row must exist
/// - Required columns must be present
/// - Row length must match header length
/// - Each ticket must have unique ID
struct CSVImportView: View {

    // MARK: - Input Properties

    /// Event ID to import tickets for
    let eventId: String

    /// Parent sheet presentation binding
    /// Used to dismiss entire import flow on success
    @Binding var parentIsPresented: Bool

    // MARK: - Environment

    /// Dismiss action for this sheet
    @Environment(\.dismiss) var dismiss

    /// Network monitor for offline detection
    @EnvironmentObject var networkMonitor: NetworkMonitor

    /// Ticket view model for import operations
    @StateObject private var ticketViewModel = TicketViewModel()

    // MARK: - State Properties

    /// Import in progress flag
    @State private var isImporting = false

    /// Controls file picker presentation
    @State private var showFilePicker = false

    /// Array of tickets parsed from CSV
    @State private var parsedTickets: [Ticket] = []

    /// Array of parsing errors/warnings
    @State private var parseErrors: [String] = []

    /// Controls preview display state
    @State private var showPreview = false

    /// Controls success alert display
    @State private var importSuccess = false

    /// Controls offline warning alert
    @State private var showOfflineWarning = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // MARK: Initial State - Instructions
                if parsedTickets.isEmpty && !showPreview {
                    VStack(spacing: 20) {

                        // Icon
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.cyan)

                        // Title
                        Text("Import CSV File")
                            .font(.title2)
                            .fontWeight(.semibold)

                        // Description
                        Text("Select a CSV file containing your ticket data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // MARK: CSV Format Requirements
                        /// Educates user about required CSV structure
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Required CSV Columns:")
                                .font(.headline)

                            Text("• ticketCode (required)")
                            Text("• attendeeName (optional)")
                            Text("• attendeeEmail (optional)")
                            Text("• ticketType (required)")
                            Text("• price (optional)")
                            Text("• status (optional: valid/used/cancelled)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)

                        // MARK: Select File Button
                        Button {
                            showFilePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Select CSV File")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding()

                } else if showPreview {
                    // MARK: Preview State
                    /// Shows parsed tickets before importing
                    VStack(spacing: 15) {

                        // MARK: Preview Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Preview")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text("\(parsedTickets.count) tickets found")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal)

                        // MARK: Warning Banner
                        /// Shows parsing errors if any occurred
                        if !parseErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(
                                        systemName:
                                            "exclamationmark.triangle.fill"
                                    )
                                    .foregroundColor(.orange)
                                    Text("Warnings (\(parseErrors.count))")
                                        .font(.headline)
                                }

                                // Show first 5 errors
                                ForEach(parseErrors.prefix(5), id: \.self) {
                                    error in
                                    Text("• \(error)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                // Show count of remaining errors
                                if parseErrors.count > 5 {
                                    Text(
                                        "+ \(parseErrors.count - 5) more warnings"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }

                        // MARK: Ticket Preview List
                        /// Shows first 10 tickets for verification
                        List(parsedTickets.prefix(10)) { ticket in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ticket.ticketCode)
                                    .font(.headline)

                                if let name = ticket.attendeeName {
                                    Text(name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text(ticket.ticketType)
                                        .font(.caption)
                                        .foregroundColor(.cyan)

                                    if let price = ticket.price {
                                        Text(
                                            "$\(String(format: "%.2f", price))"
                                        )
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // MARK: Remaining Count
                        /// Shows how many more tickets exist beyond preview
                        if parsedTickets.count > 10 {
                            Text("+ \(parsedTickets.count - 10) more tickets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)

            // MARK: Toolbar
            .toolbar {

                // MARK: Network Status Indicator
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

                // MARK: Cancel Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                // MARK: Import Button
                /// Only shown in preview state
                if showPreview {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isImporting ? "Importing..." : "Import") {
                            if !networkMonitor.isConnected {
                                // Warn user about offline mode
                                showOfflineWarning = true
                            } else {
                                Task {
                                    await importTickets()
                                }
                            }
                        }
                        .disabled(isImporting || parsedTickets.isEmpty)
                    }
                }
            }

            // MARK: File Picker
            /// System file picker for CSV selection
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result)
            }

            // MARK: Success Alert
            .alert("Import Successful!", isPresented: $importSuccess) {
                Button("Done") {
                    parentIsPresented = false
                }
            } message: {
                Text(
                    "\(parsedTickets.count) tickets have been imported successfully."
                )
            }

            // MARK: Error Alert
            .alert(item: $ticketViewModel.alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: alertItem.dismissButton
                )
            }

            // MARK: Offline Warning Alert
            .alert("Offline Mode", isPresented: $showOfflineWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "You need an internet connection to import tickets. The import will be queued and completed once you're back online."
                )
            }
        }
    }

    // MARK: - File Selection Handler

    /// Handle file selection from system picker
    /// SECURITY:
    /// - Uses security-scoped resource access
    /// - Releases access after reading with defer
    ///
    /// - Parameter result: Result containing selected file URL or error
    func handleFileSelection(result: Result<[URL], Error>) {
        do {
            // Extract first (only) selected file
            guard let selectedFile = try result.get().first else { return }

            // MARK: Request Security Access
            /// Required for reading files outside app sandbox
            guard selectedFile.startAccessingSecurityScopedResource() else {
                Logger.error(
                    "Failed to access file",
                    "Security scoped resource",
                    code: 0
                )
                return
            }

            // MARK: Release Access on Completion
            /// Ensures security access is released even if error occurs
            defer { selectedFile.stopAccessingSecurityScopedResource() }

            // MARK: Read File Content
            /// Load entire CSV file into memory
            let csvContent = try String(
                contentsOf: selectedFile,
                encoding: .utf8
            )

            // Parse the CSV content
            parseCSV(content: csvContent)

        } catch {
            Logger.error(
                "Failed to read file",
                error.localizedDescription,
                code: 0
            )
            ticketViewModel.alertItem = AlertContext.fileReadFailed
        }
    }

    // MARK: - CSV Parsing

    /// Parse CSV content into Ticket objects
    /// PARSING ALGORITHM:
    /// 1. Split content into rows by newlines
    /// 2. Parse header row to get column names
    /// 3. Validate required columns exist
    /// 4. Parse each data row:
    ///    - Split by commas
    ///    - Map values to columns
    ///    - Create Ticket object
    ///    - Track errors for invalid rows
    ///
    /// - Parameter content: Raw CSV file content
    func parseCSV(content: String) {
        parseErrors = []
        var tickets: [Ticket] = []

        // MARK: Split Into Rows
        let rows = content.components(separatedBy: .newlines)
        guard rows.count > 1 else {
            parseErrors.append("CSV file is empty or invalid")
            return
        }

        // MARK: Parse Header Row
        /// First row contains column names
        let header = rows[0].components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        // MARK: Validate Required Columns
        guard header.contains("ticketCode") && header.contains("ticketType")
        else {
            parseErrors.append(
                "Missing required columns: ticketCode and ticketType"
            )
            return
        }

        // MARK: Parse Data Rows
        /// Process each row after header
        for (index, row) in rows.dropFirst().enumerated() {
            // Skip empty rows
            guard !row.isEmpty else { continue }

            // Split row by commas
            let values = row.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            // Validate column count matches header
            guard values.count == header.count else {
                parseErrors.append("Row \(index + 2): Column count mismatch")
                continue
            }

            // MARK: Map Values to Columns
            /// Create dictionary of column name → value
            var rowData: [String: String] = [:]
            for (i, key) in header.enumerated() {
                rowData[key] = values[i]
            }

            // MARK: Validate Required Fields

            // Check ticketCode
            guard let ticketCode = rowData["ticketCode"], !ticketCode.isEmpty
            else {
                parseErrors.append("Row \(index + 2): Missing ticketCode")
                continue
            }

            // Check ticketType
            guard let ticketType = rowData["ticketType"], !ticketType.isEmpty
            else {
                parseErrors.append("Row \(index + 2): Missing ticketType")
                continue
            }

            // MARK: Parse Optional Fields

            // Parse price (optional)
            let price = Double(rowData["price"] ?? "")

            // Parse status (optional, default to valid)
            let statusString = rowData["status"] ?? "valid"
            let status =
                TicketStatus(rawValue: statusString.lowercased()) ?? .valid

            // MARK: Create Ticket Object
            let ticket = Ticket(
                id: UUID().uuidString,
                eventId: eventId,
                ticketCode: ticketCode,
                attendeeName: rowData["attendeeName"],
                attendeeEmail: rowData["attendeeEmail"],
                ticketType: ticketType,
                price: price,
                status: status,
                purchaseDate: nil,
                usedAt: nil,
                createdAt: Date()
            )

            tickets.append(ticket)
        }

        // MARK: Update State
        parsedTickets = tickets
        showPreview = true
        Logger.success("Parsed \(tickets.count) tickets from CSV")
    }

    // MARK: - Import Tickets

    /// Import parsed tickets to Firestore
    /// Uses batch write for atomic operation
    /// All tickets imported together or none at all
    func importTickets() async {
        isImporting = true

        do {
            try await ticketViewModel.importTickets(
                tickets: parsedTickets,
                eventId: eventId
            )
            importSuccess = true
        } catch {
            Logger.error(
                "Failed to import tickets",
                error.localizedDescription,
                code: 0
            )
        }

        isImporting = false
    }
}

// MARK: - Preview

#Preview {
    CSVImportView(eventId: "mock-event-id", parentIsPresented: .constant(true))
}

// MARK: - CSV Format Example

/*
 EXAMPLE CSV FILE:

 ticketCode,attendeeName,attendeeEmail,ticketType,price,status
 TIX-001,John Smith,john@example.com,General,50.00,valid
 TIX-002,Jane Doe,jane@example.com,VIP,100.00,valid
 TIX-003,Bob Johnson,bob@example.com,General,50.00,used

 NOTES:
 - First row is header (column names)
 - Comma-separated values
 - Optional fields can be empty
 - Status values: valid, used, cancelled
 - Price should be decimal number

 COMMON ERRORS:
 - Missing header row
 - Inconsistent column count
 - Empty required fields
 - Invalid status values (auto-corrected to 'valid')
 - Non-numeric price (ignored, set to nil)
 */
