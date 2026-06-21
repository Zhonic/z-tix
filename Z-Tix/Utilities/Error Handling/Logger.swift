//
//  Logger.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import Foundation

// MARK: - Logger Utility

/// Centralised logging utility for development and debugging
/// Provides categorised log levels with visual indicators
///
/// PURPOSE:
/// - Track app flow during development
/// - Debug issues quickly
/// - Monitor network operations
/// - Trace error sources
///
/// TOGGLE:
/// Set isEnabled = false for production to disable logging
///
/// LOG LEVELS:
/// - DEBUG: General information (white)
/// - SUCCESS: Positive outcomes (✅ green checkmark)
/// - WARNING: Non-critical issues (⚠️ orange warning)
/// - ERROR: Critical failures (❌ red X)
/// - AUTH ERROR: Specific auth issue tracking
struct Logger {

    // MARK: - Configuration

    /// Global enable/disable switch for all logging
    /// Set to false in production to improve performance
    /// Prevents log spam in release builds
    static var isEnabled = true

    // MARK: - Debug Log

    /// General purpose debug logging
    /// Used for tracing execution flow and state
    ///
    /// - Parameters:
    ///   - message: Debug message to log
    ///   - code: Optional error/status code (0 if none)
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    ///
    /// Example:
    /// Logger.debug("Loading events", code: 0)
    /// Output: DEBUG: [EventViewModel.swift:45] Loading events with error code: 0
    static func debug(
        _ message: String,
        code: Int,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }

        let fileName = (file as NSString).lastPathComponent
        print(
            "DEBUG: [\(fileName):\(line)] \(message) with error code: \(code)"
        )
    }

    // MARK: - Error Log

    /// Critical error logging with details
    /// Used for exceptions, failures, and serious issues
    /// Always prints regardless of isEnabled (errors always matter)
    ///
    /// - Parameters:
    ///   - message: Error description
    ///   - errorName: Specific error name/type
    ///   - code: Error code from framework/API
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    ///
    /// Example:
    /// Logger.error("Failed to fetch events", error.localizedDescription, code: error.code)
    /// Output: ❌ ERROR: [EventViewModel.swift:67] Failed to fetch events with error Network timeout and error code: -1001
    static func error(
        _ message: String,
        _ errorName: String,
        code: Int,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        print(
            "❌ ERROR: [\(fileName):\(line)] \(message) with error \(errorName) and error code: \(code)"
        )
    }

    // MARK: - Success Log

    /// Positive outcome logging
    /// Used to confirm operations completed successfully
    /// Provides visual feedback with ✅ checkmark
    ///
    /// - Parameters:
    ///   - message: Success message
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    ///
    /// Example:
    /// Logger.success("Event created successfully")
    /// Output: ✅ SUCCESS: [EventViewModel.swift:89] Event created successfully
    static func success(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }

        let fileName = (file as NSString).lastPathComponent
        print("✅ SUCCESS: [\(fileName):\(line)] \(message)")
    }

    // MARK: - Warning Log

    /// Non-critical issue logging
    /// Used for recoverable errors, cache misses, fallbacks
    /// Provides visual feedback with ⚠️ warning symbol
    ///
    /// - Parameters:
    ///   - message: Warning message
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    ///
    /// Example:
    /// Logger.warning("Loading from cache (offline mode)")
    /// Output: ⚠️ WARNING: [EventViewModel.swift:102] Loading from cache (offline mode)
    static func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }

        let fileName = (file as NSString).lastPathComponent
        print("⚠️ WARNING: [\(fileName):\(line)] \(message)")
    }

    // MARK: - Auth Error Log

    /// Specialised logging for Firebase Auth errors
    /// Tracks specific authentication error types
    /// Used during login/signup for debugging auth flow
    ///
    /// - Parameters:
    ///   - errorName: Firebase Auth error name (e.g., "wrongPassword")
    ///   - code: Firebase Auth error code
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    ///
    /// Example:
    /// Logger.authError("wrongPassword", code: error.code)
    /// Output: DEBUG: [AuthViewModel.swift:134] This is hitting wrongPassword with error code: 17009
    static func authError(
        _ errorName: String,
        code: Int,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }

        let fileName = (file as NSString).lastPathComponent
        print(
            "DEBUG: [\(fileName):\(line)] This is hitting \(errorName) with error code: \(code)"
        )
    }
}

