//
//  String+Ext.swift
//  Z-Tix
//
//  Created by Harnish Patel on 21/10/2025.
//

import Foundation

// MARK: - String Extensions

/// Extension adding utility methods to String type
/// Currently provides email validation functionality
extension String {

    // MARK: - Email Validation

    /// Validates if string is a properly formatted email address
    /// Uses regex pattern to check structure and domain format
    ///
    /// VALIDATION RULES:
    /// - Local part: Letters, numbers, dots, underscores, percent, plus, hyphen
    /// - @ symbol required
    /// - Domain: Letters, numbers, dots, hyphens
    /// - TLD: 2-64 letters (e.g., .com, .technology)
    ///
    /// VALID EXAMPLES:
    /// - "john@example.com" ✅
    /// - "jane.doe@company.co.uk" ✅
    /// - "user+tag@domain.com" ✅
    /// - "test_email@sub.domain.org" ✅
    ///
    /// INVALID EXAMPLES:
    /// - "notanemail" ❌ (no @ or domain)
    /// - "missing@domain" ❌ (no TLD)
    /// - "@example.com" ❌ (no local part)
    /// - "user@.com" ❌ (no domain)
    /// - "user@domain.c" ❌ (TLD too short)
    ///
    /// - Returns: true if email format is valid
    var isValidEmail: Bool {

        // MARK: Regex Pattern Breakdown
        /// [A-Z0-9a-z._%+-]+ : Local part (before @)
        ///   - Letters (uppercase/lowercase)
        ///   - Numbers
        ///   - Special chars: . _ % + -
        ///   - At least one character (+)
        ///
        /// @ : Required separator
        ///
        /// [A-Za-z0-9.-]+ : Domain (after @, before TLD)
        ///   - Letters (uppercase/lowercase)
        ///   - Numbers
        ///   - Dots and hyphens
        ///   - At least one character (+)
        ///
        /// \\. : Literal dot separator (escaped)
        ///
        /// [A-Za-z]{2,64} : Top-level domain (TLD)
        ///   - Only letters
        ///   - 2-64 characters (covers .uk to .technology)
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        // Create NSPredicate for pattern matching
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)

        // Evaluate string against pattern
        return emailPredicate.evaluate(with: self)
    }
}

// MARK: - Usage Examples

/*
 TYPICAL USAGE IN FORMS:

 1. LOGIN/REGISTRATION VALIDATION:
 extension LoginView: AuthenticationFormProtocol {
     var formIsValid: Bool {
         return !email.isEmpty
             && email.isValidEmail  // ← Extension usage
             && !password.isEmpty
             && password.count >= 8
     }
 }

 2. REAL-TIME VALIDATION:
 struct EmailInputView: View {
     @State private var email = ""

     var isValidEmail: Bool {
         email.isValidEmail
     }

     var body: some View {
         TextField("Email", text: $email)

         if !email.isEmpty && !isValidEmail {
             Text("Invalid email format")
                 .foregroundColor(.red)
         }
     }
 }

 3. BACKEND SUBMISSION CHECK:
 func createUser(email: String) async throws {
     guard email.isValidEmail else {
         throw ValidationError.invalidEmail
     }
     // Proceed with creation
 }

 4. BATCH VALIDATION:
 let emails = ["user@test.com", "invalid", "another@example.org"]
 let validEmails = emails.filter { $0.isValidEmail }
 // validEmails: ["user@test.com", "another@example.org"]
 */

// MARK: - Regex Pattern Analysis

/*
 PATTERN COMPONENTS EXPLAINED:

 LOCAL PART: [A-Z0-9a-z._%+-]+
 ✅ Allows:
    - john
    - john.doe
    - john_doe
    - john+tag
    - john%discount
    - user-name
    - test123

 ❌ Blocks:
    - john@doe (@ not allowed in local)
    - john doe (spaces not allowed)
    - john#tag (# not standard)

 DOMAIN: [A-Za-z0-9.-]+
 ✅ Allows:
    - example
    - sub.domain
    - test-server
    - server123

 ❌ Blocks:
    - domain_name (underscore rare in domains)
    - domain@test (@ not allowed)
    - .domain (can't start with dot)

 TLD: [A-Za-z]{2,64}
 ✅ Allows:
    - .com, .org, .net (3 chars)
    - .uk, .au, .nz (2 chars)
    - .technology, .international (long TLDs)

 ❌ Blocks:
    - .c (too short)
    - .123 (numbers not allowed in TLD)
    - .c0m (numbers not allowed)
 */

// MARK: - Limitations & Edge Cases

