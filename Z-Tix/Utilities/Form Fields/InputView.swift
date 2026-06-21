//
//  InputView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 14/10/2025.
//

import SwiftUI

// MARK: - Input View Component

/// Reusable text input component with label and divider
/// Provides consistent styling for forms throughout the app
///
/// FEATURES:
/// - Label above input field
/// - Standard or secure field option
/// - Bottom divider line
/// - Consistent sizing and spacing
/// - Dark mode support
///
/// USAGE:
/// Login forms, registration, event creation, any text input
struct InputView: View {

    // MARK: - Properties

    /// Two-way binding to text value
    /// Updates parent view when text changes
    @Binding var text: String

    /// Label text displayed above field
    /// Example: "Email Address", "Password", "Event Name"
    let title: String

    /// Placeholder text shown when field is empty
    /// Example: "name@example.com", "Enter your password"
    let placeholder: String

    /// Whether to use SecureField (password) or TextField (plain text)
    /// Default: false (plain text)
    var isSecureField = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: Label
            /// Title text above input field
            /// Consistent styling across all forms
            Text(title)
                .foregroundColor(Color(.darkGray))  // Subtle, not too prominent
                .fontWeight(.semibold)  // Slightly bold for clarity
                .font(.footnote)  // Small, space-efficient

            // MARK: Input Field
            /// Conditional rendering based on security requirement
            if isSecureField {
                // MARK: Secure Field (Password)
                /// Dots/asterisks hide characters
                /// No copy/paste by default
                /// Suitable for passwords, PINs
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
            } else {
                // MARK: Text Field (Plain Text)
                /// Standard text input
                /// Visible characters
                /// Suitable for email, name, etc.
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
            }

            // MARK: Divider
            /// Bottom line separating fields
            /// Provides visual structure
            /// Subtle visual boundary
            Divider()
        }
    }
}

// MARK: - Preview

#Preview {
    InputView(
        text: .constant(""),
        title: "Email Address",
        placeholder: "name@example.com"
    )
}

// MARK: - Usage Examples

/*
 TYPICAL IMPLEMENTATIONS:

 1. EMAIL INPUT:
 struct LoginView: View {
     @State private var email = ""

     var body: some View {
         InputView(
             text: $email,
             title: "Email Address",
             placeholder: "name@example.com"
         )
         .keyboardType(.emailAddress)
         .autocapitalization(.none)
         .autocorrectionDisabled(true)
     }
 }

 2. PASSWORD INPUT:
 @State private var password = ""

 InputView(
     text: $password,
     title: "Password",
     placeholder: "Enter your password",
     isSecureField: true  // ← Dots instead of text
 )

 3. FORM WITH MULTIPLE INPUTS:
 VStack(spacing: 24) {
     InputView(
         text: $email,
         title: "Email Address",
         placeholder: "name@example.com"
     )

     InputView(
         text: $firstName,
         title: "First Name",
         placeholder: "Enter your first name"
     )

     InputView(
         text: $lastName,
         title: "Last Name",
         placeholder: "Enter your last name"
     )
 }
 .padding(.horizontal)

 4. WITH VALIDATION FEEDBACK:
 VStack {
     InputView(
         text: $email,
         title: "Email Address",
         placeholder: "name@example.com"
     )

     if !email.isEmpty && !email.isValidEmail {
         Text("Invalid email format")
             .font(.caption)
             .foregroundColor(.red)
     }
 }

 5. EVENT CREATION:
 Form {
     Section(header: Text("Event Information")) {
         InputView(
             text: $eventName,
             title: "Event Name",
             placeholder: "Summer Festival 2025"
         )

         InputView(
             text: $eventDescription,
             title: "Description",
             placeholder: "Describe your event"
         )
     }
 }
 */

// MARK: - Component Design

/*
 SPACING RATIONALE:
 - 12pt between label and input: Comfortable reading
 - VStack auto-spacing between fields: Clean separation
 - Divider provides visual boundary

 COLOR SCHEME:
 - Label: .darkGray - Subtle, doesn't compete with input
 - Input: .primary - System color, adapts to theme
 - Divider: .gray - Standard iOS divider color
 */

// MARK: - Typography Hierarchy

/*
 FONT SIZES:

 Title (Label): .footnote (~13pt)
 - Small but readable
 - Doesn't dominate space
 - Clear hierarchy

 Input: .system(size: 14)
 - Slightly larger than label
 - Comfortable for typing
 - Good readability

 WHY NOT LARGER?
 - Mobile screens have limited space
 - Larger fonts push content off screen
 - 14pt is iOS standard for input text
 - Matches native UITextField size
 */

// MARK: - Secure Field Behavior

/*
 SECUREFIELD vs TEXTFIELD:

 SECUREFIELD (isSecureField: true):
 - Characters hidden (•••)
 - Copy/paste limited
 - AutoFill supported
 - Suitable for: passwords, PINs, secrets

 TEXTFIELD (isSecureField: false):
 - Characters visible
 - Copy/paste enabled
 - AutoCorrect/AutoCapitalize work
 - Suitable for: email, name, description

 SECURITY CONSIDERATIONS:
 - SecureField doesn't mean secure storage
 - String value still in memory
 - Server-side validation required
 - HTTPS for network transmission
 */

