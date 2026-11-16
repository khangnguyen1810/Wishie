//
//  SplashScreenView.swift
//  Wishie
//

import SwiftUI

struct SplashConfig {
    /// Must match `UIImageName` / `UIColorName` of `UILaunchScreen` in Info.plist
    /// so the native launch screen hands off to this view without any visible jump.
    var logo: Image = Image(.splashLogo)
    var tint: Color = .lightYellow1
    var initialDelay: CGFloat = 0.35
}

extension View {
    /// Covers the content with the splash, then "punches" the logo out to reveal it.
    func splashScreen(config: SplashConfig = .init()) -> some View {
        modifier(SplashScreenModifier(config: config))
    }
}

private struct SplashScreenModifier: ViewModifier {
    var config: SplashConfig
    @State private var showSplash: Bool = true

    func body(content: Content) -> some View {
        content
            .overlay {
                if showSplash {
                    SplashScreenView(config: config) {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            showSplash = false
                        }
                    }
                }
            }
    }
}

private struct SplashScreenView: View {
    var config: SplashConfig
    var onFinish: () -> Void
    @State private var scaleDown: Bool = false
    @State private var scaleUp: Bool = false

    var body: some View {
        Rectangle()
            .fill(.clear)
            .overlay {
                GeometryReader {
                    let scaleFactor: CGFloat = 4
                    let size = $0.size.applying(.init(scaleX: scaleFactor, y: scaleFactor))

                    Rectangle()
                        .fill(config.tint)
                        /// Inverse mask: the logo becomes a hole that grows to reveal the app
                        .mask {
                            Rectangle()
                                .overlay {
                                    logoView(isMask: true, size: size)
                                }
                        }
                        .overlay {
                            logoView(isMask: false, size: size)
                        }
                }
            }
            .ignoresSafeArea()
            .task {
                guard !scaleDown else { return }

                try? await Task.sleep(for: .seconds(config.initialDelay))
                withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                    scaleDown = true
                }

                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.interpolatingSpring(duration: 0.6, bounce: 0, initialVelocity: 0)) {
                    scaleUp = true
                }

                try? await Task.sleep(for: .seconds(0.6))
                onFinish()
            }
    }

    private func logoView(isMask: Bool, size: CGSize) -> some View {
        config.logo
            .blendMode(isMask ? .destinationOut : .normal)
            .scaleEffect(scaleDown ? 0.8 : 1)
            .visualEffect { [scaleUp] content, proxy in
                let imageSize = proxy.size
                let scale = max(
                    size.width / imageSize.width,
                    size.height / imageSize.height
                )

                return content
                    .scaleEffect(scaleUp ? scale : 1)
                    .opacity(isMask ? (scaleUp ? 1 : 0) : (scaleUp ? 0 : 1))
            }
    }
}

#Preview {
    Text("Wishie")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .splashScreen()
}
