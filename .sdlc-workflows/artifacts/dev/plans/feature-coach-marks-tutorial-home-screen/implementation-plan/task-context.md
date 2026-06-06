# Share Context

## Important Instructions for Implementation

- Use `overlayPreferenceValue(key: CoachMarkBoundsKey.self)` instead of `.overlay` in `HomeView` to gain access to element anchor bounds; this modifier is always active so conditional rendering is done inside the closure
- Resolve `Anchor<CGRect>` to `CGRect` inside `HomeTutorialOverlayView` using its own `GeometryReader` — never pass `GeometryProxy` across view boundaries
- The spotlight cutout uses SwiftUI `Path` with `FillStyle(eoFill: true)` — the outer rect and inner rounded rect together create a transparent hole via the even-odd rule
- Step 3 has `anchorID: nil` — render a centered tooltip with no spotlight cutout and no arrow
- Do NOT change `WishieConstants.hasSeenHomeTutorial` or its `AppStorage` usage in `HomeView`
- Step transition animation (`.easeInOut(duration: 0.25)`) is applied when advancing `currentStep` inside `HomeTutorialOverlayView`

## Reused Existing Functions/Utilities

- `WishieConstants.hasSeenHomeTutorial`: `AppStorage` key for tutorial completion persistence — `Wishie/Constants/WishieConstants.swift`
- `Color(hex:)`: hex-string color initializer — `Wishie/Helper/ColorExtension.swift`
- `.font(.wishies(_:_:))`: custom font modifier — `Wishie/Resources/WishieCustomFont.swift`

## Shared Contracts

### Entities

- `CoachMarkStep`: Represents one tutorial step. Properties: `anchorID: String?` (nil = no spotlight), `title: String`, `message: String`, `arrowDirection: CoachMarkArrowDirection`
- `CoachMarkArrowDirection`: Enum indicating tooltip arrow direction. Cases: `up` (arrow points upward toward element above tooltip), `down` (arrow points downward toward element below tooltip), `none` (no arrow, used when anchorID is nil)

### Interfaces

None

### DTOs

None

---

# Task 1: Create Coach Mark Data Model and Anchor Preference Key

- [ ] 1.1: In `Wishie/Models/CoachMarkStep.swift` CREATE:
  - Define `struct CoachMarkStep` with stored properties: `let anchorID: String?`, `let title: String`, `let message: String`, `let arrowDirection: CoachMarkArrowDirection`
  - Define `enum CoachMarkArrowDirection` with cases: `up`, `down`, `none`

- [ ] 1.2: In `Wishie/Helper/CoachMarkBoundsKey.swift` CREATE:
  - Import `SwiftUI`
  - Define `struct CoachMarkBoundsKey: PreferenceKey` with `typealias Value = [String: Anchor<CGRect>]`
  - Set `static var defaultValue: Value = [:]`
  - Implement `static func reduce(value: inout Value, nextValue: () -> Value)` by calling `value.merge(nextValue(), uniquingKeysWith: { $1 })`

# Task 2: Create Reusable CoachMarkOverlayView

