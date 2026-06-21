//
//  NetworkMonitor.swift
//  Z-Tix
//
//  Created by Harnish Patel on 5/11/2025.
//

import Foundation
import Network

// MARK: - Network Monitor

/// Real-time network connectivity monitoring using Apple's Network framework
/// Publishes connection status and type changes to update UI indicators
/// Used throughout the app to show online/offline badges and enable appropriate features
@MainActor
class NetworkMonitor: ObservableObject {

    // MARK: - Published Properties

    /// Whether the device currently has network connectivity
    /// Updates UI elements to show online/offline status
    @Published var isConnected: Bool = true

    /// The type of network connection currently active
    /// Used to display specific connection type (WiFi, Cellular, etc.)
    @Published var connectionType: ConnectionType = .wifi

    // MARK: - Private Properties

    /// Network path monitor that observes connectivity changes
    /// Runs on a background queue to avoid blocking main thread
    private let monitor = NWPathMonitor()

    /// Background queue for network monitoring operations
    /// Labeled for easy identification in debugging
    private let queue = DispatchQueue(label: "NetworkMonitor")

    // MARK: - Connection Type Enum

    /// Enumeration of possible network connection types
    /// Provides human-readable names for UI display
    enum ConnectionType {
        /// Connected via WiFi network
        case wifi

        /// Connected via cellular data (3G/4G/5G)
        case cellular

        /// Connected via wired ethernet (rare on iOS, common on Mac Catalyst)
        case ethernet

        /// No network connection available
        case none

        /// User-friendly display name for each connection type
        var displayName: String {
            switch self {
            case .wifi: return "WiFi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .none: return "No Connection"
            }
        }
    }

    // MARK: - Initialisation

    /// Initialise the network monitor and start observing connectivity
    /// Monitoring begins immediately upon creation
    init() {
        startMonitoring()
    }

    // MARK: - Monitoring Methods

    /// Begin monitoring network path changes
    /// Sets up a handler that fires whenever connectivity status changes
    func startMonitoring() {
        // Configure the path update handler
        // [weak self] prevents retain cycles
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                // Update connection status based on path satisfaction
                // .satisfied means network is available and usable
                self?.isConnected = path.status == .satisfied

                // Determine and update the specific connection type
                self?.updateConnectionType(path)

                // MARK: Logging

                if path.status == .satisfied {
                    // Log successful connection with type
                    Logger.success(
                        "Network connected - \(self?.connectionType.displayName ?? "Unknown")"
                    )
                } else {
                    // Log offline status - app enters offline mode
                    Logger.warning("Network disconnected - Offline mode active")
                }
            }
        }

        // Start the monitor on background queue
        // This prevents blocking the main thread during network checks
        monitor.start(queue: queue)
    }

    /// Determine the specific type of network connection
    /// Checks interface types in order of preference (WiFi > Cellular > Ethernet)
    ///
    /// - Parameter path: The current network path to analyse
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .none
        }
    }

    /// Stop monitoring network changes
    /// Should be called when the monitor is no longer needed to free resources
    /// Currently not used (monitor runs for app lifetime) but available for future optimisation
    func stopMonitoring() {
        monitor.cancel()
    }
}
