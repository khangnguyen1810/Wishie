import SwiftUI
import UIKit

struct KeyboardHeightModifier: ViewModifier {
    @Binding var keyboardHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                            guard
                                let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                                let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
                                let animationCurveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
                            else { return }

                            let viewBottomY = geometry.frame(in: .global).maxY
                            let effectiveHeight = max(0, viewBottomY - keyboardFrame.minY)
                            let mappedAnimation = animation(for: animationCurveRaw, duration: animationDuration)

                            withAnimation(mappedAnimation) {
                                keyboardHeight = effectiveHeight
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                            guard
                                let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
                                let animationCurveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
                            else { return }

                            let mappedAnimation = animation(for: animationCurveRaw, duration: animationDuration)

                            withAnimation(mappedAnimation) {
                                keyboardHeight = 0
                            }
                        }
                }
            )
    }

    private func animation(for curveRaw: Int, duration: Double) -> Animation {
        switch UIView.AnimationCurve(rawValue: curveRaw) {
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        default:
            return .linear(duration: duration)
        }
    }
}

extension View {
    func keyboardHeight(_ height: Binding<CGFloat>) -> some View {
        modifier(KeyboardHeightModifier(keyboardHeight: height))
    }
}
