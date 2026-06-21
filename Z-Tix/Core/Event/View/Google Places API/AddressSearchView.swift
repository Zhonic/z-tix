//
//  AddressSearchView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 2/11/2025.
//

import SwiftUI

// MARK: - Address Search View

/// Custom text field with Google Places autocomplete functionality
/// Provides real-time address suggestions as user types
/// Used in CreateEventView for venue address input with professional UX
struct AddressSearchView: View {

    // MARK: - Properties

    /// The selected/entered address text
    /// Binds to parent view for two-way data flow
    @Binding var selectedAddress: String

    /// Placeholder text shown in empty text field
    var placeholder: String = "Please start typing the address"

    /// Optional title/label displayed above text field
    var title: String? = nil

    /// Service handling Google Places API calls
    /// Manages search requests, debouncing, and suggestion state
    @StateObject private var searchService = AddressSearchService()

    /// Local search text that updates in real-time as user types
    /// Separated from selectedAddress to allow typing before selection
    @State private var searchText: String = ""

    /// Controls visibility of autocomplete suggestions dropdown
    @State private var showSuggestions = false

    /// Focus state for keyboard management and suggestion visibility
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // MARK: Optional Title Label
            if let title = title {
                Text(title)
                    .foregroundColor(Color(.darkGray))
                    .fontWeight(.medium)
                    .font(.headline)
            }

            // MARK: Search Text Field
            /// Main input field with focus management
            TextField(placeholder, text: $searchText)
                .font(.system(size: 14))
                .focused($isTextFieldFocused)

                // MARK: Search Text Change Handler
                /// Triggers Google Places search as user types
                .onChange(of: searchText) { oldValue, newValue in
                    // Trigger API search with new text
                    searchService.searchAddresses(query: newValue)

                    // Show suggestions only if we have text and focus
                    showSuggestions = !newValue.isEmpty && isTextFieldFocused

                    // Update parent's bound value in real-time
                    selectedAddress = newValue
                }

                // MARK: Focus State Change Handler
                /// Show/hide suggestions based on focus state
                .onChange(of: isTextFieldFocused) { _, isFocused in
                    // Show/hide suggestions based on focus
                    if isFocused && !searchText.isEmpty {
                        showSuggestions = true
                    } else {
                        // Hide suggestions when field loses focus
                        showSuggestions = false
                    }
                }

                // MARK: Initialisation
                /// Populate text field with existing address if present
                .onAppear {
                    searchText = selectedAddress
                }

            Divider()

            // MARK: Suggestions Dropdown
            /// Shown below text field when suggestions available
            if showSuggestions {
                suggestionsDropdown
            }

            // MARK: Error Message
            /// Display API errors (rate limits, network issues, etc.)
            if let error = searchService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Suggestions Dropdown

    /// Autocomplete suggestions dropdown with loading and empty states
    /// Styled to match iOS conventions with smooth animations
    private var suggestionsDropdown: some View {
        VStack(spacing: 0) {

            if searchService.isLoading {
                // MARK: Loading State
                /// Shown while API request is in flight
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching addresses...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)

            } else if searchService.suggestions.isEmpty && searchText.count >= 3
            {
                // MARK: Empty State
                /// Shown when search returns no results
                /// Only after 3+ characters to avoid showing too early
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Text("No addresses found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)

            } else {
                // MARK: Suggestions List
                /// Display each suggestion with icon and dividers
                ForEach(searchService.suggestions) { suggestion in
                    Button {
                        selectAddress(suggestion)
                    } label: {
                        HStack(spacing: 10) {
                            // Map pin icon
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.cyan)
                                .font(.system(size: 16))

                            // Address text
                            Text(suggestion.description)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())  // Make entire row tappable
                    }
                    .buttonStyle(.plain)  // Remove default button styling

                    // Divider between suggestions (not after last item)
                    if suggestion.id != searchService.suggestions.last?.id {
                        Divider()
                            .padding(.leading, 38)  // Indent to align with text
                    }
                }
            }
        }
        // MARK: Dropdown Styling
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.top, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: 0.2), value: showSuggestions)
    }

    // MARK: - Helper Functions

    /// Handle selection of an address from suggestions
    /// Updates text fields, dismisses keyboard, and clears suggestions
    ///
    /// - Parameter suggestion: The selected place suggestion
    private func selectAddress(_ suggestion: PlaceSuggestion) {
        Logger.debug("Selected address: \(suggestion.description)", code: 0)

        // Update both local and bound address values
        searchText = suggestion.description
        selectedAddress = suggestion.description

        // Hide dropdown and dismiss keyboard
        showSuggestions = false
        isTextFieldFocused = false

        // Clear suggestions list to reset state
        searchService.clearSuggestions()
    }
}

// MARK: - Previews

/// Shows component in different states for development

#Preview("Default") {
    VStack {
        AddressSearchView(
            selectedAddress: .constant(""),
            placeholder: "Please start typing the address",
            title: "Event Venue"
        )
        .padding()

        Spacer()
    }
}

#Preview("With Initial Value") {
    VStack {
        AddressSearchView(
            selectedAddress: .constant("24 Spectrum Crescent, Clyde North"),
            placeholder: "Please start typing the address",
            title: "Event Venue"
        )
        .padding()

        Spacer()
    }
}
