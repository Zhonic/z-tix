//
//  CreateEventView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 20/10/2025.
//

import SwiftUI

// MARK: - Create/Edit Event View

/// Dual-purpose view for creating new events and editing existing ones
/// Intelligently adapts UI and behavior based on whether eventToEdit is provided
///
/// MODES:
/// 1. CREATE MODE (eventToEdit = nil):
///    - Empty form with default values
///    - "Create Event" button
///    - Shown in tab view (Add Event tab)
///    - Switches to home tab on success
///    - Cannot import tickets until saved (requires event ID)
///    - No delete button
///
/// 2. EDIT MODE (eventToEdit = Event):
///    - Pre-filled form with event data
///    - "Save Changes" button (disabled if no changes)
///    - Shown via navigation from event list
///    - Dismisses back to list on success
///    - Can import tickets immediately
///    - Shows ticket count
///    - Shows delete button
///    - Tracks changes to prevent unnecessary saves
///
/// KEY FEATURES:
/// - Google Places address autocomplete
/// - Dynamic time validation (prevents past times for today's events)
/// - Change detection in edit mode (enable save only if modified)
/// - Ticket import integration with count display
/// - Delete with cascade confirmation
/// - Success overlay with auto-dismiss
/// - Form validation (all required fields)
/// - Keyboard dismiss toolbar
struct CreateEventView: View {

    // MARK: - Input Properties

    /// Event to edit (nil = create mode, Event = edit mode)
    /// This single property determines entire view behavior
    let eventToEdit: Event?

    /// Tab selection binding (only used in create mode)
    /// Allows switching to home tab (index 0) after creation
    /// nil when navigated to (edit mode uses dismiss instead)
    let selectedTab: Binding<Int>?

    // MARK: - Event Details State

    /// Event name/title
    /// Example: "Summer Music Festival 2025", "Tech Conference"
    /// Required field (autocapitalised words)
    @State private var eventName = ""

    /// Event description/details
    /// Multi-line text field (3-6 lines visible)
    /// Example: "Join us for the biggest music festival of the summer..."
    /// Required field (autocapitalised sentences)
    @State private var eventDescription = ""

    /// Event date (day/month/year component only)
    /// Must be today or future date
    /// Affects time validation (see minimumTime)
    @State private var eventDate = Date()

    /// Event time (hour/minute component only)
    /// Validated based on selected date:
    /// - Today: Must be current time or later
    /// - Future: Any time allowed
    @State private var eventTime = Date()

    /// Event venue address
    /// Populated by Google Places API autocomplete
    /// Example: "24 Spectrum Crescent, Clyde North, VIC, 3978"
    /// Required field
    @State private var eventVenue = ""

    // MARK: - UI State

    /// Save/create operation in progress
    /// Shows loading spinner on button, disables interaction
    @State private var isProcessing = false

    /// Show success overlay message
    /// Green banner with checkmark slides up from bottom
    /// Auto-dismisses after 1.5 seconds
    @State private var showSuccessMessage = false

    // MARK: - Original Values (Edit Mode Change Detection)

    /// Original event name (snapshot at view load)
    /// Compared against current value to detect changes
    @State private var originalEventName = ""

    /// Original description for change detection
    @State private var originalEventDescription = ""

    /// Original date for change detection
    @State private var originalEventDate = Date()

    /// Original time for change detection
    @State private var originalEventTime = Date()

    /// Original venue for change detection
    @State private var originalEventVenue = ""

    // MARK: - Environment

    /// Dismiss action for navigation
    /// Used in edit mode to return to event list
    @Environment(\.dismiss) var dismiss

    /// Event view model for CRUD operations
    /// Shared across app via environment object
    @EnvironmentObject var eventViewModel: EventViewModel

    /// Ticket view model for count checking
    /// Private instance for this view only
    /// Used to check ticket count in edit mode
    @StateObject private var ticketViewModel = TicketViewModel()

    // MARK: - Sheet State

    /// Show ticket import sheet modal
    /// Only available in edit mode (needs event ID)
    @State private var showImportSheet = false

    // MARK: - Ticket Status State

