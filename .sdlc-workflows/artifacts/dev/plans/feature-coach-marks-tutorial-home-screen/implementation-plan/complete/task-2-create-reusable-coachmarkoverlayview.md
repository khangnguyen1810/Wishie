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

