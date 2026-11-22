//
//  WelcomeScreen.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.splashPhase) private var splashPhase

    /// The copy and button rise in with a blur once the splash starts collapsing into the logo.
    private var contentRevealed: Bool { splashPhase != .covering }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WishBubbleStage()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Group {
                    copy
                        .padding(.top, 16)

                    NavigationLink(destination: OnboardingContainerView()) {
                    Text("Start my first wish")
                        .font(.wishies(.bold, 17))
                        .foregroundStyle(WelcomePalette.cream)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(WelcomePalette.brown, in: RoundedRectangle(cornerRadius: 18))
                }
                    .padding(.top, 28)
                    .accessibilityIdentifier("welcome.startButton")
                }
                .blur(radius: contentRevealed ? 0 : 15)
                .opacity(contentRevealed ? 1 : 0)
                .offset(y: contentRevealed ? 0 : 240)
                .animation(.bouncy(duration: 0.6, extraBounce: 0.05).delay(0.1), value: contentRevealed)
            }
            .padding(.horizontal, 24)
            .safeAreaPadding(.bottom, 24)
            .background {
                Color("obScreenBg")
                    .ignoresSafeArea()
            }
        }
    }

    private var copy: some View {
        VStack(spacing: 10) {
            // Baloo 2 has tall line metrics, so the two lines are stacked with negative spacing.
            VStack(spacing: -16) {
                Text("What are you")
                Text("wishing for?")
            }
            .font(.wishiesDisplay(.extraBold, 40))
            .foregroundStyle(Color("obInk"))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityElement(children: .combine)
            Text("Big or small, Wishie keeps every wish so the people who love you never have to guess.")
                .font(.wishies(.regular, 16))
                .foregroundStyle(Color("obInk").opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Palette

/// Colors taken from the app icon (orange ground, brown outline, yellow fill).
private enum WelcomePalette {
    static let orange = Color(hex: "FFC265")
    static let brown = Color(hex: "B84701")
    static let yellow = Color(hex: "F6D685")
    static let cream = Color(hex: "FFF4DC")
}

// MARK: - Bubble stage

/// The app icon surrounded by floating wish bubbles. Tapping a bubble pops it, and a new wish
/// floats back into the same spot a moment later.
private struct WishBubbleStage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.splashPhase) private var splashPhase

    @State private var bubbles: [WishBubble] = WishBubble.initial
    @State private var bursts: [BubbleBurst] = []
    @State private var nextWishIndex = WishBubble.slots.count
    @State private var popCount = 0
    @State private var userHasPopped = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let haloSize = min(size.width, size.height) * 0.68
            let logoSize = min(120, haloSize * 0.42)
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
            // Bubbles start tucked behind the logo and burst outward as the splash lands on it.
            let revealed = splashPhase != .covering

            ZStack {
                Circle()
                    .fill(WelcomePalette.orange.opacity(0.35))
                    .frame(width: haloSize, height: haloSize)
                    .scaleEffect(revealed ? 1 : 0.3)
                    .opacity(revealed ? 1 : 0)
                    .animation(.bouncy(duration: 0.7, extraBounce: 0.1).delay(0.15), value: revealed)
                    .position(center)

                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .shadow(color: WelcomePalette.brown.opacity(splashPhase == .done ? 0.3 : 0), radius: 20, y: 18)
                    .animation(.easeOut(duration: 0.3), value: splashPhase)
                    // The splash flies its own copy of the logo here, so this one stays hidden until it lands.
                    .opacity(splashPhase == .done ? 1 : 0)
                    .splashLogoTarget()
                    .position(center)
                    .accessibilityLabel("Wishie")

                ForEach(bursts) { burst in
                    BubbleBurstView(color: burst.color, reduceMotion: reduceMotion)
                        .position(x: burst.slot.x * size.width, y: burst.slot.y * size.height)
                        .allowsHitTesting(false)
                }

                ForEach(Array(bubbles.enumerated()), id: \.element.id) { index, bubble in
                    if bubble.isVisible {
                        WishBubbleView(bubble: bubble, reduceMotion: reduceMotion) {
                            userHasPopped = true
                            pop(bubble)
                        }
                        .scaleEffect(revealed ? 1 : 0.2)
                        .opacity(revealed ? 1 : 0)
                        .position(
                            x: revealed ? bubble.slot.x * size.width : center.x,
                            y: revealed ? bubble.slot.y * size.height : center.y
                        )
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.62).delay(0.2 + Double(index) * 0.05),
                            value: revealed
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.2).combined(with: .opacity),
                                removal: reduceMotion ? .opacity : .scale(scale: 1.6).combined(with: .opacity)
                            )
                        )
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: popCount)
        .task {
            // One hint pop, so people notice the bubbles can be tapped.
            try? await Task.sleep(for: .seconds(2.8))
            guard !userHasPopped, let bubble = bubbles.filter(\.isVisible).randomElement() else { return }
            pop(bubble)
        }
    }

    private func pop(_ bubble: WishBubble) {
        guard let index = bubbles.firstIndex(where: { $0.id == bubble.id }), bubbles[index].isVisible else { return }

        popCount += 1
        let burst = BubbleBurst(slot: bubble.slot, color: bubble.slot.style.burstColor)
        bursts.append(burst)
        withAnimation(.easeOut(duration: 0.18)) {
            bubbles[index].isVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            bursts.removeAll { $0.id == burst.id }

            try? await Task.sleep(for: .seconds(1.1))
            let shown = Set(bubbles.filter(\.isVisible).map(\.text))
            var text = WishBubble.wishes[nextWishIndex % WishBubble.wishes.count]
            while shown.contains(text) {
                nextWishIndex += 1
                text = WishBubble.wishes[nextWishIndex % WishBubble.wishes.count]
            }
            nextWishIndex += 1

            guard let slotIndex = bubbles.firstIndex(where: { $0.slot == bubble.slot }) else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                bubbles[slotIndex] = WishBubble(slot: bubble.slot, text: text)
            }
        }
    }
}