    /// Number of tickets imported for this event
    /// Fetched on view appear and after import
    /// Displayed in ticket information section
    @State private var ticketCount: Int = 0

    /// Ticket count query in progress
    /// Shows loading indicator while checking
    @State private var isCheckingTickets = false

    // MARK: - Delete State

    /// Show delete confirmation dialog
    /// Only in edit mode
    @State private var showDeleteConfirmation = false

    // MARK: - Initialisation

    /// Custom initialiser handles both create and edit modes
    /// Sets up form state based on mode
    ///
    /// EDIT MODE BEHAVIOR:
    /// - Pre-fills all fields with event data
    /// - Stores original values for change detection
    /// - Enables smart save button (disabled if no changes)
    ///
    /// CREATE MODE BEHAVIOR:
    /// - Leaves all text fields empty
    /// - Sets dates to current time (default values)
    /// - No change detection needed (always allow save)
    ///
    /// WHY CUSTOM INIT?
    /// - SwiftUI @State requires initialisation before body
    /// - Conditional initialisation based on eventToEdit
    /// - State wrapper initialisation syntax: _property = State(initialValue:)
    ///
    /// - Parameters:
    ///   - eventToEdit: Event to edit (nil for create mode)
    ///   - selectedTab: Tab binding for navigation (nil in edit mode)
    init(eventToEdit: Event? = nil, selectedTab: Binding<Int>? = nil) {
        self.eventToEdit = eventToEdit
        self.selectedTab = selectedTab

        // MARK: Edit Mode Initialisation
        if let event = eventToEdit {
            // Set current values from existing event
            _eventName = State(initialValue: event.title)
            _eventDescription = State(initialValue: event.description)
            _eventDate = State(initialValue: event.date)
            _eventTime = State(initialValue: event.time)
            _eventVenue = State(initialValue: event.address)

            // Store original values for change detection
            // These never change after initialisation
            _originalEventName = State(initialValue: event.title)
            _originalEventDescription = State(initialValue: event.description)
            _originalEventDate = State(initialValue: event.date)
            _originalEventTime = State(initialValue: event.time)
            _originalEventVenue = State(initialValue: event.address)

        } else {
            // MARK: Create Mode Initialisation
            // Start with empty form
            _eventName = State(initialValue: "")
            _eventDescription = State(initialValue: "")
            _eventDate = State(initialValue: Date())
            _eventTime = State(initialValue: Date())
            _eventVenue = State(initialValue: "")

            // Original values (unused in create mode but required)
            _originalEventName = State(initialValue: "")
            _originalEventDescription = State(initialValue: "")
            _originalEventDate = State(initialValue: Date())
            _originalEventTime = State(initialValue: Date())
            _originalEventVenue = State(initialValue: "")
        }
    }

    // MARK: - Computed Properties

    /// Checks if any field has been modified in edit mode
    /// Used to enable/disable save button intelligently
    ///
    /// LOGIC:
    /// - Create mode: Always returns true (allow saving)
    /// - Edit mode: Compares each field to original value
    /// - Returns true if ANY field has changed
    ///
    /// WHY THIS MATTERS:
    /// - Prevents unnecessary Firestore writes
    /// - Saves API quota and costs
    /// - Better UX (can't save without changes)
    /// - Provides visual feedback (disabled button)
    ///
    /// FIELDS CHECKED:
    /// - Event name
    /// - Event description
    /// - Event date
    /// - Event time
    /// - Event venue
    var hasChanges: Bool {
        // Create mode: always allow saving new event
        guard isEditMode else {
            return true
        }

        // Edit mode: check each field for modifications
        let nameChanged = eventName != originalEventName
        let descriptionChanged = eventDescription != originalEventDescription
        let dateChanged = eventDate != originalEventDate
        let timeChanged = eventTime != originalEventTime
        let venueChanged = eventVenue != originalEventVenue

        // Return true if ANY field was modified
        return nameChanged || descriptionChanged || dateChanged || timeChanged
            || venueChanged
    }

    /// Determines if view is in edit mode
    /// Simple check: presence of eventToEdit means editing
    var isEditMode: Bool {
        eventToEdit != nil
    }

    // MARK: - Computed Properties for Button Text

