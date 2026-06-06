import SwiftUI

struct HomeTutorialOverlayView: View {
    let anchors: [String: Anchor<CGRect>]
    let onComplete: () -> Void

    @State private var currentStep: Int = 0

    private let steps: [CoachMarkStep] = [
        CoachMarkStep(
            anchorID: "homeAddButton",
            title: "Create or Join",
            message: "Tap + to create a new wishlist or scan a QR code to join a friend's list",
            arrowDirection: .up
        ),
        CoachMarkStep(
            anchorID: "homeTabSelector",
            title: "Your Lists",
            message: "Switch between your own wishlists and the wishlists you have joined",
            arrowDirection: .up
        ),
        CoachMarkStep(
            anchorID: "homeExampleItem",
            title: "Swipe to Manage",
            message: "Swipe left on any wishlist to quickly delete it or leave a friend's list",
            arrowDirection: .down
        )
    ]

    var body: some View {
        GeometryReader { proxy in
            let currentStepData = steps[min(currentStep, steps.count - 1)]
            let highlightRect: CGRect? = {
                guard let anchorID = currentStepData.anchorID,
                      let anchor = anchors[anchorID] else { return nil }
                return proxy[anchor]
            }()

            CoachMarkOverlayView(
                highlightRect: highlightRect,
                step: currentStepData,
                stepIndex: currentStep,
                totalSteps: steps.count,
                onNext: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = min(currentStep + 1, steps.count - 1)
                    }
                },
                onDone: onComplete
            )
        }
        .ignoresSafeArea()
    }
}