// MARK: - Models

private struct WishBubble: Identifiable {
    let id = UUID()
    let slot: Slot
    let text: String
    var isVisible = true

    enum Style {
        case white, yellow, pink, purple, ink

        var fill: Color {
            switch self {
            case .white: .white
            case .yellow: WelcomePalette.yellow
            case .pink: Color("wishiePink")
            case .purple: Color("purple_dream")
            case .ink: Color("obInk")
            }
        }

        var text: Color {
            self == .ink ? Color("obScreenBg") : Color("obInk")
        }

        var burstColor: Color {
            self == .white ? WelcomePalette.orange : fill
        }

        var hasShadow: Bool { self == .white }
    }

    /// A fixed spot on the stage, in fractions of its size, so the layout scales to any phone.
    struct Slot: Hashable {
        let x: CGFloat
        let y: CGFloat
        let rotation: Double
        let style: Style
        let floatDuration: Double
    }

    static let slots: [Slot] = [
        Slot(x: 0.26, y: 0.14, rotation: -6, style: .white, floatDuration: 2.4),
        Slot(x: 0.76, y: 0.22, rotation: 5, style: .yellow, floatDuration: 2.9),
        Slot(x: 0.24, y: 0.34, rotation: 4, style: .pink, floatDuration: 2.6),
        Slot(x: 0.82, y: 0.54, rotation: -4, style: .white, floatDuration: 3.1),
        Slot(x: 0.20, y: 0.70, rotation: -3, style: .purple, floatDuration: 2.7),
        Slot(x: 0.72, y: 0.80, rotation: 6, style: .ink, floatDuration: 2.5),
        Slot(x: 0.40, y: 0.92, rotation: 2, style: .white, floatDuration: 3.0),
    ]

    static let wishes: [String] = [
        "New sneakers", "Concert tickets", "A trip to Đà Lạt", "Film camera",
        "Pottery class", "That linen dress", "Matcha set", "Vinyl player",
        "Cozy hoodie", "Lego set", "Spa day", "Mechanical keyboard",
        "Perfume", "Polaroid", "Board game night",
    ]

    static var initial: [WishBubble] {
        zip(slots, wishes).map { WishBubble(slot: $0, text: $1) }
    }
}

private struct BubbleBurst: Identifiable {
    let id = UUID()
    let slot: WishBubble.Slot
    let color: Color
}

// MARK: - Bubble views

private struct WishBubbleView: View {
    let bubble: WishBubble
    let reduceMotion: Bool
    let onPop: () -> Void

    @State private var floating = false

    var body: some View {
        Button(action: onPop) {
            Text(bubble.text)
                .font(.wishies(.bold, 14))
                .foregroundStyle(bubble.slot.style.text)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(bubble.slot.style.fill, in: Capsule())
                .shadow(color: bubble.slot.style.hasShadow ? Color("obInk").opacity(0.08) : .clear, radius: 9, y: 6)
                .contentShape(Capsule())
        }
        .buttonStyle(BubblePressStyle())
        .rotationEffect(.degrees(bubble.slot.rotation))
        .offset(y: floating ? -6 : 6)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: bubble.slot.floatDuration).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
        .accessibilityLabel(bubble.text)
        .accessibilityHint("Pops this wish bubble")
    }
}

/// Squashes the bubble slightly while a finger is on it, like pressing a real bubble.
private struct BubblePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

/// Small dots that fly out from where a bubble popped and fade away.
private struct BubbleBurstView: View {
    let color: Color
    let reduceMotion: Bool

    @State private var exploded = false
    private let particleCount = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: exploded ? 0.5 : 3)
                .frame(width: exploded ? 90 : 30, height: exploded ? 90 : 30)
                .opacity(exploded ? 0 : 0.8)

            if !reduceMotion {
                ForEach(0..<particleCount, id: \.self) { index in
                    let angle = Double(index) / Double(particleCount) * 2 * .pi
                    let distance: CGFloat = index.isMultiple(of: 2) ? 52 : 38
                    Circle()
                        .fill(color)
                        .frame(width: index.isMultiple(of: 2) ? 8 : 5)
                        .offset(
                            x: exploded ? cos(angle) * distance : 0,
                            y: exploded ? sin(angle) * distance : 0
                        )
                        .scaleEffect(exploded ? 0.3 : 1)
                        .opacity(exploded ? 0 : 1)
                }
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                exploded = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
