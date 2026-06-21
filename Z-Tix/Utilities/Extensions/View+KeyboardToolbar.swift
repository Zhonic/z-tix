//
//  View+KeyboardToolbar.swift
//  Z-Tix
//
//  Created by Harnish Patel on 5/11/2025.
//

import SwiftUI

// MARK: - View Extension for Keyboard Toolbar

/// Extension adding keyboard dismiss functionality to any SwiftUI View
/// Provides a toolbar above the keyboard with "Done" button
///
/// PROBLEM SOLVED:
/// SwiftUI doesn't provide built-in keyboard dismiss button
/// Users on iPad expect "Done" button above keyboard
/// On iPhone, users swipe down, but button is more discoverable
///
/// USAGE:
/// TextField("Email", text: $email)
///     .keyboardDismissToolbar()  // ← Adds Done button
extension View {

    // MARK: - Keyboard Dismiss Toolbar

    /// Adds a toolbar above the keyboard with a "Done" button
    /// Button dismisses keyboard when tapped
    ///
    /// BEHAVIOR:
    /// - Appears above keyboard automatically
    /// - Only visible when keyboard is shown
    /// - Dismisses keyboard on tap
    /// - Works with any text input field
    ///
    /// PLACEMENT:
    /// - .keyboard placement puts toolbar above keyboard
    /// - Spacer pushes button to trailing edge (right side)
    /// - Consistent with iOS conventions
    ///
    /// - Returns: View with keyboard dismiss toolbar
    func keyboardDismissToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                // MARK: Spacer
                /// Pushes Done button to right side
                /// Left side remains empty
                /// Matches iOS keyboard toolbar pattern
                Spacer()

                // MARK: Done Button
                /// Tapping dismisses keyboard
                /// Styled in Z-Tix brand color (cyan)
                Button("Done") {
                    // MARK: Dismiss Keyboard
                    /// Sends resignFirstResponder to responder chain
                    /// This is the "official" way to dismiss keyboard
                    /// Works for TextField, TextEditor, SecureField
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,  // Target: First responder (active field)
                        from: nil,  // Sender: Not needed
                        for: nil  // Event: Not needed
                    )
                }
                .foregroundColor(.cyan)  // Z-Tix brand color
                .fontWeight(.semibold)  // Emphasis
            }
        }
    }
}

// MARK: - Usage Examples

/*
 TYPICAL IMPLEMENTATIONS:

 1. SINGLE TEXT FIELD:
 struct LoginView: View {
     @State private var email = ""

     var body: some View {
         TextField("Email", text: $email)
             .keyboardDismissToolbar()  // ← Add Done button
     }
 }

 2. MULTIPLE FIELDS:
 struct RegistrationView: View {
     @State private var email = ""
     @State private var password = ""

     var body: some View {
         VStack {
             TextField("Email", text: $email)
                 .keyboardDismissToolbar()

             SecureField("Password", text: $password)
                 .keyboardDismissToolbar()
         }
     }
 }

 3. FORM WITH MULTIPLE INPUTS:
 Form {
     Section {
         TextField("First Name", text: $firstName)
         TextField("Last Name", text: $lastName)
         TextField("Email", text: $email)
     }
     .keyboardDismissToolbar()  // ← Applies to all fields in section
 }

 4. TEXT EDITOR:
 TextEditor(text: $eventDescription)
     .frame(height: 100)
     .keyboardDismissToolbar()

 5. SEARCH FIELD:
 SearchBar(text: $searchText)
     .keyboardDismissToolbar()
 */

// MARK: - Implementation Details

/*
 HOW IT WORKS:

 1. TOOLBAR PLACEMENT:
    - .keyboard placement is SwiftUI 3.0+
    - Appears in accessory view above keyboard
    - Automatically shown/hidden with keyboard
    - No manual tracking needed

 2. RESPONDER CHAIN:
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )

    - Selector: Method to invoke (resignFirstResponder)
    - Target: nil means "first responder in chain"
    - From: Sender of action (not needed here)
    - For: Associated event (not needed here)

 3. FIRST RESPONDER:
    - iOS tracks which view has keyboard focus
    - resignFirstResponder() tells it to give up focus
    - Keyboard automatically dismisses
    - Works for any UITextField/UITextView

 4. TOOLBAR GROUP:
    - ToolbarItemGroup groups multiple items
    - .keyboard placement for above-keyboard location
    - Spacer + Button creates right-aligned layout
 */

// MARK: - Design Decisions

