//
//  ScannerVC.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import AVFoundation
import Foundation
import UIKit

// MARK: - Camera Error Types

/// Errors that can occur during camera setup or scanning
enum CameraError: String {
    /// Camera not available or permission denied
    case invalidDeviceInput

    /// Scanned code is not a supported format
    case invalidScannedValue
}

// MARK: - Scanner Delegate Protocol

/// Protocol for communicating scan results back to SwiftUI
/// Implemented by ScannerView.Coordinator
protocol ScannerVCDelegate: AnyObject {
    /// Called when a valid barcode/QR code is scanned
    /// - Parameter output: The string value of the scanned code
    func didFind(output: String)

    /// Called when an error occurs during scanning
    /// - Parameter error: The type of error encountered
    func didSurface(error: CameraError)
}

// MARK: - Scanner View Controller

/// UIKit view controller managing AVFoundation camera capture
/// Bridges camera functionality to SwiftUI via UIViewControllerRepresentable
///
/// CAPABILITIES:
/// - QR code detection
/// - EAN-8 barcode detection (8 digits)
/// - EAN-13 barcode detection (13 digits)
/// - Real-time camera preview
/// - Automatic focus and exposure
/// - Duplicate scan prevention
///
/// LIFECYCLE:
/// 1. Init with delegate
/// 2. viewDidLoad: Setup capture session
/// 3. viewDidAppear: Verify session running
/// 4. viewDidLayoutSubviews: Size preview layer
/// 5. Scan detected: Pause, notify delegate, resume after delay
final class ScannerVC: UIViewController {

    // MARK: - Properties

    /// AVFoundation capture session managing camera input/output
    let captureSession = AVCaptureSession()

    /// Video preview layer showing camera feed
    var previewLayer: AVCaptureVideoPreviewLayer?

    /// Delegate for communicating results back to SwiftUI
    weak var scannerDelegate: ScannerVCDelegate?

    /// Prevents processing multiple scans simultaneously
    /// Camera pauses after each scan to avoid rapid-fire duplicates
    private var isProcessingScan = false

    init(scannerDelegate: ScannerVCDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.scannerDelegate = scannerDelegate
    }

    // MARK: - Initialisation

    /// Initialise scanner with delegate
    /// - Parameter scannerDelegate: Coordinator to receive scan results
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    /// View loaded - setup camera capture session
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.debug("ScannerVC viewDidLoad - starting camera setup", code: 0)
        setupCaptureSession()
    }

    /// View appeared - verify camera is running
    /// Triggers error if camera failed to start
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Logger.debug(
            "ScannerVC viewDidAppear - checking capture session status",
            code: 0
        )

        // MARK: Session Verification
        /// Check if camera started successfully
        /// Common failure: Simulator (no camera) or permission denied
        if !captureSession.isRunning {
            Logger.warning("Capture session is not running - triggering error")

            // Delay error to allow UI to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                [weak self] in
                Logger.error(
                    "Capture session failed to start",
                    "Session not running",
                    code: 1001
                )
                self?.scannerDelegate?.didSurface(error: .invalidDeviceInput)
            }
        } else {
            Logger.success("Capture session is running successfully")
        }
    }

    /// Layout subviews - size preview layer to view bounds
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // MARK: Preview Layer Sizing
        /// Ensure preview layer matches view size
        /// Important for rotation and different device sizes
        guard let previewLayer = previewLayer else {
            Logger.error(
                "Preview layer setup failed",
                "Preview layer is nil",
                code: 1002
            )
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }

        previewLayer.frame = view.layer.bounds
        Logger.debug(
            "Preview layer bounds set to: \(view.layer.bounds)",
            code: 0
        )

    }

    // MARK: - Camera Setup

    /// Configure AVFoundation capture session with camera input and metadata output
    /// STEPS:
    /// 1. Check for simulator (no camera available)
    /// 2. Get video capture device (camera)
    /// 3. Create video input from device
    /// 4. Add input to capture session
    /// 5. Create metadata output (barcode detector)
    /// 6. Add output to capture session
    /// 7. Configure metadata types (QR, EAN-8, EAN-13)
    /// 8. Create preview layer
    /// 9. Start capture session
    private func setupCaptureSession() {
        Logger.debug("Starting setupCaptureSession", code: 0)

        // MARK: Simulator Check
        /// Simulator doesn't have camera hardware
        /// Fail early with helpful error message
        #if targetEnvironment(simulator)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                [weak self] in
                Logger.warning("Running on simulator - no camera available")
                self?.scannerDelegate?.didSurface(error: .invalidDeviceInput)
            }
            return
        #endif

        // MARK: Get Camera Device
        /// Request default video capture device (back camera)
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video)
        else {
            Logger.error(
                "Camera setup failed",
                "No video capture device",
                code: 0
            )
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }

        Logger.success("Video capture device found")

        // MARK: Create Video Input
        /// Wrap camera device in input for capture session
        let videoInput: AVCaptureDeviceInput

        do {
            try videoInput = AVCaptureDeviceInput(device: videoCaptureDevice)
            Logger.success("Video input created successfully")
        } catch {
            Logger.error(
                "Video input creation failed",
                error.localizedDescription,
                code: 2002
            )
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }

        // MARK: Add Input to Session
        /// Check compatibility before adding
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            Logger.success("Video input added to capture session")
        } else {
            Logger.error(
                "Cannot add video input",
                "captureSession.canAddInput returned false",
                code: 2003
            )
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }

        // MARK: Create Metadata Output
        /// This is what actually detects barcodes/QR codes
        let metaDataOutput = AVCaptureMetadataOutput()

        // MARK: Add Output to Session
        /// Check compatibility before adding
        if captureSession.canAddOutput(metaDataOutput) {
            captureSession.addOutput(metaDataOutput)
            Logger.success("Metadata output added to capture session")

            // MARK: Configure Metadata Detection
            /// Set this controller as delegate to receive scan events
            metaDataOutput.setMetadataObjectsDelegate(self, queue: .main)

            /// Specify which code types to detect
            /// QR: Digital tickets, modern standard
            /// EAN-8: Short printed barcodes (8 digits)
            /// EAN-13: Standard printed barcodes (13 digits)
            metaDataOutput.metadataObjectTypes = [.qr, .ean8, .ean13]
            Logger.debug("Metadata types set to: QR, EAN-8, EAN-13", code: 0)

        } else {
            Logger.error(
                "Cannot add metadata output",
                "captureSession.canAddOutput returned false",
                code: 2004
            )
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }

        // MARK: Setup Preview Layer
        /// Create visual preview of camera feed
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        /// Fill entire preview area while maintaining aspect ratio
        /// Prevents black bars on sides
        previewLayer!.videoGravity = .resizeAspectFill
        Logger.success("Preview layer created with resizeAspectFill")

        // MARK: Add Preview to View
        /// Insert preview layer as sublayer
        /// Force unwrapped as the value is just above
        view.layer.addSublayer(previewLayer!)
        Logger.debug("Preview layer added to view", code: 0)

        // MARK: Start Camera
        /// Begin capturing video and detecting codes
        captureSession.startRunning()
        Logger.success("Capture session started running")
    }
}

