//
//  ImportTicketsView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 28/10/2025.
//

import SwiftUI

// MARK: - Import Tickets View

/// Format selection screen for ticket import
/// Presents different import options with clear visual hierarchy
/// Currently only CSV is implemented, others show "Coming Soon"
///
/// DESIGN PATTERN:
/// - Active formats: Prominent cyan styling, functional
/// - Coming soon formats: Grayed out, show alert when tapped
/// - Consistent button layout for all options
///
/// FUTURE FORMATS:
/// - Excel (.xlsx, .xls) - Planned
/// - JSON (.json) - Planned
/// - API integration - Future consideration
/// - Manual entry - For small events
struct ImportTicketsView: View {

    // MARK: - Input Properties

    /// Event ID to import tickets for
    let eventId: String

    /// Parent sheet presentation binding
    /// Controls entire import flow dismissal
    @Binding var isPresented: Bool

    // MARK: - Environment

    /// Dismiss action for this sheet
    @Environment(\.dismiss) var dismiss

    // MARK: - State Properties

    /// Controls CSV import sheet presentation
    @State private var showCSVImport = false

    /// Controls "Coming Soon" alert for unavailable formats
    @State private var showComingSoonAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // MARK: Header
                Text("Choose Import Format")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 30)

                Text("Select how you'd like to import your tickets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // MARK: Format Options
                VStack(spacing: 15) {

                    // MARK: CSV Option - Active
                    /// Fully functional import option
                    Button {
                        showCSVImport = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.title2)
                                .foregroundColor(.cyan)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("CSV File")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Import from CSV spreadsheet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.cyan)
                        }
                        .padding()
                        .background(Color.cyan.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan, lineWidth: 2)
                        )
                    }

                    // MARK: Excel Option - Coming Soon
                    /// Planned feature for future release
                    Button {
                        showComingSoonAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "tablecells")
                                .font(.title2)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Excel File")
                                    .font(.headline)
                                    .foregroundColor(.gray)

                                Text("Import from Excel spreadsheet")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // MARK: JSON Option - Coming Soon
                    /// Planned feature for API-based imports
                    Button {
                        showComingSoonAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "curlybraces")
                                .font(.title2)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("JSON File")
                                    .font(.headline)
                                    .foregroundColor(.gray)

                                Text("Import from JSON data")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()
            }
            .navigationTitle("Import Tickets")
            .navigationBarTitleDisplayMode(.inline)

            // MARK: Toolbar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // MARK: CSV Import Sheet
            /// Presents full CSV import flow
            .sheet(isPresented: $showCSVImport) {
                CSVImportView(
                    eventId: eventId,
                    parentIsPresented: $isPresented
                )

            }

            // MARK: Coming Soon Alert
            /// Informs users about planned features
            .alert("Feature Coming Soon", isPresented: $showComingSoonAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This import format will be available in a future update.")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ImportTicketsView(eventId: "mock-event-id", isPresented: .constant(true))
}

// MARK: - Future Import Formats

/*
 EXCEL IMPORT (.xlsx, .xls):
 - Requires ExcelKit or similar library
 - Parse sheets, handle multiple tabs
 - More complex than CSV but popular format
 - Priority: High (many users have Excel)

 JSON IMPORT (.json):
 - Great for API integrations
 - Structured data, easy to parse
 - Could connect to ticketing platforms
 - Priority: Medium (developer-focused)

 MANUAL ENTRY:
 - Simple form for small events
 - Add tickets one by one
 - Good for last-minute additions and at-event live ticket sales
 - Priority: Low (CSV covers most cases)

 API INTEGRATION:
 - Connect to Eventbrite, Ticketmaster, etc.
 - Auto-sync tickets from other platforms
 - OAuth authentication required
 - Priority: Future (complex implementation)

 BARCODE GENERATION:
 - Generate tickets in-app
 - Print or email to attendees
 - Requires PDF generation
 - Priority: Future (major feature)
 */
