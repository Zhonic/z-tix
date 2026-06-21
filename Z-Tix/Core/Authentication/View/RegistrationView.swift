//
//  RegistrationView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 14/10/2025.
//

import SwiftUI

// MARK: - Registration View

/// New user account creation screen
/// Collects user information and creates Firebase Auth account with Firestore profile
/// Includes real-time password matching validation with visual feedback
struct RegistrationView: View {

    // MARK: - State Properties

    /// User's email address for account creation
    @State private var email = ""

    /// User's first name for profile
    @State private var firstName = ""

    /// User's last name for profile
    @State private var lastName = ""

    /// User's chosen password (minimum 8 characters)
    @State private var password = ""

    /// Password confirmation field for validation
    @State private var confirmPassword = ""

    /// Tracks whether account creation is in progress
    /// Prevents double-submission and shows loading state
    @State private var isProcessing = false

    // MARK: - Environment Properties

    /// Dismissal environment value for programmatic view dismissal
    @Environment(\.dismiss) var dismiss

    /// Shared authentication view model for account creation
    @EnvironmentObject var authViewModel: AuthViewModel

    // MARK: - Body

    var body: some View {
        VStack {

            // MARK: App Logo
            /// Z-Tix branding at top of registration screen
            Image("Z-Tix_Text_Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 120)
                .padding(.vertical, 32)

            // MARK: Form Fields
            /// All user information input fields with appropriate keyboard types
            VStack(spacing: 24) {
                InputView(
                    text: $email,
                    title: "Email Address",
                    placeholder: "name@example.com"
                )
                .keyboardType(.emailAddress)  // Email-optimized keyboard
                .autocapitalization(.none)  // No auto-caps for email
                .autocorrectionDisabled(true)  // No autocorrect for email

                InputView(
                    text: $firstName,
                    title: "First Name",
                    placeholder: "Enter your first name"
                )
                .autocorrectionDisabled(true)  // Disable for proper names

                InputView(
                    text: $lastName,
                    title: "Last Name",
                    placeholder: "Enter your last name"
                )
                .autocorrectionDisabled(true)  // Disable for proper names

                InputView(
                    text: $password,
                    title: "Password",
                    placeholder: "Enter your password",
                    isSecureField: true  // Masks password characters
                )

                // MARK: Password Confirmation with Visual Validation
                /// Shows checkmark or X mark based on password match
                /// Provides instant visual feedback for password matching
                ZStack(alignment: .trailing) {
                    InputView(
                        text: $confirmPassword,
                        title: "Confirm Password",
                        placeholder: "Confirm your password",
                        isSecureField: true  // Masks password characters
                    )

                    // Only show validation icon when both fields have input
                    if !password.isEmpty && !confirmPassword.isEmpty {
                        if password == confirmPassword {
                            // Green checkmark for matching passwords
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemGreen))
                        } else {
                            // Red X mark for non-matching passwords
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemRed))
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // MARK: Sign Up Button
            /// Async button that creates Firebase Auth account and Firestore profile
            /// Disabled during processing and when validation fails
            Button {
                isProcessing = true
                Task {
                    do {
                        // Attempt to create user account
                        try await authViewModel.createUser(
                            withEmail: email,
                            password: password,
                            firstName: firstName,
                            lastName: lastName
                        )

                        // Only dismiss if account creation was successful
                        // Registration view is stacked on top, so dismiss returns to previous screen
                        await MainActor.run {
                            isProcessing = false
                            dismiss()
                        }
                    } catch {
                        // Error is handled in viewModel (shows alert)
                        // Stay on registration screen so user can correct input
                        await MainActor.run {
                            isProcessing = false
                        }
                        print(
                            "DEBUG: Registration failed, staying on registration screen."
                        )
                    }
                }
            } label: {
                ZTixButton(
                    title: "SIGN UP",
                    foregroundColour: .white,
                    backgroundColour: .cyan,
                    opacity: 100
                )
            }
            .disabled(!formIsValid)  // Disable if validation fails
            .opacity(formIsValid ? 1.0 : 0.5)  // Visual feedback for disabled state
            .padding(.top, 24)

            Spacer()

            // MARK: Login Navigation
            /// Button to return to login screen for existing users
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                        .foregroundColor(.cyan)
                    Text("Sign in")
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
            }
        }
        .keyboardDismissToolbar()  // Adds toolbar button to dismiss keyboard

        // MARK: Error Alert
        /// Displays account creation errors from view model
        /// Examples: email already exists, weak password, network errors
        .alert(item: $authViewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: alertItem.dismissButton
            )
        }
    }
}

// MARK: - Form Validation

/// Conforms to authentication form protocol for consistent validation
extension RegistrationView: AuthenticationFormProtocol {
    /// Validates that all required fields meet criteria before enabling sign-up
    /// All fields must be filled and meet requirements:
    /// - Valid email format
    /// - Password at least 8 characters
    /// - Passwords must match
    /// - First and last names required
    var formIsValid: Bool {
        return !email.isEmpty
            && email.isValidEmail  // Extension method validates email format
            && !password.isEmpty
            && password.count >= 8  // Minimum password length
            && confirmPassword == password  // Passwords must match
            && !firstName.isEmpty
            && !lastName.isEmpty
    }
}

// MARK: - Preview

#Preview {
    RegistrationView()
}
