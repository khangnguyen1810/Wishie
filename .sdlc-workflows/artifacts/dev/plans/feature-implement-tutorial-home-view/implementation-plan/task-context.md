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

# Task 1: Add Tutorial Persistence Key to WishieConstants

- [ ] 1.1: In `Wishie/Constants/WishieConstants.swift` UPDATE:
  - Add a new static constant `hasSeenHomeTutorial: String = "hasSeenHomeTutorial"` to the `WishieConstants` enum body, alongside the existing `userIdKey`, `firebaseUserPath`, and `firebaseWishlistPath` constants.

# Task 2: Create HomeTutorialOverlayView Component

- [ ] 2.1: In `Wishie/CustomView/HomeTutorialOverlayView.swift` CREATE:
  - Define `struct HomeTutorialOverlayView: View` with a single `onDismiss: () -> Void` closure property.
  - Root body is a `ZStack` wrapping a full-screen `Color.black.opacity(0.65).ignoresSafeArea()` tap target and a centered tutorial card.
  - Apply `.onTapGesture { onDismiss() }` to the root `ZStack` to dismiss on any tap.
  - Apply `.opacity(1).animation(.easeInOut(duration: 0.3), value: true)` for a fade-in effect on appear.
  - Tutorial card is a `VStack(spacing: 20)` with:
    - A title `Text("How Wishie works 🎁")` using `.font(.wishies(.bold, 20))` and `.foregroundStyle(Color.black)`.
    - Three hint rows produced by a private `hintRow(icon:, text:)` helper `@ViewBuilder` func, each showing an SF Symbol icon and a description `Text`:
      - `hintRow(icon: "plus.circle.fill", text: "Tap + to create a new wishlist or join a friend's")`
      - `hintRow(icon: "list.bullet.rectangle.portrait", text: "Switch between My list and Friend's list tabs")`
      - `hintRow(icon: "arrow.left", text: "Swipe left on a wishlist to delete or leave it")`
    - A `Text("Tap anywhere to get started")` dismiss hint using `.font(.wishies(.regular, 13))` and `.foregroundStyle(Color.darkGrey)`.
  - Tutorial card styling: `padding(24)`, `background` of `RoundedRectangle(cornerRadius: 24)` filled with `LinearGradient(colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")], startPoint: .top, endPoint: .bottom)`, and a `stroke` overlay of `RoundedRectangle(cornerRadius: 24)` with `Color(hex: "#F9C46B").opacity(0.6)` lineWidth `1.5`.
  - Card constrained with `.padding(.horizontal, 32)`.
  - Private `hintRow(icon: String, text: String)` `@ViewBuilder` renders an `HStack(spacing: 12)` with:
    - `Image(systemName: icon)` sized `.font(.system(size: 20))` colored `.foregroundStyle(Color(hex: "#F9C46B"))`.
    - `Text(text)` using `.font(.wishies(.regular, 14))` and `.foregroundStyle(Color.black)`, `.fixedSize(horizontal: false, vertical: true)`.

# Task 3: Integrate HomeTutorialOverlayView into HomeView

- [ ] 3.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE:
  - Add `@AppStorage(WishieConstants.hasSeenHomeTutorial) private var hasSeenHomeTutorial: Bool = false` to the `HomeView` state property declarations.
  - Append an `.overlay` modifier as the last modifier on the outermost `NavigationStack` in `body` (after `.showFullScreenDialog($homeViewModel.isGettingList)`):
    ```swift
    .overlay {
        if !hasSeenHomeTutorial {
            HomeTutorialOverlayView {
                hasSeenHomeTutorial = true
            }
        }
    }
    ```
  - No other changes to `HomeView` are required.