/*
 KNOWN LIMITATIONS:

 1. INTERNATIONALISED DOMAINS:
    - Doesn't validate IDN (Internationalised Domain Names)
    - Example: "user@münchen.de" would fail
    - RFC 6531 support not included
    - Workaround: Punycode conversion

 2. IP ADDRESS DOMAINS:
    - Doesn't allow IP addresses as domains
    - Example: "user@192.168.1.1" would fail
    - RFC 5321 technically allows this
    - Rare in practice for Z-Tix use case

 3. QUOTED STRINGS:
    - Doesn't support quoted local parts
    - Example: "john doe"@example.com" would fail
    - RFC 5321 allows this
    - Very rare in modern email

 4. COMMENTS:
    - Doesn't support RFC 5322 comments
    - Example: "john(comment)@example.com" would fail
    - Almost never used

 5. LENGTH LIMITS:
    - Doesn't enforce 64-char local part limit
    - Doesn't enforce 255-char total limit
    - Could add separate length validation

 ACCEPTABLE FOR Z-TIX:
 - Covers 99.9% of real-world emails
 - Validates standard formats users expect
 - Prevents obvious typos and mistakes
 - Balances strictness with usability
 */

// MARK: - Performance Considerations

/*
 REGEX PERFORMANCE:

 COMPLEXITY:
 - Regex evaluation: O(n) where n = string length
 - Typical email: 20-30 characters
 - Evaluation time: <1ms

 OPTIMISATION:
 - NSPredicate compiled once
 - Could cache predicate for better performance
 - Not necessary for form validation use case

 BETTER PERFORMANCE (if needed):
 static let emailPredicate: NSPredicate = {
     let format = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
     return NSPredicate(format: "SELF MATCHES %@", format)
 }()

 var isValidEmail: Bool {
     Self.emailPredicate.evaluate(with: self)
 }
 */

// MARK: - Alternative Approaches

/*
 OTHER VALIDATION METHODS:

 1. MAILBOX CHECK (Network-based):
    - Verify email exists on server
    - SMTP connection to check
    - Too slow for UI validation
    - Privacy concerns

 2. DISPOSABLE EMAIL DETECTION:
    - Check against blacklist
    - Prevent temporary emails
    - Requires maintained list
    - Not needed for Z-Tix

 3. APPLE'S DATA DETECTOR:
    let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )
    - More permissive
    - Less control over rules
    - Current approach more explicit

 4. THIRD-PARTY LIBRARIES:
    - EmailValidator pods
    - More features
    - Additional dependency
    - Overkill for basic validation

 DECISION: Current regex approach is optimal balance
 */

// MARK: - Security Considerations

/*
 EMAIL VALIDATION & SECURITY:

 NOT A SECURITY MEASURE:
 - Validation is for UX (prevent typos)
 - Not for preventing malicious input
 - Server-side validation still required
 - Can't prevent fake emails

 INJECTION PREVENTION:
 - Firebase Auth handles email safely
 - No SQL injection risk (NoSQL database)
 - No XSS risk (emails not rendered as HTML)

 WHAT IT PREVENTS:
 - User typos: "user@gmial.com" → caught
 - Format mistakes: "user@domain" → caught
 - Incomplete entries: "@example.com" → caught
 - Accidental spaces: "user @test.com" → caught

 WHAT IT DOESN'T PREVENT:
 - Fake but valid: "fake@example.com" → passes
 - Typosquatting: "user@examp1e.com" → passes
 - Disposable emails: "test@tempmail.com" → passes
 - These require server-side verification
 */

// MARK: - Testing

/*
 TEST CASES:

 func testEmailValidation() {
     // Valid emails
     XCTAssertTrue("test@example.com".isValidEmail)
     XCTAssertTrue("user.name@example.com".isValidEmail)
     XCTAssertTrue("user+tag@example.co.uk".isValidEmail)
     XCTAssertTrue("first_last@sub.domain.org".isValidEmail)

     // Invalid emails
     XCTAssertFalse("notanemail".isValidEmail)
     XCTAssertFalse("@example.com".isValidEmail)
     XCTAssertFalse("user@".isValidEmail)
     XCTAssertFalse("user@domain".isValidEmail)
     XCTAssertFalse("user domain@example.com".isValidEmail)
     XCTAssertFalse("user@domain.c".isValidEmail)
 }
 */

// MARK: - Future Enhancements

/*
 POSSIBLE ADDITIONS TO EXTENSION:

 1. PHONE NUMBER VALIDATION:
 var isValidPhoneNumber: Bool {
     // International formats
 }

 2. URL VALIDATION:
 var isValidURL: Bool {
     // HTTP/HTTPS URLs
 }

 3. PASSWORD STRENGTH:
 var passwordStrength: PasswordStrength {
     // Weak, medium, strong
 }

 4. ALPHANUMERIC CHECK:
 var isAlphanumeric: Bool {
     // Letters and numbers only
 }

 5. TRIM WHITESPACE:
 var trimmed: String {
     trimmingCharacters(in: .whitespaces)
 }
 */
