# Share Context

## Important Instructions for Implementation

- No code comments of any kind (no `//`, `/* */`, TODO, FIXME, or explanatory comments).
- No debugging statements (`print`, `debugPrint`, `NSLog`).
- The tutorial overlay MUST be applied as an `.overlay` modifier on the outermost `NavigationStack` in `HomeView.body`, placed after all existing modifiers (`.sheet`, `.fullScreenCover`, `.showDialogIfNeeded`, `.showFullScreenDialog`).
- Use `@AppStorage` with the key from `WishieConstants.hasSeenHomeTutorial` — do NOT hardcode the key string in `HomeView`.
- `HomeTutorialOverlayView` is a pure SwiftUI view; no view model is needed.
- Fade in on appear and fade out on dismiss using `.opacity` with `.animation(.easeInOut(duration: 0.3))`.

## Reused Existing Functions/Utilities

- `Color(hex:)` (`Wishie/Helper/ColorExtension.swift`): Converts hex strings to SwiftUI `Color`. Used for all brand color values.
- `Font.wishies(_ style:, _ size:)` (`Wishie/Resources/WishieCustomFont.swift`): Custom font accessor used throughout the app for consistent typography.
- `WishieConstants` (`Wishie/Constants/WishieConstants.swift`): Central enum for string constants. Extended in Task 1 to hold the `AppStorage` key.

## Shared Contracts

### Entities

N/A — this feature involves no new data models or backend entities.

### Interfaces

N/A — no new service protocols are introduced.

### DTOs

N/A — no data transfer objects are required.

