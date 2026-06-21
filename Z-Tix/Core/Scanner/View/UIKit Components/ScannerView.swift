//
//  ScannerView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import SwiftUI

// MARK: - Scanner View (SwiftUI/UIKit Bridge)

/// SwiftUI wrapper for UIKit camera scanner (ScannerVC)
/// Implements UIViewControllerRepresentable to bridge UIKit to SwiftUI
///
/// COORDINATOR PATTERN:
/// SwiftUI ↔ Coordinator ↔ UIKit
/// - SwiftUI: Provides bindings (@Binding properties)
/// - Coordinator: Implements ScannerVCDelegate, receives scan results
/// - UIKit: ScannerVC manages camera, calls delegate methods
///
/// DATA FLOW:
/// 1. ScannerVC detects QR code
/// 2. Calls coordinator.didFind(output:)
/// 3. Coordinator updates scannerView.scannedCode
/// 4. @Binding propagates change to parent (TixScannerView)
/// 5. Parent processes scan
struct ScannerView: UIViewControllerRepresentable {

    // MARK: - Bindings

    /// Scanned code value
    /// Updates trigger scan processing in parent view
    @Binding var scannedCode: String

    /// Alert item for camera errors
    /// Shows permission errors, simulator errors, etc.
    @Binding var alertItem: AlertItem?

    // MARK: - UIViewControllerRepresentable Methods

    /// Create the UIKit view controller
    /// Called once when view appears
    ///
    /// - Parameter context: Contains coordinator and environment
    /// - Returns: Configured ScannerVC instance
    func makeUIViewController(context: Context) -> ScannerVC {
        // Pass coordinator as delegate to receive scan results
        ScannerVC(scannerDelegate: context.coordinator)
    }

    /// Update the view controller when SwiftUI state changes
    /// Not needed for this scanner (camera doesn't change based on state)
    ///
    /// - Parameters:
    ///   - uiViewController: The ScannerVC instance
    ///   - context: Contains coordinator and environment
    func updateUIViewController(_ uiViewController: ScannerVC, context: Context)
    {
        // No updates needed - camera is self-contained
    }

    /// Create coordinator instance
    /// Coordinator acts as delegate bridge between UIKit and SwiftUI
    ///
    /// - Returns: New Coordinator instance
    func makeCoordinator() -> Coordinator {
        Coordinator(scannerView: self)
    }

    // MARK: - Coordinator

    /// Coordinator implementing ScannerVCDelegate
    /// Receives callbacks from UIKit camera and updates SwiftUI state
    ///
    /// ROLE: Bridge pattern implementation
    /// - Receives scan results from ScannerVC
    /// - Updates SwiftUI @Binding properties
    /// - Handles error reporting
    final class Coordinator: NSObject, ScannerVCDelegate {

        // MARK: - Properties

        /// Reference to parent SwiftUI view
        /// Provides access to @Binding properties
        private let scannerView: ScannerView

        // MARK: - Initialisation

        /// Initialise coordinator with parent view reference
        /// - Parameter scannerView: Parent ScannerView with bindings
        init(scannerView: ScannerView) {
            self.scannerView = scannerView
        }

        // MARK: - ScannerVCDelegate Methods

        /// Called when ScannerVC successfully scans a code
        /// Updates parent's scannedCode binding to trigger processing
        ///
        /// DATA FLOW:
        /// ScannerVC → Coordinator → ScannerView → TixScannerView
        ///
        /// - Parameter output: The scanned code string
        func didFind(output: String) {
            // Update SwiftUI binding
            // This propagates up to TixScannerView
            scannerView.scannedCode = output
            print(output)  // Debug logging
        }

        /// Called when ScannerVC encounters an error
        /// Updates parent's alertItem binding to show error alert
        ///
        /// COMMON ERRORS:
        /// - invalidDeviceInput: No camera, permission denied, simulator
        /// - invalidScannedValue: Unsupported code format (shouldn't happen)
        ///
        /// - Parameter error: The type of error encountered
        func didSurface(error: CameraError) {
            // Convert CameraError to AlertItem for display
            switch error {
            case .invalidDeviceInput:
                scannerView.alertItem = AlertContext.invalidDeviceInput
            case .invalidScannedValue:
                scannerView.alertItem = AlertContext.invalidScannedType
            }
            print("")  // Debug logging separator
        }
    }

    // MARK: - Type Alias

    /// Specify which UIViewController type this representable wraps
    typealias UIViewControllerType = ScannerVC
}

// MARK: - Implementation Notes

/*
 UIViewControllerRepresentable PATTERN:

 Three required methods:
 1. makeUIViewController: Create and configure UIKit controller
 2. updateUIViewController: Update when SwiftUI state changes
 3. makeCoordinator: Create coordinator for delegation

 COORDINATOR PATTERN:
 - Coordinator is owned by SwiftUI view
 - Implements protocols that UIKit expects (ScannerVCDelegate)
 - Bridges between UIKit callbacks and SwiftUI state
 - Essential for UIKit/SwiftUI interop

 WHY USE UIKit FOR CAMERA:
 - AVFoundation is UIKit-based
 - More mature and stable than SwiftUI alternatives
 - Better performance and control
 - SwiftUI camera APIs still evolving
 - Direct access to camera hardware features

 BINDING UPDATES:
 - When coordinator updates scannerView.scannedCode
 - @Binding automatically notifies parent view
 - Parent's onChange(of: scannedCode) triggers
 - This starts scan validation process

 ERROR HANDLING:
 - Camera errors surface through delegate
 - Coordinator converts to AlertItem
 - Parent view displays alert
 - User sees helpful error message
 */
