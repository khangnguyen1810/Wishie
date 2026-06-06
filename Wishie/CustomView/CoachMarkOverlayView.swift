import SwiftUI

struct CoachMarkOverlayView: View {
    let highlightRect: CGRect?
    let step: CoachMarkStep
    let stepIndex: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onDone: () -> Void

    @State private var isVisible: Bool = false

    private let estimatedTooltipHeight: CGFloat = 140

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geo.size))
                    if let rect = highlightRect {
                        path.addRoundedRect(
                            in: rect.insetBy(dx: -10, dy: -10),
                            cornerSize: CGSize(width: 14, height: 14)
                        )
                    }
                }
                .fill(Color.black.opacity(0.72), style: FillStyle(eoFill: true))
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            positionedTooltip
        }
        .ignoresSafeArea()
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear { isVisible = true }
    }

    @ViewBuilder
    private var positionedTooltip: some View {
        if let rect = highlightRect, step.arrowDirection == .up {
            GeometryReader { geo in
                VStack(alignment: .center, spacing: 0) {
                    Spacer().frame(height: rect.maxY + 16)
                    HStack {
                        Spacer().frame(width: rect.midX - 7)
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#F9C46B"))
                        Spacer()
                    }
                    tooltipCard
                    Spacer()
                }
                .frame(width: geo.size.width)
            }
        } else if let rect = highlightRect, step.arrowDirection == .down {
            GeometryReader { geo in
                VStack(alignment: .center, spacing: 0) {
                    Spacer().frame(height: max(0, rect.minY - estimatedTooltipHeight - 16))
                    tooltipCard
                    HStack {
                        Spacer().frame(width: rect.midX - 7)
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#F9C46B"))
                        Spacer()
                    }
                    Spacer()
                }
                .frame(width: geo.size.width)
            }
        } else {
            VStack(spacing: 0) {
                Spacer()
                tooltipCard
                    .padding(.bottom, 120)
                Spacer()
            }
        }
    }

    private var tooltipCard: some View {
        VStack(spacing: 8) {
            Text(step.title)
                .font(.wishies(.bold, 16))
                .foregroundStyle(Color.black)
            Text(step.message)
                .font(.wishies(.regular, 14))
                .foregroundStyle(Color.darkGrey)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                stepDots
                Spacer()
                actionButton
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#F9C46B").opacity(0.6), lineWidth: 1.5)
                )
        }
        .padding(.horizontal, 28)
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Circle()
                    .fill(i == stepIndex ? Color(hex: "#F9C46B") : Color.darkGrey.opacity(0.35))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var actionButton: some View {
        Button(stepIndex < totalSteps - 1 ? "Next" : "Done") {
            if stepIndex < totalSteps - 1 {
                onNext()
            } else {
                onDone()
            }
        }
        .font(.wishies(.bold, 14))
        .foregroundStyle(Color.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(LinearGradient(
                    colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
        )
    }
}
