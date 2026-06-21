//
//  AddressSearchService.swift
//  Z-Tix
//
//  Created by Harnish Patel on 2/11/2025.
//

import Foundation

// MARK: - Place Suggestion Model

/// Represents a single address suggestion from Google Places API
/// Conforms to Identifiable for use in SwiftUI ForEach loops
/// Conforms to Codable for JSON decoding from API response
struct PlaceSuggestion: Identifiable, Codable {
    /// Unique identifier for SwiftUI list rendering
    /// Uses Google's placeId to ensure uniqueness
    let id: String

    /// Human-readable address description
    /// Example: "123 Superhero Lair, Stark City, Marvel, Universe"
    let description: String

    /// Google Places unique identifier for this place
    /// Used for place details API calls (not currently implemented)
    let placeId: String

    // MARK: Custom Decoding

    /// JSON keys from Google Places API response
    enum CodingKeys: String, CodingKey {
        case description
        case placeId
    }

    /// Custom decoder to set id from placeId
    /// Google's response doesn't include an 'id' field
    /// 'id' field' derived from placeId for Identifiable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(
            String.self,
            forKey: .description
        )
        self.placeId = try container.decode(String.self, forKey: .placeId)
        self.id = placeId  // Use placeId as the unique identifier
    }

    /// Manual initialiser for testing and mock data
    init(description: String, placeId: String) {
        self.id = placeId
        self.description = description
        self.placeId = placeId
    }
}

// MARK: - API Response Models

/// Root response structure from Google Places Autocomplete API
/// Matches the JSON structure returned by the API
struct AutocompleteResponse: Codable {
    /// Array of autocomplete suggestions (nil if no results)
    let suggestions: [SuggestionWrapper]?

    /// Wrapper containing the place prediction
    /// Google's API uses nested structure for extensibility
    struct SuggestionWrapper: Codable {
        let placePrediction: PlacePrediction
    }

    /// Detailed prediction information for a place
    struct PlacePrediction: Codable {
        /// Text description of the place
        let text: TextContent

        /// Unique identifier for this place
        let placeId: String

        /// Nested text content wrapper
        /// API uses object instead of string for future extensibility
        struct TextContent: Codable {
            /// The actual text description
            let text: String
        }
    }
}

// MARK: - Address Search Service

/// Observable service managing Google Places API autocomplete requests
/// Implements debouncing to reduce API calls and costs
/// Runs on MainActor to safely update UI-bound published properties
@MainActor
class AddressSearchService: ObservableObject {

    // MARK: - Published Properties

    /// Current list of address suggestions
    /// Updates trigger dropdown UI refresh in AddressSearchView
    @Published var suggestions: [PlaceSuggestion] = []

    /// Loading state for showing progress indicator
    /// True during API request
    @Published var isLoading = false

    /// Error message to display to user
    /// Set when API calls fail (network, invalid key, etc.)
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// Active search task for debouncing
    /// Cancelled when new search is triggered before completion
    /// Prevents API call spam as user types
    private var searchTask: Task<Void, Never>?

    // MARK: - Public Methods

    /// Trigger address search with debouncing
    /// Cancels previous search if still pending
    /// Requires minimum 4 characters to trigger API call
    ///
    /// DEBOUNCING: Waits 300ms after typing stops before calling API
    /// Reduces API calls from ~20 (one per keystroke) to 1-2 per address
    ///
    /// COST SAVINGS: Google charges $2.83 per 1000 requests
    /// Debouncing reduces costs by 90%+ for typical usage
    ///
    /// - Parameter query: Search text entered by user
    func searchAddresses(query: String) {
        // MARK: Cancel Previous Search
        /// If user keeps typing, cancel the pending API call
        /// Only the final search (after typing stops) executes
        searchTask?.cancel()

        // MARK: Minimum Length Check
        /// Require 4+ characters to avoid too many broad results
        /// "123" could return thousands of addresses worldwide
        /// "1234 Main" returns reasonable results
        guard query.count >= 4 else {
            suggestions = []
            errorMessage = nil
            return
        }

        // MARK: API Key Validation
        /// Check configuration before making API call
        /// Fails fast with helpful error message
        if let error = GooglePlacesConfig.configurationError {
            Logger.error("Google Places API Error", error, code: 0)
            errorMessage = error
            return
        }

        // MARK: Debounce Timer
        /// Create new task that waits 300ms before executing
        /// If cancelled (by new search), never executes
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }

