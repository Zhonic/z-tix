//
//  LoginView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 14/10/2025.
//

import SwiftUI

// MARK: - Login View

/// User authentication screen for existing accounts
/// Handles email/password login with validation and error handling
/// Provides smart account creation flow when user attempts to sign in with non-existent account
struct LoginView: View {

    // MARK: - State Properties

    /// User's email address input
    /// Validated against email format before enabling sign-in
    @State private var email = ""

    /// User's password input
    /// Must be at least 8 characters to enable sign-in
    @State private var password = ""

    /// Controls visibility of the "Create Account" confirmation dialog
    /// Triggered when user tries to sign in with an email that doesn't exist
    @State private var showCreateAccountDialog = false

    /// Controls programmatic navigation to registration screen
    /// Separate from NavigationLink to handle navigation from dialog action
    @State private var navigateToRegistration = false

    // MARK: - Environment Objects

    /// Shared authentication view model for sign-in operations and error handling
    @EnvironmentObject var authViewModel: AuthViewModel

    // MARK: - Body

    var body: some View {
        VStack {

            // MARK: App Logo
            /// Z-Tix branding at top of login screen
            Image("Z-Tix_Text_Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 120)
                .padding(.vertical, 32)

            // MARK: Form Fields
            /// Email and password input fields with validation
            VStack(spacing: 24) {
                InputView(
                    text: $email,
                    title: "Email Address",
                    placeholder: "name@example.com"
                )
                .keyboardType(.emailAddress)  // Shows email-optimized keyboard
                .autocapitalization(.none)  // Prevents auto-capitalization for emails
                .autocorrectionDisabled(true)  // Disables autocorrect for email input

                InputView(
                    text: $password,
                    title: "Password",
                    placeholder: "Enter your password",
                    isSecureField: true  // Masks password characters
                )
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // MARK: Sign In Button
            /// Async button that triggers authentication
            /// Disabled until form validation passes
            Button {
                Task {
                    try await authViewModel.signIn(
                        withEmail: email,
                        password: password
                    )
                }
            } label: {
                ZTixButton(
                    title: "SIGN IN",
                    foregroundColour: .white,
                    backgroundColour: .cyan,
                    opacity: 100
                )
            }
            .disabled(!formIsValid)  // Disable if validation fails
            .opacity(formIsValid ? 1.0 : 0.5)  // Visual feedback for disabled state
            .padding(.top, 24)

            Spacer()

            // MARK: Registration Navigation
            /// Link to registration screen for new users
            NavigationLink {
                RegistrationView()
                    .navigationBarBackButtonHidden(true)  // Prevent back navigation conflicts
            } label: {
                HStack(spacing: 3) {
                    Text("Don't have an account?")
                        .foregroundColor(.cyan)
                    Text("Sign up")
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
            }
        }
        .navigationBarBackButtonHidden(true)  // Prevent unwanted back navigation
        .keyboardDismissToolbar()  // Adds toolbar button to dismiss keyboard

        // MARK: Error Alert
        /// Displays authentication errors from view model
        .alert(item: $authViewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: alertItem.dismissButton
            )
        }

        // MARK: Account Creation Prompt Observer
        /// Watches for "account not found" scenario from AuthViewModel
        /// When detected, shows confirmation dialog to create new account
        .onChange(of: authViewModel.showCreateAccountPrompt) {
            oldValue,
            newValue in
            print(
                "DEBUG: showCreateAccountPrompt changed from \(oldValue) to \(newValue)"
            )
            if newValue {
                // Small delay ensures SwiftUI state is fully settled
                // Prevents dialog dismissal race conditions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showCreateAccountDialog = true
                }

            }
        }

        // MARK: Create Account Confirmation Dialog
        /// Smart helper dialog that offers account creation when email doesn't exist
        /// Better UX than just showing "account not found" error
        .confirmationDialog(
            "Account Not Found",
            isPresented: $showCreateAccountDialog,
            titleVisibility: .visible
        ) {
            Button("Create Account") {
                // Reset the prompt flag to prevent re-showing
                authViewModel.showCreateAccountPrompt = false
                // Trigger navigation to registration
                navigateToRegistration = true
            }
            Button("Cancel", role: .cancel) {
                authViewModel.showCreateAccountPrompt = false
            }
        } message: {
            Text(
                "No account exists with this email. Would you like to create a new account?"
            )
        }

        // MARK: Programmatic Navigation Handler
        /// Handles navigation to registration screen from dialog button
        /// Separate from NavigationLink to work with confirmation dialog
        .navigationDestination(isPresented: $navigateToRegistration) {
            RegistrationView()
                .navigationBarBackButtonHidden(true)
                .onDisappear {
                    // Reset navigation flag when returning from registration screen
                    // Prevents re-navigation if user comes back
                    navigateToRegistration = false
                }
        }
    }
}

// MARK: - Form Validation

/// Conforms to authentication form protocol for consistent validation
extension LoginView: AuthenticationFormProtocol {
    /// Validates that all required fields meet criteria before enabling sign-in
    /// - Email must be non-empty and properly formatted
    /// - Password must be at least 8 characters
    var formIsValid: Bool {
        return !email.isEmpty
            && email.isValidEmail  // Extension method validates email format
            && !password.isEmpty
            && password.count >= 8  // Minimum password length requirement
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}