- [ ] 2.1: In `Wishie/CustomView/CoachMarkOverlayView.swift` CREATE:
  - Import `SwiftUI`
  - Define `struct CoachMarkOverlayView: View` with:
    - `let highlightRect: CGRect?`
    - `let step: CoachMarkStep` (uses `CoachMarkStep` from task 1.1)
    - `let stepIndex: Int`
    - `let totalSteps: Int`
    - `let onNext: () -> Void`
    - `let onDone: () -> Void`
    - `@State private var isVisible: Bool = false`
  - `body`:
    - Outer `ZStack(alignment: .top)` with `.ignoresSafeArea()` and `.opacity(isVisible ? 1 : 0).animation(.easeInOut(duration: 0.3), value: isVisible).onAppear { isVisible = true }`
    - **Dim overlay with spotlight**: `GeometryReader { geo in Path { path in path.addRect(CGRect(origin: .zero, size: geo.size)); if let rect = highlightRect { path.addRoundedRect(in: rect.insetBy(dx: -10, dy: -10), cornerSize: CGSize(width: 14, height: 14)) } }.fill(Color.black.opacity(0.72), style: FillStyle(eoFill: true)).ignoresSafeArea().allowsHitTesting(false) }`
    - **Tooltip card**: a `VStack(spacing: 8)` containing `Text(step.title).font(.wishies(.bold, 16)).foregroundStyle(Color.black)` and `Text(step.message).font(.wishies(.regular, 14)).foregroundStyle(Color.darkGrey).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)`, styled with `padding(16)`, `background { RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")], startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F9C46B").opacity(0.6), lineWidth: 1.5)) }`, `padding(.horizontal, 28)`
    - **Arrow indicator**: if `step.arrowDirection == .up` and `highlightRect != nil`, render `Image(systemName: "arrowtriangle.up.fill").font(.system(size: 14)).foregroundStyle(Color(hex: "#F9C46B"))` positioned just above the tooltip card; if `step.arrowDirection == .down` and `highlightRect != nil`, render below the tooltip card — use `VStack(spacing: 0)` to stack arrow and card
    - **Step indicator + action button row**: `HStack { stepDots; Spacer(); actionButton }` inside the tooltip card bottom area — `stepDots` renders `HStack(spacing: 6)` of `Circle().fill(i == stepIndex ? Color(hex: "#F9C46B") : Color.darkGrey.opacity(0.35)).frame(width: 7, height: 7)` for `i in 0..<totalSteps`; `actionButton` renders `Button(stepIndex < totalSteps - 1 ? "Next" : "Done") { stepIndex < totalSteps - 1 ? onNext() : onDone() }` styled with `.font(.wishies(.bold, 14)).foregroundStyle(Color.black).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(LinearGradient(colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")], startPoint: .leading, endPoint: .trailing)))`
    - **Tooltip vertical positioning**: use a `VStack { Spacer().frame(height: tooltipTopOffset) ; tooltipContent }` where `tooltipTopOffset` is: if `highlightRect != nil && step.arrowDirection == .up` → `highlightRect!.maxY + 16`; if `highlightRect != nil && step.arrowDirection == .down` → `max(0, highlightRect!.minY - estimatedTooltipHeight - 16)`; else (nil or `.none`) → use `Spacer()` to center vertically — wrap in `GeometryReader` to calculate screen height for centering

# Task 3: Update HomeTutorialOverlayView to Coach Marks Implementation

- [ ] 3.1: In `Wishie/CustomView/HomeTutorialOverlayView.swift` UPDATE (replace entire file content):
  - Import `SwiftUI`
  - Define `struct HomeTutorialOverlayView: View` with:
    - `let anchors: [String: Anchor<CGRect>]` (anchors dictionary from `CoachMarkBoundsKey`, provided by `HomeView`)
    - `let onComplete: () -> Void`
    - `@State private var currentStep: Int = 0`
  - Define `private let steps: [CoachMarkStep]` as a stored constant (uses `CoachMarkStep` from task 1.1):
    ```
    CoachMarkStep(anchorID: "homeAddButton", title: "Create or Join", message: "Tap + to create a new wishlist or scan a QR code to join a friend's list", arrowDirection: .up)
    CoachMarkStep(anchorID: "homeTabSelector", title: "Your Lists", message: "Switch between your own wishlists and the wishlists you have joined", arrowDirection: .up)
    CoachMarkStep(anchorID: nil, title: "Swipe to Manage", message: "Swipe left on any wishlist to quickly delete it or leave a friend's list", arrowDirection: .none)
    ```
  - `body`:
    - `GeometryReader { proxy in ... }.ignoresSafeArea()`
    - Inside `GeometryReader`: resolve `highlightRect: CGRect?` by checking `steps[currentStep].anchorID`, looking it up in `anchors`, and calling `proxy[anchor]` — assign `nil` if `anchorID` is `nil` or key is absent
    - Render `CoachMarkOverlayView` (from task 2.1) passing: `highlightRect: highlightRect`, `step: steps[currentStep]`, `stepIndex: currentStep`, `totalSteps: steps.count`, `onNext: { withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 } }`, `onDone: onComplete`

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
