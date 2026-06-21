# Z-Tix

Z-Tix is an iPhone event and ticket management app built with Swift, SwiftUI, and Xcode. It is designed for event organisers to create and manage events, import attendee tickets from CSV files, validate QR codes and barcodes at the door, and review scan history.

The app uses Firebase Authentication for organiser accounts and Cloud Firestore for events, tickets, and scan logs. Firestore persistence and network monitoring support ticket lookup and queued writes when connectivity is limited. Profile picture metadata is stored locally with SwiftData, while the image itself is stored in the app's file system.

## Main features

- Organiser registration, sign-in, sign-out, and account management
- Event creation, editing, listing, and deletion
- Google Places address autocomplete when entering event venues
- CSV ticket import into an event
- Camera-based QR, EAN-8, and EAN-13 ticket scanning
- Ticket validation with valid, already scanned, not found, and error results
- Scan history grouped by event
- Firestore caching and network-status awareness for limited offline operation
- Locally stored, selectable, and croppable profile pictures

The **Upgrade** screen and staff-user model are placeholders for planned functionality.

## Technology

- Swift 5 and SwiftUI
- UIKit and AVFoundation for the camera scanner
- SwiftData for local profile-picture metadata
- Firebase Authentication, Cloud Firestore, and Firebase Storage through Swift Package Manager
- Network framework for connectivity monitoring
- PhotosUI for profile-picture selection
- Google Places API for venue address suggestions

The Xcode project currently targets iOS 18.5 and uses the bundle identifier `edu.monash.Z-Tix`.

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

Views and view models are separated within most feature folders. The principal persisted models are:

- `Event`: an organiser-owned event stored in Firestore
- `Ticket`: an attendee ticket stored below its event in a `tickets` subcollection
- `TicketScan`: a top-level audit record for a scan attempt
- `OrganiserUser`: the organiser profile linked to a Firebase Authentication user
- `ProfilePicture`: local SwiftData metadata pointing to an image on disk
- `StaffUser`: a model reserved for a future staff-access feature

## Opening and running the app

1. Open `Z-Tix.xcodeproj` in Xcode on macOS.
2. Allow Xcode to resolve the Firebase Swift Package dependencies.
3. Supply the ignored local configuration files expected by the project: `Z-Tix/Info.plist` and a target source file defining the `GooglePlacesConfig` values used by `AddressSearchService`.
4. Confirm that the bundled `GoogleService-Info.plist` belongs to the Firebase project you intend to use and that its Authentication and Firestore services are configured.
5. Select the `Z-Tix` scheme and run the app.

Use a physical iPhone for the full experience. The simulator can display most screens, but it cannot exercise the camera-based ticket scanner. Camera and photo-library permissions are requested for scanning and profile-picture selection.

## Sample ticket import

`Test_Tix_v2.csv` demonstrates the expected import columns:

```csv
ticketCode,attendeeName,attendeeEmail,ticketType,price,status,QR Code
```

Import the sample file from an event's ticket-import screen. Avoid importing the same CSV into the same event more than once, as the current workflow does not provide a general duplicate-import cleanup step.
