# Task 4: Update HomeView to Use Anchor Preferences and Coach Marks Overlay

- [ ] 4.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE:
  - In the `topAppBar()` function body: locate the `ZStack` that wraps the gold circle add button (contains `Circle().fill(LinearGradient(...))` and `Image("add")`), add `.anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeAddButton": $0] }` as a modifier on that `ZStack` (uses `CoachMarkBoundsKey` from task 1.2)
  - In the `tabSelector` computed property: add `.anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeTabSelector": $0] }` as a modifier on the `HStack(spacing: 0)` that contains the two `tabItem` calls
  - Locate the existing `.overlay { if !hasSeenHomeTutorial { HomeTutorialOverlayView { ... }.transition(.opacity) } }` block and REPLACE it with:
    ```swift
    .overlayPreferenceValue(CoachMarkBoundsKey.self) { anchors in
        if !hasSeenHomeTutorial {
            HomeTutorialOverlayView(
                anchors: anchors,
                onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasSeenHomeTutorial = true
                    }
                }
            )
        }
    }
    ```
  - Remove the `@State private var coachMarkStep: Int = 0` line if it was added to `HomeView` — step state is now managed inside `HomeTutorialOverlayView`