/*
 WHY THIS APPROACH?

 1. REUSABILITY:
    - Single modifier for all text inputs
    - Consistent behavior app-wide
    - Easy to apply everywhere

 2. DISCOVERABILITY:
    - Done button is obvious
    - Users know how to dismiss
    - Better UX than hidden gestures

 3. ACCESSIBILITY:
    - Button is tappable target
    - VoiceOver reads "Done, button"
    - Keyboard shortcuts work

 4. PLATFORM CONSISTENCY:
    - Matches iOS keyboard toolbar pattern
    - Similar to Safari, Messages, etc.
    - Users familiar with interaction

 ALTERNATIVES CONSIDERED:

 1. TAP GESTURE ON BACKGROUND:
    .onTapGesture {
        UIApplication.shared.sendAction(...)
    }

    Pros: Gesture-based, minimal UI
    Cons: Not discoverable, conflicts with other gestures

 2. SWIPE DOWN GESTURE:
    .gesture(DragGesture()...)

    Pros: Modern iOS pattern
    Cons: Not obvious to users, iPad users expect button

 3. HIDE KEYBOARD BUTTON IN FIELD:
    TextField with built-in dismiss

    Pros: Compact
    Cons: Not standard SwiftUI, custom implementation

 DECISION: Toolbar approach best balances discoverability and UX
 */

// MARK: - Platform Considerations

/*
 IPHONE vs IPAD:

 IPHONE:
 - Keyboard covers ~40% of screen
 - Users can swipe down to dismiss
 - Done button is additional convenience
 - Toolbar appears above keyboard

 IPAD:
 - Floating keyboard option
 - Split keyboard option
 - Done button more expected
 - Toolbar integrates with keyboard UI

 BOTH BENEFIT:
 - Consistent experience
 - Explicit dismiss action
 - No guessing how to close keyboard
 */

// MARK: - Styling Customisation

/*
 CUSTOMISABLE STYLING:

 Current: .cyan color, .semibold weight

 Could extend for custom styling:

 func keyboardDismissToolbar(
     buttonText: String = "Done",
     color: Color = .cyan,
     weight: Font.Weight = .semibold
 ) -> some View {
     self.toolbar {
         ToolbarItemGroup(placement: .keyboard) {
             Spacer()
             Button(buttonText) {
                 UIApplication.shared.sendAction(...)
             }
             .foregroundColor(color)
             .fontWeight(weight)
         }
     }
 }

 Usage:
 TextField(...)
     .keyboardDismissToolbar(
         buttonText: "Close",
         color: .red,
         weight: .bold
     )
 */

// MARK: - Keyboard Management Best Practices

/*
 COMPLETE KEYBOARD HANDLING:

 1. SUBMIT BUTTON:
    TextField("Email", text: $email)
        .keyboardDismissToolbar()
        .submitLabel(.done)  // Return key says "Done"
        .onSubmit {
            // Handle submission
        }

 2. FOCUS MANAGEMENT:
    @FocusState private var focusedField: Field?

    TextField("Email", text: $email)
        .focused($focusedField, equals: .email)
        .keyboardDismissToolbar()

    // Programmatically dismiss:
    focusedField = nil

 3. KEYBOARD TYPE:
    TextField("Email", text: $email)
        .keyboardType(.emailAddress)  // Email keyboard
        .keyboardDismissToolbar()

 4. AUTOCORRECT:
    TextField("Username", text: $username)
        .autocorrectionDisabled()
        .keyboardDismissToolbar()

 5. CONTENT TYPE:
    TextField("Email", text: $email)
        .textContentType(.emailAddress)  // Password autofill
        .keyboardDismissToolbar()
 */

// MARK: - Accessibility

/*
 ACCESSIBILITY FEATURES:

 BUILT-IN SUPPORT:
 - VoiceOver reads "Done, button"
 - Switch Control can activate button
 - Voice Control: "Tap Done"
 - Keyboard shortcuts work (Cmd+W to close)

 IMPROVEMENTS POSSIBLE:
 Button("Done") {
     // ...
 }
 .accessibilityLabel("Dismiss keyboard")
 .accessibilityHint("Closes the on-screen keyboard")

 KEYBOARD NAVIGATION:
 - Tab key moves between fields
 - Return key on last field could dismiss
 - Done button provides explicit option
 */

// MARK: - Testing Considerations

/*
 UI TESTING:

 func testKeyboardDismiss() {
     let app = XCUIApplication()

     // Tap text field (shows keyboard)
     let textField = app.textFields["Email"]
     textField.tap()

     // Verify keyboard is shown
     XCTAssertTrue(app.keyboards.element.exists)

     // Tap Done button
     app.buttons["Done"].tap()

     // Verify keyboard is dismissed
     XCTAssertFalse(app.keyboards.element.exists)
 }
 */