// MARK: - Metadata Output Delegate

/// Extension implementing AVCaptureMetadataOutputObjectsDelegate
/// Called when camera detects a barcode or QR code
extension ScannerVC: AVCaptureMetadataOutputObjectsDelegate {

    /// Called when metadata (barcode/QR) is detected in camera feed
    /// FLOW:
    /// 1. Check not already processing (prevent duplicates)
    /// 2. Extract metadata object from array
    /// 3. Verify it's a machine-readable code
    /// 4. Extract string value
    /// 5. Pause camera to prevent rapid-fire scans
    /// 6. Notify delegate with scanned value
    /// 7. Resume camera after 1.5 second delay
    ///
    /// - Parameters:
    ///   - output: Metadata output object
    ///   - metadataObjects: Array of detected objects
    ///   - connection: Capture connection
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {

        // MARK: Duplicate Prevention
        /// Prevent processing multiple scans simultaneously
        /// Camera can detect same code multiple times per second
        guard !isProcessingScan else {
            Logger.debug("Scan already in progress, ignoring", code: 0)
            return
        }

        Logger.debug("Metadata output received - checking objects", code: 0)

        // MARK: Extract Metadata Object
        /// Array should have one object when code is detected
        guard let object = metadataObjects.first else {
            Logger.debug("No metadata objects found", code: 0)
            return
        }

        Logger.debug("Metadata object found: \(object)", code: 0)

        // MARK: Verify Machine Readable Code
        /// Cast to machine-readable code object
        /// Filters out non-barcode metadata
        guard
            let machineReadableObject = object
                as? AVMetadataMachineReadableCodeObject
        else {
            Logger.debug("Object is not machine readable code", code: 0)
            return
        }

        Logger.debug(
            "Machine readable object type: \(machineReadableObject.type.rawValue)",
            code: 0
        )

        // MARK: Extract String Value
        /// Get the actual code string (ticket ID)
        guard let output = machineReadableObject.stringValue else {
            Logger.debug("No string value in code", code: 0)
            return
        }

        Logger.success("Successfully scanned code: \(output)")

        // MARK: Process Scan

        // Set processing flag immediately
        isProcessingScan = true

        // Pause camera to prevent multiple scans of same code
        captureSession.stopRunning()
        Logger.debug("Camera paused for processing", code: 0)

        // Notify delegate (SwiftUI) of scanned code
        scannerDelegate?.didFind(output: output)

        // MARK: Resume Scanning
        /// Resume camera after delay to allow processing
        /// 1.5 seconds gives time for validation and alert display
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isProcessingScan = false
            self?.captureSession.startRunning()
            Logger.debug("Camera resumed, ready for next scan", code: 0)
        }
    }
}

// MARK: - Implementation Notes

/*
 CAMERA PERMISSIONS:
 - Info.plist must include NSCameraUsageDescription
 - iOS automatically prompts user for permission
 - If denied, capture session fails and display error

 SUPPORTED FORMATS:
 - QR codes: Modern digital tickets, URLs, complex data
 - EAN-8: 8-digit printed barcodes (shorter format)
 - EAN-13: 13-digit printed barcodes (UPC-A compatible)

 SCAN PREVENTION PATTERN:
 - isProcessingScan flag prevents rapid duplicate scans
 - Camera pauses after each scan
 - 1.5 second delay allows validation + user feedback
 - Camera resumes automatically for next scan

 ERROR HANDLING:
 - Simulator: Show error immediately (no camera)
 - No camera: Rare on real devices, but handle gracefully
 - Permission denied: System handles, we detect failure
 - Session failure: Verify in viewDidAppear, show error

 PREVIEW LAYER:
 - Sized in viewDidLayoutSubviews (handles rotation)
 - Uses .resizeAspectFill to avoid black bars
 - Covers entire scanner view area
 */
