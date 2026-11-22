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
    /// Point size the native launch screen draws the logo at (the asset's own size).
    var logoSize: CGSize = UIImage(named: "SplashLogo")?.size ?? CGSize(width: 120, height: 120)
    /// Corner radius of the rounded tile in `SplashLogo`, as a fraction of its width.
    var logoCornerRatio: CGFloat = 0.23
}

/// Where the splash is in its hand-off, so the screen underneath can time its own entrance.
enum SplashPhase {
    /// The splash still fully covers the app.
    case covering
    /// The splash is shrinking into the screen's logo; content should animate in.
    case revealing
    /// The splash is gone.
    case done
}

extension EnvironmentValues {
    @Entry var splashPhase: SplashPhase = .done
    /// A screen that shows the app logo reports its frame (global coordinates) here, and the
    /// splash collapses into that spot instead of punching a hole through to the content.
    @Entry var reportSplashLogoFrame = SplashLogoReporter()
}

/// Wraps the report closure so the environment can compare it. The closure only writes to the
/// splash modifier's state, so any two reporters are interchangeable.
struct SplashLogoReporter: Equatable {
    var report: (CGRect) -> Void = { _ in }

    func callAsFunction(_ frame: CGRect) { report(frame) }

    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

extension View {
    /// Covers the content with the splash, then either collapses it into the logo of the
    /// screen underneath (when that screen reports one) or "punches" the logo out to reveal it.
    func splashScreen(config: SplashConfig = .init()) -> some View {
        modifier(SplashScreenModifier(config: config))
    }

    /// Marks this view as the logo the splash should collapse into.
    func splashLogoTarget() -> some View {
        modifier(SplashLogoTargetModifier())
    }
}

private struct SplashLogoTargetModifier: ViewModifier {
    @Environment(\.reportSplashLogoFrame) private var report

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            report(frame)
        }
    }
}

private struct SplashScreenModifier: ViewModifier {
    var config: SplashConfig
    @State private var showSplash: Bool = true
    @State private var phase: SplashPhase = .covering
    @State private var logoTarget: CGRect?

    func body(content: Content) -> some View {
        content
            .environment(\.splashPhase, phase)
            .environment(\.reportSplashLogoFrame, SplashLogoReporter { frame in
                guard showSplash, frame.width > 0, frame.height > 0 else { return }
                logoTarget = frame
            })
            .overlay {
                if showSplash {
                    SplashContainer(config: config, logoTarget: $logoTarget) { newPhase in
                        phase = newPhase
                    } onFinish: {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            phase = .done
                            showSplash = false
                        }
                    }
                }
            }
    }
}

/// Shows the native launch look, then picks the exit animation once the delay has passed,
/// by which time the screen underneath has laid out and reported its logo (if any).
private struct SplashContainer: View {
    var config: SplashConfig
    /// A binding, not a value: the `.task` below must read the latest frame, not the one
    /// captured when the view was first created (which is always nil).
    @Binding var logoTarget: CGRect?
    var onPhase: (SplashPhase) -> Void
    var onFinish: () -> Void

    private enum Style { case launch, collapse, reveal }
    @State private var style: Style = .launch

    var body: some View {
        ZStack {
            switch style {
            case .launch:
                config.tint
                    .overlay { config.logo }
                    .ignoresSafeArea()
                    // Swap instantly: the exit animation that starts right after must not
                    // cross-fade this static copy out, or two logos show for a moment.
                    .transition(.identity)
            case .collapse:
                if let logoTarget {
                    SplashCollapseView(config: config, target: logoTarget, onPhase: onPhase, onFinish: onFinish)
                        .transition(.identity)
                }
            case .reveal:
                SplashRevealView(config: config, onFinish: onFinish)
                    .transition(.identity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(config.initialDelay))
            if logoTarget != nil {
                style = .collapse
            } else {
                onPhase(.revealing)
                style = .reveal
            }
        }
    }
}

// MARK: - Collapse: the splash shrinks into a rounded icon that lands on the screen's logo

private struct SplashCollapseView: View {
    var config: SplashConfig
    var target: CGRect
    var onPhase: (SplashPhase) -> Void
    var onFinish: () -> Void

    @State private var collapsed: Bool = false
    @State private var pushIcon: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let localTarget = target.offsetBy(dx: -origin.x, dy: -origin.y)
            let full = CGRect(origin: .zero, size: proxy.size)
            let frame = collapsed ? localTarget : full
            let logoSize = collapsed ? localTarget.size : config.logoSize
            let push: CGFloat = pushIcon ? 60 : 0

            ZStack {
                RoundedRectangle(
                    cornerRadius: collapsed ? localTarget.width * config.logoCornerRatio : 0,
                    style: .continuous
                )
                .fill(config.tint)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY + push)

                config.logo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: logoSize.width, height: logoSize.height)
                    .position(x: frame.midX, y: frame.midY + push)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(!collapsed)
        .task {
            guard !collapsed else { return }
            onPhase(.revealing)
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                collapsed = true
                pushIcon = true
            }

            try? await Task.sleep(for: .seconds(0.15))
            withAnimation(.bouncy(duration: 0.4)) {
                pushIcon = false
            }

            try? await Task.sleep(for: .seconds(0.5))
            onFinish()
        }
    }
}

// MARK: - Reveal: the logo becomes a hole that grows to reveal the app

private struct SplashRevealView: View {
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
