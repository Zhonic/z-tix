//
//  SettingsRowView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 14/10/2025.
//

import SwiftUI

// MARK: - Settings Row Component

/// Reusable row component for settings/profile lists
/// Displays an icon with a label in consistent format
///
/// USAGE:
/// - Settings menus (ProfileView)
/// - Action lists
/// - Navigation links
/// - Info displays
///
/// DESIGN PATTERN:
/// Icon (left) + Text (center) + Optional accessory (right)
/// Follows iOS Settings app convention
struct SettingsRowView: View {

    // MARK: - Properties

    /// SF Symbol name for icon
    /// Example: "gear", "arrow.left.circle.fill", "person"
    let imageName: String

    /// Row label text
    /// Example: "Sign Out", "Version", "Delete Account"
    let title: String

    /// Icon colour (also called tint in iOS)
    /// Used for colour coding actions:
    /// - .gray: Neutral info
    /// - .cyan: Primary actions
    /// - .red: Destructive actions
    let tintColour: Color

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // MARK: Icon
            /// SF Symbol with colour coding
            Image(systemName: imageName)
                .imageScale(.small)  // Consistent size
                .font(.title)  // Slightly larger than text
                .foregroundColor(tintColour)

            // MARK: Label
            /// Primary text in system primary colour
            /// Adapts to light/dark mode automatically
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsRowView(
        imageName: "gear",
        title: "Version",
        tintColour: Color(.systemGray)
    )
}

// MARK: - Usage Examples

/*
 TYPICAL IMPLEMENTATIONS:

 1. INFO ROW (with value on right):
 HStack {
     SettingsRowView(
         imageName: "gear",
         title: "Version",
         tintColour: Color(.label)
     )
     Spacer()
     Text("1.0.0")
         .font(.subheadline)
         .foregroundColor(.gray)
 }

 2. ACTION BUTTON (Sign Out):
 Button {
     authViewModel.signOut()
 } label: {
     SettingsRowView(
         imageName: "arrow.left.circle.fill",
         title: "Sign Out",
         tintColour: .red
     )
 }

 3. DESTRUCTIVE ACTION (Delete Account):
 Button {
     showDeleteConfirmation = true
 } label: {
     SettingsRowView(
         imageName: "xmark.circle.fill",
         title: "Delete Account",
         tintColour: .red
     )
 }

 4. NAVIGATION LINK (Attributions):
 NavigationLink {
     AttributionsView()
 } label: {
     SettingsRowView(
         imageName: "doc.text.fill",
         title: "Attributions",
         tintColour: .cyan
     )
 }

 5. PROFILE DISPLAY:
 SettingsRowView(
     imageName: "person.circle",
     title: "Profile",
     tintColour: .cyan
 )
 */

// MARK: - Colour Conventions

/*
 ICON COLOUR MEANINGS:

 1. GRAY (.systemGray):
    - Neutral information
    - Read-only displays
    - Non-interactive items
    Example: Version number, app info

 2. CYAN (Z-Tix brand):
    - Primary actions
    - Navigation links
    - Positive actions
    Example: View attributions, settings

 3. RED:
    - Destructive actions
    - Account management
    - Data deletion
    Example: Sign out, delete account

 4. LABEL (.label):
    - System primary colour
    - Adapts to light/dark mode
    - General purpose
    Example: Generic settings

 5. BLUE:
    - External links
    - App Store links
    - Web content
    Example: Rate app, terms of service
 */

// MARK: - Layout Specifications

/*
 SPACING & SIZING:

 HStack spacing: 12pt
 - Comfortable gap between icon and text
 - Follows iOS design guidelines
 - Consistent with Settings app

 Image scale: .small
 - Prevents icons from being too large
 - Maintains text prominence
 - Consistent across all rows

 Icon font: .title
 - Larger than text for visibility
 - But not overwhelming
 - Good visual hierarchy

 Text font: .subheadline
 - Standard size for list items
 - Readable without being large
 - Matches iOS conventions

 TYPICAL ROW HEIGHT:
 - Auto-sizing based on content
 - Usually ~44pt (iOS tap target)
 - Comfortable spacing in lists
 */

// MARK: - Accessibility

/*
 ACCESSIBILITY FEATURES:

 1. DYNAMIC TYPE:
    - Fonts scale with system settings
    - .subheadline respects text size preferences
    - Icon scales proportionally

 2. COLOUR CONTRAST:
    - .primary ensures readable text
    - Works in light and dark mode
    - Tint colours chosen for visibility

 3. VOICEOVER:
    - Reads icon label + text
    - Button role understood when in Button
    - Navigation hint provided by NavigationLink

 IMPROVEMENTS POSSIBLE:
 - Add .accessibilityLabel() for custom descriptions
 - Add .accessibilityHint() for action guidance
 - Consider .accessibilityAddTraits(.isButton)
 */

// MARK: - Design Philosophy

/*
 WHY THIS PATTERN?

 1. CONSISTENCY:
    - Every settings row looks the same
    - Predictable user experience
    - Matches iOS Settings app

 2. REUSABILITY:
    - Single source of truth for row design
    - Easy to update entire app
    - Reduces code duplication

 3. CLARITY:
    - Icon provides visual category
    - Colour codes action severity
    - Text states purpose clearly

 4. MAINTAINABILITY:
    - Change design in one place
    - Easy to add new rows
    - Simple to understand

 ALTERNATIVE APPROACHES:
 - Could use List with native styling
 - Could use Label view (Icon + Text)
 - Could use custom ButtonStyle

 Decision: Custom view provides more control and consistency
 */