    /// Dynamic button text based on mode and processing state
    /// STATES:
    /// - Edit + Processing: "Saving Changes..."
    /// - Edit + Not Processing: "Save Changes"
    /// - Create + Processing: "Creating Event..."
    /// - Create + Not Processing: "Create Event"
    private var saveButtonText: String {
        if isProcessing {
            return isEditMode ? "Saving Changes..." : "Creating Event..."
        } else {
            return isEditMode ? "Save Changes" : "Create Event"
        }
    }

    /// Determines if save button should be disabled
    /// DISABLED WHEN:
    /// - Form is invalid (missing required fields)
    /// - Processing is in progress (prevents double submission)
    /// - Edit mode with no changes (prevents unnecessary saves)
    ///
    /// ENABLED WHEN:
    /// - Create mode with valid form
    /// - Edit mode with valid form and changes detected
    private var saveButtonDisabled: Bool {
        !formIsValid || isProcessing || (isEditMode && !hasChanges)
    }

    // MARK: - Computed Property for Success Message

    /// Success message text varies by mode
    /// - Edit mode: "Changes saved successfully!"
    /// - Create mode: "Event created successfully!"
    private var successMessageText: String {
        isEditMode
            ? "Changes saved successfully!" : "Event created successfully!"
    }

    // MARK: - Dynamic Time Range Based on Selected Date