// MARK: - Usage Patterns

/*
 COMMON LOGGING SCENARIOS:

 1. FUNCTION ENTRY/EXIT:
 func fetchEvents() async {
     Logger.debug("Starting event fetch", code: 0)
     // ... fetch logic
     Logger.success("Events fetched: \(events.count)")
 }

 2. NETWORK OPERATIONS:
 do {
     let snapshot = try await db.collection("events").getDocuments()
     if snapshot.metadata.isFromCache {
         Logger.warning("Loaded from CACHE (offline mode)")
     } else {
         Logger.success("Loaded from SERVER")
     }
 } catch let error as NSError {
     Logger.error("Fetch failed", error.localizedDescription, code: error.code)
 }

 3. STATE CHANGES:
 func updateTicketStatus() {
     Logger.debug("Updating ticket status to: used", code: 0)
     ticket.status = .used
     Logger.success("Ticket marked as used")
 }

 4. ERROR HANDLING:
 catch let error as NSError {
     switch error.code {
     case AuthErrorCode.wrongPassword.rawValue:
         Logger.authError("wrongPassword", code: error.code)
         alertItem = AlertContext.incorrectPassword
     default:
         Logger.error("Auth failed", error.localizedDescription, code: error.code)
     }
 }

 5. CACHE OPERATIONS:
 if cachedData != nil {
     Logger.warning("Using cached data (offline)")
     return cachedData
 } else {
     Logger.debug("Cache miss, fetching from server", code: 0)
 }
 */

// MARK: - File Location Tracking

/*
 AUTOMATIC PARAMETERS:

 file: String = #file
 - Full file path at compile time
 - Stripped to filename only in print
 - Example: /Users/.../EventViewModel.swift → EventViewModel.swift

 function: String = #function
 - Function/method name
 - Useful for tracing call stack
 - Currently not printed (could be added)

 line: Int = #line
 - Line number where log called
 - Exact location in source code
 - Invaluable for debugging

 BENEFITS:
 - No manual file/line tracking
 - Compiler provides accurate info
 - Easy to locate log source
 - Jump to code from console
 */

// MARK: - Production Considerations

/*
 DISABLING LOGS IN PRODUCTION:

 1. SET isEnabled = false:
    - Simple toggle
    - All logs disabled
    - Minimal performance impact

 2. COMPILER FLAGS:
    #if DEBUG
    static var isEnabled = true
    #else
    static var isEnabled = false
    #endif

 3. ENVIRONMENT VARIABLES:
    static var isEnabled = ProcessInfo.processInfo.environment["LOG_ENABLED"] == "1"

 PERFORMANCE:
 - Guard clause exits early when disabled
 - String interpolation still evaluated (minor cost)
 - Consider @autoclosure for zero-cost when disabled

 ALTERNATIVE LOGGING:
 - os_log (Apple's logging framework)
 - Third-party: SwiftyBeaver, CocoaLumberjack
 - Analytics services for production errors
 */

// MARK: - Visual Indicators

/*
 EMOJI PREFIXES:

 ✅ SUCCESS - Green checkmark
 - Easy to spot positive outcomes
 - Confirms operations succeeded
 - Quick visual scanning

 ⚠️ WARNING - Orange warning symbol
 - Highlights potential issues
 - Non-critical problems
 - Offline mode indicators

 ❌ ERROR - Red X mark
 - Critical failures stand out
 - Immediate attention needed
 - Exception conditions

 DEBUG - No emoji
 - Regular execution flow
 - General information
 - Not highlighted

 BENEFITS:
 - Quick log scanning in console
 - Color coding (terminal supports)
 - Priority identification
 - Visual hierarchy
 */

// MARK: - Future Enhancements

/*
 POTENTIAL IMPROVEMENTS:

 1. LOG LEVELS:
    enum LogLevel {
        case verbose, debug, info, warning, error
    }
    - Configurable verbosity
    - Filter by importance

 2. FILE LOGGING:
    - Write logs to file
    - Persist across app restarts
    - Send logs to support

 3. REMOTE LOGGING:
    - Send to analytics service
    - Crash reporting integration
    - Production error tracking

 4. STRUCTURED LOGGING:
    - JSON format
    - Searchable metadata
    - Better parsing

 5. LOG CATEGORIES:
    - Network, UI, Database, Auth
    - Filter by subsystem
    - Xcode-style unified logging
 */
