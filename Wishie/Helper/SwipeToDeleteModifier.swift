import SwiftUI

/// Whether a swipeable row should be resting open (action revealed) or closed.
enum SwipeRevealState {
    case closed
    case open
}

/// Decides whether a swipe gesture should settle open or closed, given how far
/// the row had already been dragged (`baseOffset`) and the in-flight drag
/// translation. Kept as a pure function so the snap threshold can be unit
/// tested without rendering any view.
func swipeRevealState(baseOffset: CGFloat, translation: CGFloat, actionWidth: CGFloat) -> SwipeRevealState {
    let projected = baseOffset + translation
    return -projected > actionWidth / 2 ? .open : .closed
}

/// A List-free replacement for `.swipeActions`: reveals a single trailing
/// action button by dragging the row left, for use with `ScrollView`/`LazyVStack`
/// rows (which don't support `.swipeActions`).
private struct SwipeToDeleteModifier: ViewModifier {
    let tint: Color
    let icon: String
    let label: String
    let action: () -> Void

    @State private var revealState: SwipeRevealState = .closed
    @GestureState private var dragTranslation: CGFloat = 0

    private let actionWidth: CGFloat = 92

    private var baseOffset: CGFloat {
        revealState == .open ? -actionWidth : 0
    }

    private var currentOffset: CGFloat {
        baseOffset + dragTranslation
    }

    /// 0 when fully closed, 1 when fully open. Drives both the button's
    /// opacity and whether it can accept taps, so a rotated card's corner
    /// (which doesn't fully cover this button's rectangular bounds at rest)
    /// never shows or intercepts a stray tap while "closed".
    private var revealProgress: CGFloat {
        min(1, max(0, -currentOffset / actionWidth))
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    revealState = .closed
                }
                action()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                    Text(label)
                        .font(.wishiesDisplay(.bold, 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .foregroundStyle(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
            }
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .opacity(revealProgress)
            .allowsHitTesting(revealState == .open)

            content
                .offset(x: currentOffset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12)
                        .updating($dragTranslation) { value, state, _ in
                            state = min(0, max(value.translation.width, -actionWidth * 1.4 - baseOffset))
                        }
                        .onEnded { value in
                            let next = swipeRevealState(
                                baseOffset: baseOffset,
                                translation: value.translation.width,
                                actionWidth: actionWidth
                            )
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                revealState = next
                            }
                        }
                )
        }
    }
}

extension View {
    /// Reveals a single destructive action by swiping the row left.
    /// Use in place of `.swipeActions` for rows hosted in a `ScrollView`/`LazyVStack`.
    func swipeToDelete(tint: Color, icon: String = "trash", label: String, action: @escaping () -> Void) -> some View {
        modifier(SwipeToDeleteModifier(tint: tint, icon: icon, label: label, action: action))
    }
}