    /// Calculates minimum allowed time based on selected event date
    /// Prevents creating events in the past
    ///
    /// LOGIC:
    /// - If event date is TODAY: Minimum time = current time
    /// - If event date is FUTURE: No restriction (nil = all times allowed)
    ///
    /// WHY DYNAMIC?
    /// - User might select today, then past time → Invalid
    /// - User might select future date → Any time is valid
    /// - This prevents the first case while allowing the second
    ///
    /// EXAMPLE SCENARIOS:
    /// 1. Select today (Nov 8), time 2:00 PM, current time 3:00 PM
    ///    → minTime = 3:00 PM (prevents past time)
    ///
    /// 2. Select tomorrow (Nov 9), time 2:00 PM, current time 3:00 PM
    ///    → minTime = nil (2:00 PM tomorrow is valid)
    ///
    /// 3. User changes date from tomorrow to today
    ///    → Time picker updates to restrict past times
    ///
    /// - Returns: Current Date if today, nil if future date
    private var minimumTime: Date? {
        let calendar = Calendar.current
        let now = Date()

        // Check if the selected event date is today
        let isToday = calendar.isDateInToday(eventDate)

        if isToday {
            // For today, restrict to current time onwards
            return now
        } else {
            // For future dates, allow all times (no restriction)
            return nil
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Event Information Section
                Section(header: Text("Event Information")) {

                    // MARK: Event Name Field
                    /// Text input for event title
                    /// Capitalises first letter of each word
                    /// Autocorrect disabled (event names often unique)
                    TextField("Event Name", text: $eventName)
                        .autocapitalization(.words)
                        .autocorrectionDisabled(true)

                    // MARK: Event Description Field
                    /// Multi-line text input for event details
                    /// Vertical axis allows expansion
                    /// 3-6 lines visible (scrollable if longer)
                    /// Capitalises first letter of sentences
                    TextField(
                        "Event Description",
                        text: $eventDescription,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .autocapitalization(.sentences)

                    // MARK: Event Date Picker
                    /// Date selection (day/month/year)
                    /// Restricted to today and future dates (Date()...)
                    /// Only date component shown (no time)
                    DatePicker(
                        "Event Date",
                        selection: $eventDate,
                        in: Date()...,  // Today onwards (prevents past dates)
                        displayedComponents: .date
                    )

                    // MARK: Event Time Picker (Dynamic Validation)
                    /// Time selection with conditional restrictions
                    /// Two different pickers based on selected date
                    if let minTime = minimumTime {
                        // TODAY: Time must be current or future
                        DatePicker(
                            "Event Time",
                            selection: $eventTime,
                            in: minTime...,  // Current time onwards
                            displayedComponents: .hourAndMinute
                        )
                    } else {
                        // FUTURE DATE: Any time allowed
                        DatePicker(
                            "Event Time",
                            selection: $eventTime,
                            displayedComponents: .hourAndMinute
                        )
                    }

                    // MARK: Event Venue Field (Google Places)
                    /// Custom address search with autocomplete
                    /// Integrates Google Places API
                    /// Shows suggestions as user types
                    AddressSearchView(
                        selectedAddress: $eventVenue,
                        placeholder: "Please start typing the venue address...",
                        title: "Event Venue"
                    )
                }

                // MARK: Ticket Information Section
                Section(header: Text("Ticket Information")) {

                    // MARK: Import Tickets Button
                    /// Opens ticket import sheet
                    /// Disabled in create mode (needs event ID)
                    Button {
                        showImportSheet = true
                    } label: {
                        Text("Import Tickets")
                    }
                    .disabled(!isEditMode)

                    // MARK: Status Messages
                    if !isEditMode {
                        // CREATE MODE: Explain why import is disabled
                        /// Informs user to save first
                        /// Tickets need event ID from Firestore
                        Text("Save the event first before importing tickets")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        // EDIT MODE: Show ticket count or status
                        ticketStatusView
                    }
                }

                // MARK: Save Button Section
                Section {
                    Button {
                        isProcessing = true
                        Task {
                            do {
                                if isEditMode {
                                    // MARK: Update Existing Event
                                    try await eventViewModel.updateEvent(
                                        eventId: eventToEdit!.id,
                                        title: eventName,
                                        description: eventDescription,
                                        date: eventDate,
                                        time: eventTime,
                                        address: eventVenue
                                    )
                                } else {
                                    // MARK: Create New Event
                                    try await eventViewModel.createEvent(
                                        title: eventName,
                                        description: eventDescription,
                                        date: eventDate,
                                        time: eventTime,
                                        address: eventVenue
                                    )
                                    // Clear form after successful creation
                                    clearForm()
                                }

                                // MARK: Show Success and Navigate
                                await MainActor.run {
                                    isProcessing = false
                                    showSuccessMessage = true

                                    // Delay before navigation (let user see success)
                                    DispatchQueue.main.asyncAfter(
                                        deadline: .now() + 1.5
                                    ) {
                                        if isEditMode {
                                            // Edit mode: Dismiss back to event list
                                            dismiss()
                                        } else {
                                            // Create mode: Switch to home tab (index 0)
                                            selectedTab?.wrappedValue = 0
                                        }
                                    }
                                }
                            } catch {
                                // MARK: Error Handling
                                /// Error already handled in view model
                                /// Alert shown via eventViewModel.alertItem
                                /// Just reset processing state here
                                await MainActor.run {
                                    isProcessing = false
                                }
                            }
                        }
                    } label: {
                        saveButtonLabel
                    }
                    .disabled(
                        saveButtonDisabled
                    )
                }

                // MARK: Delete Button Section (Edit Mode Only)
                if isEditMode {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("Delete Event")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                }
            }
            // MARK: Navigation Configuration
            .navigationTitle(
                isEditMode ? "Edit Event Information" : "Add Event"
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isEditMode)  // Hide default back in edit mode
            .keyboardDismissToolbar()  // Custom toolbar with Done button

            // MARK: Custom Back Button (Edit Mode)
            .toolbar {
                // Only show back button in edit mode
                if isEditMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            dismiss()
                        }
                    }
                }
            }

            // MARK: Error Alert
            /// Shows errors from view model operations
            /// Displayed via eventViewModel.alertItem
            .alert(item: $eventViewModel.alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: alertItem.dismissButton
                )
            }

            // MARK: Delete Confirmation Dialog
            .confirmationDialog(
                "Delete Event?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Event", role: .destructive) {
                    Task {
                        // Perform cascade deletion
                        await eventViewModel.deleteEvent(
                            eventId: eventToEdit!.id
                        )

                        // Brief delay to show success alert
                        try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
                        await MainActor.run {
                            // Clear alert and dismiss
                            eventViewModel.alertItem = nil
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "Are you sure you want to delete '\(eventName)'? This action cannot be undone and all tickets and scan logs for this event will be deleted."
                )
            }

            // MARK: Success Message Overlay
            .overlay(
                successMessageOverlay
            )

            // MARK: Ticket Import Sheet
            .sheet(isPresented: $showImportSheet) {
                if let event = eventToEdit {
                    ImportTicketsView(
                        eventId: event.id,
                        isPresented: $showImportSheet
                    )
                }
            }

            // MARK: Initial Ticket Count Load
            /// Runs when view appears in edit mode
            /// id parameter ensures re-run if different event
            .task(id: eventToEdit?.id) {
                if let event = eventToEdit {
                    await checkTicketCount(for: event.id)

                }
            }

            // MARK: Refresh Ticket Count After Import
            /// Detects when import sheet closes
            /// Refreshes count to show newly imported tickets
            .onChange(of: showImportSheet) { oldValue, newValue in
                // Refresh ticket count when import sheet is dismissed
                if oldValue == true && newValue == false,
                    let event = eventToEdit
                {
                    Task {
                        await checkTicketCount(for: event.id)
                    }
                }
            }
        }
    }

    // MARK: - View Components

    /// Save button label with loading indicator
    /// Shows spinner when processing, text only otherwise
    @ViewBuilder
    private var saveButtonLabel: some View {
        HStack {
            Spacer()

            // MARK: Loading Spinner
            /// Only shown during processing
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.trailing, 8)
            }

            // MARK: Button Text
            /// Dynamic text based on mode and state
            Text(saveButtonText)
                .fontWeight(.semibold)

            Spacer()
        }
    }

    /// Ticket status display in edit mode
    /// Shows count, loading state, or "no tickets" message
    @ViewBuilder
    private var ticketStatusView: some View {
        if isCheckingTickets {
            // MARK: Loading State
            HStack {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Checking tickets...")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        } else if ticketCount > 0 {
            // MARK: Tickets Imported
            /// Green text showing count
            /// Proper pluralisation (ticket vs tickets)
            Text(
                "\(ticketCount) ticket\(ticketCount == 1 ? "" : "s") imported"
            )
            .foregroundColor(.green)
            .font(.caption)
        } else {
            // MARK: No Tickets
            Text("No tickets have been imported yet")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }

    /// Success message overlay
    /// Green banner with checkmark that slides up from bottom
    @ViewBuilder
    private var successMessageOverlay: some View {
        if showSuccessMessage {
            VStack {
                Spacer()

                // MARK: Success Banner
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text(successMessageText)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color.green)
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding(.bottom, 50)  // Above tab bar
            }
            .transition(.move(edge: .bottom))  // Slide up animation
            .animation(.spring(), value: showSuccessMessage)

            // MARK: Auto-Dismiss
            /// Automatically hide after 1.5 seconds
            .onAppear {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.5
                ) {
                    showSuccessMessage = false
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Form validation check
    /// Returns true if all required fields are filled
    ///
    /// REQUIRED FIELDS:
    /// - Event name (must not be empty)
    /// - Event description (must not be empty)
    /// - Event venue (must not be empty)
    ///
    /// NOT CHECKED:
    /// - Date (always has value, defaults to today)
    /// - Time (always has value, defaults to now)
    var formIsValid: Bool {
        return !eventName.isEmpty
            && !eventDescription.isEmpty
            && !eventVenue.isEmpty
    }

    /// Clears all form fields
    /// Used after successful event creation
    /// Not called in edit mode (dismissed instead)
    func clearForm() {
        eventName = ""
        eventDescription = ""
        eventDate = Date()
        eventTime = Date()
        eventVenue = ""
    }

    /// Fetches ticket count for event
    /// Shows loading state while checking
    /// Updates ticketCount with result
    ///
    /// USAGE:
    /// - Called on view appear in edit mode
    /// - Called after import sheet dismissal
    /// - Updates UI to show current ticket count
    ///
    /// - Parameter eventId: Event to check tickets for
    func checkTicketCount(for eventId: String) async {
        isCheckingTickets = true
        await ticketViewModel.fetchTickets(for: eventId)
        await MainActor.run {
            ticketCount = ticketViewModel.tickets.count
            isCheckingTickets = false
        }
    }
}

// MARK: - Previews

#Preview("Create Mode") {
    CreateEventView(selectedTab: .constant(2))
        .environmentObject(EventViewModel())
}

#Preview("Edit Mode") {
    CreateEventView(eventToEdit: Event.MOCK_EVENT)
        .environmentObject(EventViewModel())
}

// MARK: - Architecture Notes

/*
 DUAL-MODE DESIGN:

 This view handles both create and edit with minimal code duplication:

 1. CONDITIONAL INITIALISATION:
    - init() checks eventToEdit
    - Pre-fills or leaves empty
    - Sets up change detection

 2. CONDITIONAL UI:
    - isEditMode drives UI differences
    - Button text varies
    - Delete button only in edit
    - Import only in edit

 3. CONDITIONAL NAVIGATION:
    - Create: Switch tabs
    - Edit: Dismiss navigation

 BENEFITS:
 - Single source of truth for event form
 - Consistent validation logic
 - Shared error handling
 - Easier maintenance

 ALTERNATIVE APPROACH:
 - Separate CreateEventView and EditEventView
 - More code duplication
 - Harder to keep in sync
 - Decision: Current approach is better

 CHANGE DETECTION SYSTEM:

 Edit mode uses sophisticated change detection:

 1. STORE ORIGINALS:
    - Captured in init()
    - Never modified
    - Used for comparison

 2. COMPARE ON DEMAND:
    - hasChanges computed property
    - Checks each field
    - Returns true if ANY changed

 3. ENABLE/DISABLE SAVE:
    - Save disabled if no changes
    - Prevents unnecessary API calls
    - Visual feedback to user

 WHY THIS MATTERS:
 - Saves Firestore quota
 - Reduces network traffic
 - Better user experience
 - Prevents accidental saves

 DYNAMIC TIME VALIDATION:

 Time picker adapts to selected date:

 1. TODAY'S DATE:
    - Minimum time = now
    - Prevents past events
    - Updates as time passes

 2. FUTURE DATE:
    - No minimum time
    - Any time valid
    - Full 24-hour selection

 IMPLEMENTATION:
 - Two different DatePickers
 - Conditional rendering
 - minimumTime computed property
 - Re-evaluates on date change

 EDGE CASES HANDLED:
 - User selects today, past time → Blocked
 - User selects future, any time → Allowed
 - User changes from future to today → Restriction applies
 - User changes from today to future → Restriction removed

 TICKET INTEGRATION:

 Ticket import deeply integrated:

 1. CREATE MODE:
    - Import button disabled
    - Explanation shown
    - Must save event first

 2. EDIT MODE:
    - Import button enabled
    - Count displayed
    - Updates after import

 WHY DISABLED IN CREATE?
 - Tickets need event ID
 - Event ID generated by Firestore
 - ID doesn't exist until saved
 - Could auto-save, but clearer UX to require explicit save

 SUCCESS FEEDBACK:

 Multiple feedback mechanisms:

 1. SUCCESS OVERLAY:
    - Green banner
    - Checkmark icon
    - Custom message
    - Auto-dismiss
    - Slides up animation

 2. NAVIGATION:
    - Delayed 1.5s
    - Allows seeing success
    - Then auto-navigate

 3. LIST UPDATE:
    - EventViewModel refreshes
    - New/edited event appears
    - Sorted chronologically

 DELETE CASCADE:

 Delete requires confirmation:

 1. CONFIRMATION DIALOG:
    - Shows event name
    - Warns about cascade
    - Destructive button style
    - Cancel option

 2. CASCADE DELETION:
    - Deletes all tickets
    - Deletes all scan logs
    - Deletes event document
    - See EventViewModel.deleteEvent()

 3. FEEDBACK:
    - Shows success alert
    - Brief delay
    - Dismisses to list

 KEYBOARD HANDLING:

 Form includes keyboard toolbar:

 - .keyboardDismissToolbar() extension
 - Done button above keyboard
 - Dismisses on tap
 - Better iPad UX

 FUTURE ENHANCEMENTS:

 - Image upload (event poster)
 - Recurring events
 - Multiple venues
 - Co-organizers
 - Event categories
 - Ticket price tiers
 - Early bird discounts
 - Capacity limits
 - Age restrictions
 */