// MARK: - Customisation Options

/*
 COMMON MODIFIERS TO ADD:

 1. KEYBOARD TYPE:
 InputView(...)
     .keyboardType(.emailAddress)  // Email keyboard layout
     .keyboardType(.numberPad)     // Numbers only
     .keyboardType(.phonePad)      // Phone number

 2. TEXT CONTENT TYPE:
 InputView(...)
     .textContentType(.emailAddress)  // Password autofill hint
     .textContentType(.password)      // iCloud Keychain
     .textContentType(.name)          // Contact autofill

 3. CAPITALISATION:
 InputView(...)
     .autocapitalization(.none)       // No auto caps (email)
     .autocapitalization(.words)      // Capitalize Each Word
     .autocapitalization(.sentences)  // Standard (first letter)

 4. AUTOCORRECT:
 InputView(...)
     .autocorrectionDisabled(true)    // No autocorrect (username)
     .autocorrectionDisabled(false)   // Allow autocorrect (default)

 5. SUBMIT LABEL:
 InputView(...)
     .submitLabel(.done)    // Return key says "Done"
     .submitLabel(.next)    // Return key says "Next"
     .submitLabel(.go)      // Return key says "Go"

 6. ON SUBMIT:
 InputView(...)
     .onSubmit {
         // Handle return key press
         submitForm()
     }
 */

// MARK: - Accessibility

/*
 ACCESSIBILITY SUPPORT:

 BUILT-IN:
 - Label read by VoiceOver before field
 - Placeholder provides context
 - TextField/SecureField are accessible
 - Dynamic Type supported (fonts scale)

 IMPROVEMENTS POSSIBLE:

 InputView(...)
     .accessibilityLabel(title)  // Explicit label
     .accessibilityHint("Enter your \(title.lowercased())")  // Guidance
     .accessibilityValue(text.isEmpty ? "Empty" : text)  // Current value

 VOICEOVER EXPERIENCE:
 1. Focus moves to field
 2. Reads: "Email Address, text field, name@example.com"
 3. User types
 4. Double-tap to edit
 5. Read character feedback as typing
 */

// MARK: - Dark Mode Support

/*
 DARK MODE HANDLING:

 AUTOMATIC ADAPTATION:
 - Color(.darkGray) adapts to theme
 - .primary color inverts in dark mode
 - Divider color adjusts automatically
 - No manual theme management needed

 COLOR BEHAVIOR:
 Light Mode: .darkGray → Dark gray on white
 Dark Mode: .darkGray → Light gray on dark

 Light Mode: .primary → Black text
 Dark Mode: .primary → White text

 CONSISTENT APPEARANCE:
 - Always readable contrast
 - Follows system theme
 - No jarring color switches
 */

// MARK: - Performance Considerations

/*
 VIEW UPDATES:

 BINDING EFFICIENCY:
 - @Binding creates two-way link
 - Updates flow through binding
 - Only view owning @State rerenders
 - Child view (InputView) is lightweight

 RERENDERING:
 - Each keystroke updates binding
 - Parent view rerenders
 - InputView rerenders (new text)
 - Very fast (native TextField)

 OPTIMISATION (if needed):
 - Could debounce API calls
 - Could throttle validation
 - Not needed for typing display
 */

// MARK: - Testing

/*
 UI TESTING:

 func testInputView() {
     let app = XCUIApplication()

     // Find text field by placeholder
     let emailField = app.textFields["name@example.com"]

     // Type text
     emailField.tap()
     emailField.typeText("test@example.com")

     // Verify text entered
     XCTAssertEqual(emailField.value as? String, "test@example.com")
 }

 UNIT TESTING VALIDATION:
 func testEmailValidation() {
     var email = ""
     let binding = Binding(
         get: { email },
         set: { email = $0 }
     )

     // Create view
     let inputView = InputView(
         text: binding,
         title: "Email",
         placeholder: "Enter email"
     )

     // Test binding updates
     email = "test@example.com"
     XCTAssertEqual(email, "test@example.com")
 }
 */

// MARK: - Future Enhancements

/*
 POTENTIAL IMPROVEMENTS:

 1. ERROR STATE:
 InputView(..., isError: true)
 - Red border
 - Error icon
 - Error message below

 2. VALIDATION INDICATOR:
 InputView(..., isValid: email.isValidEmail)
 - Green checkmark when valid
 - Real-time feedback

 3. CHARACTER LIMIT:
 InputView(..., maxLength: 50)
 - Character counter
 - Prevent exceeding limit

 4. REQUIRED INDICATOR:
 InputView(..., isRequired: true)
 - Red asterisk on label
 - Clear required fields

 5. HELP TEXT:
 InputView(..., helpText: "Must be 8+ characters")
 - Gray text below field
 - Additional guidance
 */
