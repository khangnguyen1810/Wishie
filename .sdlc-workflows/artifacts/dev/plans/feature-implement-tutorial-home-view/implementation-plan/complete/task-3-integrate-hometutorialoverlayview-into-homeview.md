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
