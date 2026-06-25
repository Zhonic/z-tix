# Z-Tix

Z-Tix is an iPhone event and ticket management app built with Swift and SwiftUI. It is designed for event organisers to create and manage events, import attendee tickets from CSV files, validate QR codes and barcodes at the door, and review scan history.

The app uses Firebase Authentication for organiser accounts and Cloud Firestore for events, tickets, and scan logs. Firestore persistence and network monitoring support ticket lookup and queued writes when connectivity is limited. Profile picture metadata is stored locally with SwiftData, while the image itself is stored in the app's file system.

---

## Table of contents

- [Features](#features)
- [Technology](#technology)
- [Prerequisites](#prerequisites)
- [Directory structure](#directory-structure)
- [Configuration](#configuration)
- [Opening and running the app](#opening-and-running-the-app)
- [Sample ticket import](#sample-ticket-import)
- [Known limitations](#known-limitations)
- [License](#license)

---

## Features

- Organiser registration, sign-in, sign-out, and account management
- Event creation, editing, listing, and deletion
- Google Places address autocomplete when entering event venues
- CSV ticket import into an event
- Camera-based QR, EAN-8, and EAN-13 ticket scanning
- Ticket validation with valid, already scanned, not found, and error results
- Scan history grouped by event
- Firestore caching and network-status awareness for limited offline operation
- Locally stored, selectable, and croppable profile pictures

---

## Technology

| Layer | Frameworks / Services |
|---|---|
| UI | SwiftUI, UIKit (camera bridge) |
| Camera | AVFoundation |
| Local persistence | SwiftData |
| Backend | Firebase Authentication, Cloud Firestore, Firebase Storage |
| Networking | Network framework (connectivity monitoring) |
| Photos | PhotosUI |
| Maps / Places | Google Places API |
| Dependency management | Swift Package Manager |

**Key dependency versions** (from `Package.resolved`):

- Firebase iOS SDK 12.4.0
- Google App Check 11.2.0

The Xcode project targets **iOS 18.5** and uses the bundle identifier `edu.monash.Z-Tix`.

---

## Prerequisites

| Tool | Minimum version |
|---|---|
| macOS | 15 Sequoia or later (required by Xcode 16) |
| Xcode | 16.x |
| iOS device / simulator | iOS 18.5 |
| Firebase project | Authentication and Firestore enabled |
| Google Cloud project | Places API enabled and an API key issued |

A **physical iPhone** is required for the full experience. The simulator supports most screens but cannot exercise the camera-based ticket scanner.

---

## Directory structure

```text
.
├── Z-Tix.xcodeproj/                 # Xcode project, shared scheme, and SPM lockfile
├── Z-Tix/                           # Application source and bundled resources
│   ├── App/
│   │   ├── ZTixApp.swift            # App entry point and dependency setup
│   │   └── Root/                    # Splash screen and authenticated tab navigation
│   ├── Core/                        # Feature-oriented application code
│   │   ├── Authentication/          # Login, registration, splash state, and auth logic
│   │   ├── Event/                   # Event forms, event list, and Firestore operations
│   │   │   ├── View/
│   │   │   │   └── Google Places API/  # Address-search interface
│   │   │   └── ViewModel/
│   │   │       └── Google Places API/  # Places autocomplete service
│   │   ├── Logs/                    # Ticket-scan history UI and data access
│   │   ├── Offline Compatability/   # Firebase startup, cache settings, and network monitor
│   │   ├── Profile/                 # Account UI and local profile-picture handling
│   │   │   └── View/Attribution/    # Third-party attribution screen
│   │   ├── Purchase/                # Placeholder Premium/Upgrade screen
│   │   ├── Scanner/                 # Scanner UI, state, and AVFoundation UIKit bridge
│   │   │   └── View/UIKit Components/
│   │   └── Ticket Import/           # CSV picker/parser, ticket status, and ticket operations
│   ├── Database Model/              # Codable Firestore and SwiftData domain models
│   │   ├── Event.swift
│   │   ├── OrganiserUser.swift
│   │   ├── ProfilePicture.swift
│   │   ├── StaffUser.swift          # Planned staff feature model
│   │   ├── Ticket.swift
│   │   └── TicketScan.swift
│   ├── Utilities/                   # Shared controls and supporting helpers
│   │   ├── Buttons/
│   │   ├── Cells/
│   │   ├── Error Handling/
│   │   ├── Extensions/
│   │   └── Form Fields/
│   ├── Assets.xcassets/             # App icon, accent colour, and logo assets
│   └── GoogleService-Info.plist     # Firebase app configuration bundled with the target
├── GoogleService-Info.plist         # Firebase configuration copy at repository root
├── Test_Tix_v2.csv                  # Sample ticket-import data
├── .gitignore
└── README.md
```

### Domain models

Views and view models are separated within most feature folders. The principal persisted models are:

| Model | Storage | Purpose |
|---|---|---|
| `Event` | Firestore | An organiser-owned event |
| `Ticket` | Firestore (`tickets` subcollection) | An attendee ticket belonging to an event |
| `TicketScan` | Firestore | Top-level audit record for a scan attempt |
| `OrganiserUser` | Firestore | Organiser profile linked to a Firebase Auth user |
| `ProfilePicture` | SwiftData + local filesystem | Metadata pointing to a profile image stored on disk |
| `StaffUser` | — | Reserved for a future staff-access feature |

---

## Configuration

Two local files are excluded from version control and must be supplied before building.

### `Z-Tix/Info.plist`

This is the standard iOS `Info.plist` for the app target. Create it in Xcode (**File › New › File › Property List**) or copy an existing template and set at minimum:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSCameraUsageDescription</key>
    <string>Z-Tix uses the camera to scan ticket QR codes and barcodes.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Z-Tix uses the photo library to set your profile picture.</string>
</dict>
</plist>
```

Add any additional keys your Firebase or Google Places configuration requires.

### `GooglePlacesConfig` source file

`AddressSearchService` references a `GooglePlacesConfig` type that supplies the Places API key. Create a Swift source file in the project (for example `Z-Tix/Core/Event/ViewModel/Google Places API/GooglePlacesConfig.swift`) with the following structure:

```swift
enum GooglePlacesConfig {
    static let apiKey = "YOUR_GOOGLE_PLACES_API_KEY"
}
```

Replace `YOUR_GOOGLE_PLACES_API_KEY` with the key issued in your Google Cloud Console project that has the **Places API** enabled. Do **not** commit this file.

### `GoogleService-Info.plist`

A `GoogleService-Info.plist` is already bundled in the repository. Confirm that it belongs to the Firebase project you intend to use and that both **Authentication** (Email/Password provider) and **Cloud Firestore** are enabled in the Firebase console.

---

## Opening and running the app

1. Open `Z-Tix.xcodeproj` in Xcode 16 or later on macOS.
2. Allow Xcode to resolve the Firebase Swift Package dependencies (this may take a few minutes on first open).
3. Supply the two local configuration files described in the [Configuration](#configuration) section above.
4. Select the `Z-Tix` scheme, choose a connected iPhone as the run destination, and press **Run** (⌘R).

Camera and photo-library permissions are requested on first use of the scanner and profile-picture features respectively.

---

## Sample ticket import

`Test_Tix_v2.csv` demonstrates the expected import columns:

```csv
ticketCode,attendeeName,attendeeEmail,ticketType,price,status,QR Code
```

To use it:

1. Create or open an event in the app.
2. Navigate to the event's **Ticket Import** screen.
3. Select `Test_Tix_v2.csv` from the Files picker.
4. Confirm the import.

> **Note:** Avoid importing the same CSV into the same event more than once. The current workflow does not detect or clean up duplicate imports.

---

## Known limitations

- **Staff accounts** — `StaffUser` and the staff-user model are defined but not yet functional. The feature is planned for a future release.
- **Upgrade screen** — the **Upgrade** (Premium) screen is a placeholder. In-app purchase logic has not been implemented.
- **Duplicate ticket imports** — importing the same CSV file into the same event multiple times will create duplicate ticket records. There is currently no deduplication or rollback step.
- **Camera on simulator** — the ticket scanner requires a physical iPhone camera. The iOS Simulator cannot exercise this feature.
- **Offline write queue** — Firestore offline caching is enabled; however, scans performed without connectivity are queued and flushed when the device reconnects. Behaviour under extended offline periods has not been extensively tested.

---

## License

This project is not currently distributed under an open-source licence. All rights reserved.
