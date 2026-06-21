//
//  TixScannerViewModel.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import SwiftUI

// MARK: - Ticket Scanner View Model

/// Simple view model managing scanner UI state
/// Handles scanned code display and camera error alerts
/// Minimal logic - most scan processing happens in TixScannerView
final class TixScannerViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Currently scanned code (ticket ID)
    /// Empty string = no code scanned yet
    /// Updated by ScannerView coordinator when code detected
    /// Published = broadcasts changes to trigger UI updates
    @Published var scannedCode = ""

    /// Alert item for camera/scanning errors
    /// Set by ScannerView coordinator when errors occur
    /// Observed by TixScannerView to display alerts
    @Published var alertItem: AlertItem? {
        didSet {
            // Log when alert is set for debugging
            if let alert = alertItem {
                Logger.debug("Alert set: \(alert.title)", code: 0)
            }
        }
    }

    // MARK: - Computed Properties

    /// Status text to display below camera preview
    /// Shows scanned code or "Not Yet Scanned" message
    ///
    /// - Returns: Scanned code or placeholder text
    var statusText: String {
        scannedCode.isEmpty ? "Not Yet Scaned" : scannedCode
    }

    /// Color for status text based on scan state
    /// Red = no scan yet (waiting)
    /// Green = code scanned (processing)
    ///
    /// - Returns: Red for empty, green for scanned
    var statusTextColor: Color {
        scannedCode.isEmpty ? .red : .green
    }

}

// MARK: - Design Notes

/*
 MINIMAL VIEW MODEL:

 This view model is intentionally simple because:
 - Main scan logic lives in TixScannerView (closer to UI)
 - TicketViewModel handles validation and logging
 - ScannerVC handles camera operations
 - This just manages display state

 RESPONSIBILITIES:
 - Store currently scanned code
 - Store camera error alerts
 - Compute display text and colors
 - That's it!

 WHY SO SIMPLE:
 - Follows single responsibility principle
 - Scanner UI state is simple (code + alerts)
 - Complex logic (validation, logging) belongs elsewhere
 - Easy to test and maintain

 PUBLISHED PROPERTIES:
 - scannedCode: Triggers processScan() in parent view
 - alertItem: Triggers alert display in parent view

 COMPUTED PROPERTIES:
 - statusText: Pure function, no side effects
 - statusTextColor: Pure function, no side effects
 - Could be moved to view, but cleaner here
 */
