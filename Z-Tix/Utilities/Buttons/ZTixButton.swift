//
//  ZTixButton.swift
//  Z-Tix
//
//  Created by Harnish Patel on 25/9/2025.
//

import SwiftUI

// MARK: - Z-Tix Button Component

/// Reusable button component with consistent Z-Tix branding
/// Features:
/// - Fixed width relative to screen size
/// - Consistent height (44pt - iOS tap target standard)
/// - Customisable colors and opacity
/// - Rounded corners for modern iOS aesthetic
///
/// USAGE:
/// Primary actions (Sign In, Create Event, etc.)
/// Used throughout app for main call-to-action buttons
///
/// DESIGN STANDARDS:
/// - Width: Screen width - 150 (responsive)
/// - Height: 44pt (Apple's minimum tap target)
/// - Font: Title3, semibold weight
/// - Corner radius: 15pt
struct ZTixButton: View {

    // MARK: - Properties

    /// Button label text
    /// Example: "SIGN IN", "CREATE EVENT", "IMPORT"
    var title: String

    /// Text color
    /// Typically .white for solid backgrounds
    var foregroundColour: Color

    /// Background color
    /// Typically .cyan (Z-Tix brand color)
    var backgroundColour: Color

    /// Background opacity (0.0 - 1.0)
    /// Used for disabled states (0.5) or transparent buttons
    var opacity: Double

    // MARK: - Body

    var body: some View {
        Text(title)
            // MARK: Fixed Sizing
            /// Width: Responsive to screen size (leaves 150pt margins)
            /// Height: 44pt (iOS minimum tap target)
            .frame(width: UIScreen.main.bounds.width - 150, height: 44)

            // MARK: Typography
            /// Title3 for prominent buttons
            /// Semibold weight for emphasis
            .font(.title3)
            .fontWeight(.semibold)

            // MARK: Colors
            /// Background applied with configurable opacity
            /// Foreground (text) color
            .background(backgroundColour.opacity(opacity))
            .foregroundColor(foregroundColour)

            // MARK: Corner Radius
            /// 15pt radius for modern, rounded appearance
            .cornerRadius(15)

    }
}

// MARK: - Preview

#Preview {
    ZTixButton(
        title: "Test Title",
        foregroundColour: .white,
        backgroundColour: .black,
        opacity: 1
    )
}

// MARK: - Usage Examples

/*
 COMMON PATTERNS:

 1. PRIMARY ACTION (Enabled):
 Button {
     // Action
 } label: {
     ZTixButton(
         title: "SIGN IN",
         foregroundColour: .white,
         backgroundColour: .cyan,
         opacity: 1.0
     )
 }

 2. PRIMARY ACTION (Disabled):
 Button {
     // Action
 } label: {
     ZTixButton(
         title: "SIGN IN",
         foregroundColour: .white,
         backgroundColour: .cyan,
         opacity: 0.7  // Reduced opacity for disabled state
     )
 }
 .disabled(true)

 3. PROCESSING STATE:
 Button {
     // Action
 } label: {
     ZTixButton(
         title: isProcessing ? "Loading..." : "SUBMIT",
         foregroundColour: .white,
         backgroundColour: .cyan,
         opacity: isProcessing ? 0.7 : 1.0
     )
 }
 .disabled(isProcessing)

 4. DESTRUCTIVE ACTION:
 Button {
     // Delete action
 } label: {
     ZTixButton(
         title: "DELETE",
         foregroundColour: .white,
         backgroundColour: .red,
         opacity: 1.0
     )
 }

 5. SECONDARY ACTION:
 Button {
     // Action
 } label: {
     ZTixButton(
         title: "CANCEL",
         foregroundColour: .cyan,
         backgroundColour: .gray,
         opacity: 0.2  // Light background
     )
 }
 */

// MARK: - Design Notes

/*
 WHY FIXED WIDTH?
 - Consistent button sizes across screens
 - Responsive to device (iPhone SE vs iPhone 15 Pro Max)
 - Screen width - 150 leaves ~75pt margins on each side
 - Works on all iOS device sizes

 WHY 44PT HEIGHT?
 - Apple's Human Interface Guidelines minimum tap target
 - Comfortable for thumb tapping
 - Accessible for users with motor difficulties
 - Industry standard for touch targets

 WHY OPACITY PARAMETER?
 - Flexible disabled state styling
 - Can create transparent/ghost buttons
 - Single component for multiple visual states
 - Better than creating separate disabled variant

 COLOR CONVENTIONS:
 - Primary actions: .cyan background, .white text
 - Destructive: .red background, .white text
 - Secondary: .gray background, .cyan text
 - Disabled: Same colors, 0.5 opacity

 ALTERNATIVE APPROACHES:

 Could use Button Styles:
 struct ZTixButtonStyle: ButtonStyle {
     func makeBody(configuration: Configuration) -> some View {
         configuration.label
             .frame(...)
             // styling
     }
 }

 Pros: More SwiftUI-native, handles press states
 Cons: More complex, harder to customise per-instance
 Decision: Current approach prioritises simplicity

 FUTURE ENHANCEMENTS:
 - Add icon support (SF Symbol before/after text)
 - Add loading spinner variant
 - Add size variants (small, medium, large)
 - Add outline variant (border, no fill)
 - Add press animation/haptic feedback
 */