            // Execute actual API call
            await performSearch(query: query)
        }
    }

    /// Execute Google Places API request
    /// Handles request construction, error parsing, and response decoding
    ///
    /// - Parameter query: Search text to send to API
    private func performSearch(query: String) async {
        isLoading = true
        errorMessage = nil

        Logger.debug("Searching addresses for: \(query)", code: 0)

        do {
            // MARK: URL Construction
            /// Get autocomplete endpoint URL from config
            guard let url = URL(string: GooglePlacesConfig.autocompleteURL)
            else {
                throw NSError(
                    domain: "AddressSearchService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
                )
            }

            // MARK: Request Configuration
            /// Build POST request with headers
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            /// API key in header (not URL) per Google's requirements
            request.setValue(
                GooglePlacesConfig.apiKey,
                forHTTPHeaderField: "X-Goog-Api-Key"
            )

            // MARK: Request Body Construction
            /// Build JSON body with search parameters
            var requestBody: [String: Any] = [
                "input": query,  // Search text
                "languageCode": GooglePlacesConfig.languageCode,
            ]

            /// Add optional region restriction if configured
            /// Improves result relevance for local events
            if let regionCodes = GooglePlacesConfig.includedRegionCodes {
                requestBody["includedRegionCodes"] = regionCodes
            }

            /// Serialise to JSON data
            request.httpBody = try JSONSerialization.data(
                withJSONObject: requestBody
            )

            // MARK: Execute Request
            /// Perform async network request
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            // MARK: Response Validation
            /// Verify we received HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(
                    domain: "AddressSearchService",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
                )
            }

            Logger.debug(
                "API Response Status: \(httpResponse.statusCode)",
                code: 0
            )

            // MARK: Status Code Check
            /// 200 = Success, anything else = error
            guard httpResponse.statusCode == 200 else {
                // Try to extract error message from Google's error response
                if let errorJson = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                    let error = errorJson["error"] as? [String: Any],
                    let message = error["message"] as? String
                {
                    throw NSError(
                        domain: "GooglePlacesAPI",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    )
                }

                // Generic error if no message in response
                throw NSError(
                    domain: "AddressSearchService",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "API request failed with status \(httpResponse.statusCode)"
                    ]
                )
            }

            // MARK: Response Parsing
            /// Decode JSON response to Swift models
            let decoder = JSONDecoder()
            let autocompleteResponse = try decoder.decode(
                AutocompleteResponse.self,
                from: data
            )

            // MARK: Model Conversion
            /// Convert Google's nested structure to the flat model
            /// compactMap filters out any parsing failures
            let placeSuggestions =
                autocompleteResponse.suggestions?.compactMap {
                    wrapper -> PlaceSuggestion? in
                    let prediction = wrapper.placePrediction
                    return PlaceSuggestion(
                        description: prediction.text.text,
                        placeId: prediction.placeId
                    )
                } ?? []

            // MARK: Update UI
            /// All UI updates must happen on main thread
            await MainActor.run {
                self.suggestions = placeSuggestions
                self.isLoading = false
                Logger.success(
                    "Found \(placeSuggestions.count) address suggestions"
                )
            }

        } catch {
            // MARK: Error Handling
            /// Update UI with error state on main thread
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.suggestions = []
                Logger.error(
                    "Address search failed",
                    error.localizedDescription,
                    code: 0
                )
            }
        }
    }

    /// Clear all suggestions and reset state
    /// Called when user selects an address or dismisses dropdown
    func clearSuggestions() {
        searchTask?.cancel()  // Cancel any pending search
        suggestions = []
        errorMessage = nil
        isLoading = false
    }
}
