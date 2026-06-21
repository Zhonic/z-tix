//
//  StaffUser.swift
//  Z-Tix
//
//  Created by Harnish Patel on 20/10/2025.
//

import Foundation

// MARK: - Staff User Model

/// Staff member account model (PLANNED FEATURE - NOT YET IMPLEMENTED)
/// Will allow organisers to add staff members to help scan tickets
///
/// PLANNED ARCHITECTURE:
/// - Stored in Firestore at: /staff/{staffId}
/// - Separate from OrganiserUser (different permissions)
/// - Can be assigned to multiple events
/// - Limited access (scanning only, no event CRUD operations)
///
/// RELATIONSHIPS (PLANNED):
/// - Belongs to OrganiserUser (many-to-one) - created by organiser
/// - Has access to multiple Events (many-to-many) - assigned events
/// - Can create TicketScans (one-to-many) - scanning activity
///
/// USE CASE:
/// Large events need multiple people scanning tickets at different entrances
/// Example: Music festival with 5 entry points, each needs a staff member
///
/// PROTOCOL CONFORMANCES:
/// - Identifiable: SwiftUI support
/// - Codable: Firestore encoding/decoding
struct StaffUser: Identifiable, Codable {

    // MARK: - Properties

    /// Unique staff member identifier
    /// Could be Firebase Auth UID if staff have accounts
    /// Or generated UUID if managed by organiser
    let id: String

    /// Staff member's first name
    let firstName: String

    /// Staff member's last name
    let lastName: String

    /// Staff member's email address
    /// Used for sending event assignments and notifications
    let email: String

}

// MARK: - Planned Implementation

/*
 FEATURE ROADMAP:

 1. STAFF MANAGEMENT SCREEN:
    - Add in ProfileView or separate tab
    - List all staff members
    - Add/remove staff functionality
    - Assign/unassign to events

 2. STAFF AUTHENTICATION:
    Option A: Separate Firebase Auth accounts
    - Pro: Secure, individual sessions
    - Con: More complex, requires email verification

    Option B: Shared login codes
    - Pro: Simple, quick setup
    - Con: Less secure, no individual tracking

    Decision: Start with Option A for better security

 3. STAFF PERMISSIONS:
    - Can view assigned events only
    - Can scan tickets for assigned events
    - Cannot create/edit/delete events
    - Cannot view other staff members
    - Cannot access organiser profile settings

 4. STAFF VIEW:
    - Simplified interface showing assigned events
    - Direct access to scanner for each event
    - View scan history for their scans only
    - No access to CSV import

 5. FIRESTORE STRUCTURE:
    /staff/{staffId}
      - id, firstName, lastName, email
      - organiserId (who created them)
      - createdAt, createdBy

    /eventStaff/{documentId}  (junction table)
      - eventId, staffId
      - assignedAt, assignedBy
      - permissions (array: ["scan", "view_logs"])

 6. ASSIGNMENT FLOW:
    - Organiser creates staff account
    - Organiser assigns staff to specific events
    - Staff receives email notification
    - Staff logs in and sees assigned events
    - Staff can scan tickets at those events

 7. SCAN ATTRIBUTION:
    - TicketScan model needs scannerId field
    - Track which staff member performed each scan
    - Useful for accountability and analytics
    - Display in logs: "Scanned by: John Smith (Staff)"
 */

// MARK: - Future Properties

/*
 ADDITIONAL FIELDS TO ADD:

 struct StaffUser: Identifiable, Codable {
     let id: String
     let firstName: String
     let lastName: String
     let email: String
     let organiserId: String       // Who created this staff account
     let phoneNumber: String?      // Optional contact number
     let createdAt: Date           // When account was created
     let isActive: Bool            // Can disable without deleting
     let permissions: [String]     // Array of permission strings

     // Computed properties
     var fullName: String {
         "\(firstName) \(lastName)"
     }

     var initials: String {
         // Similar to OrganiserUser
     }
 }

 enum StaffPermission: String, Codable {
     case scanTickets = "scan_tickets"
     case viewLogs = "view_logs"
     case exportData = "export_data"  // For future
 }
 */

// MARK: - Implementation Priority

/*
 PRIORITY: Medium-Low

 Current Status: Placeholder for future development

 Why not implemented yet:
 - Core app functionality works with single organiser
 - Additional complexity for MVP
 - Requires more authentication logic
 - Need to design permissions system
 - Should validate core features first

 When to implement:
 - After MVP launch and user feedback
 - When users request multi-staff support
 - After establishing pricing tiers (premium feature?)
 - When scaling to larger events (>500 attendees)

 Dependencies:
 - Complete core scanning functionality ✅
 - Stable event management ✅
 - Robust permission system ❌
 - Staff management UI ❌
 - Email notification system ❌
 */
