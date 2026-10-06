//
//  AuthScaffold.swift
//  Wishie
//

import SwiftUI

private struct AuthScrollToFieldKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

extension EnvironmentValues {
    /// Scrolls the scaffold so the field with this id sits clear of the keyboard.
    var authScrollToField: (String) -> Void {
        get { self[AuthScrollToFieldKey.self] }
        set { self[AuthScrollToFieldKey.self] = newValue }
    }
}

/// The frame shared by the auth form screens: a yellow stage holding the title, a back button
/// that stays put, a scrolling body, and an optional footer that rides above the keyboard.
struct AuthScaffold<Content: View, Footer: View>: View {
    let screenID: String
    let title: String
    let subtitle: String
    let cardTheme: GradientTheme
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Width the decorative card is drawn at.
    private let cardWidth: CGFloat = 130
    /// How far the yellow runs past the top edge, so pulling down never shows cream above it.
    private let overscrollCover: CGFloat = 1000

    init(
        screenID: String,
        title: String,
        subtitle: String,
        cardTheme: GradientTheme,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.screenID = screenID
        self.title = title
        self.subtitle = subtitle
        self.cardTheme = cardTheme
        self.content = content
        self.footer = footer
    }

    /// The card gives way to the title at accessibility text sizes.
    private var showsCard: Bool {
        !dynamicTypeSize.isAccessibilitySize
    }

    /// Below accessibility sizes the title is drawn one Text per line, pulled together. At
    /// accessibility sizes it is a single Text that wraps, so no line is cut short. Dynamic Type
    /// for the title stops at accessibility1.
    @ViewBuilder
    private var titleView: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Text(spokenTitle)
                .font(.wishiesDisplay(.bold, 32))
                .foregroundStyle(Color("obInk"))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        } else {
            VStack(alignment: .leading, spacing: -14) {
                ForEach(Array(titleLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.wishiesDisplay(.bold, 32))
                        .foregroundStyle(Color("obInk"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    private var titleLines: [String] {
        title.components(separatedBy: "\n")
    }

    private var spokenTitle: String {
        titleLines.joined(separator: " ")
    }

    var body: some View {
        ScrollViewReader { proxy in
            scrollingBody
                .environment(\.authScrollToField) { id in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(id)
                    }
                }
        }
    }

    private var scrollingBody: some View {
        ScrollView {
            VStack(spacing: 0) {
                stage
                VStack(alignment: .leading, spacing: 18) {
                    content()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background {
            Color("obScreenBg")
                .ignoresSafeArea()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .overlay(alignment: .top) {
            backStrip
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if Footer.self != EmptyView.self {
                footer()
                    .padding(.horizontal, 30)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color("obScreenBg"))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }

    private var stage: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleView
                .accessibilityRepresentation {
                    Text(spokenTitle)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("auth.\(screenID).title")
                }
            Text(subtitle)
                .font(.wishies(.regular, 16))
                .foregroundStyle(Color("obInk").opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 30)
        .padding(.trailing, showsCard ? 120 : 30)
        // 8pt gap, the 44pt back button, 16pt gap.
        .padding(.top, 68)
        .padding(.bottom, 24)
        .background {
            ZStack(alignment: .bottomTrailing) {
                Color.lightYellow
                if showsCard {
                    decorativeCard
                }
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 44, bottomTrailingRadius: 44))
            .padding(.top, -overscrollCover)
        }
    }

    /// One sample wishlist peeking out of the stage's corner, echoing the landing's fan.
    private var decorativeCard: some View {
        SampleWishlistCard(wishlist: .sample(for: cardTheme))
            .scaleEffect(cardWidth / WishlistFanLayout.designCardWidth, anchor: .bottomTrailing)
            .rotationEffect(.degrees(-9))
            // y is 68 so the card's top edge clears the pinned back strip at rest.
            .offset(x: 40, y: 68)
            .dynamicTypeSize(.large)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// A solid yellow strip behind the back button, so scrolled content passes under it. At rest it
    /// matches the stage and cannot be seen.
    private var backStrip: some View {
        HStack(spacing: 0) {
            backButton
            Spacer(minLength: 0)
        }
        .padding(.leading, 30)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            Color.lightYellow
                .ignoresSafeArea(edges: .top)
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("obInk"))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white))
        }
        .accessibilityLabel("Back")
        .accessibilityIdentifier("auth.backButton")
    }
}

extension AuthScaffold where Footer == EmptyView {
    init(
        screenID: String,
        title: String,
        subtitle: String,
        cardTheme: GradientTheme,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            screenID: screenID,
            title: title,
            subtitle: subtitle,
            cardTheme: cardTheme,
            content: content,
            footer: { EmptyView() }
        )
    }
}

#Preview {
    AuthScaffold(
        screenID: "login",
        title: "Welcome back.",
        subtitle: "Log in to see your lists.",
        cardTheme: .coral
    ) {
        AuthField("Email", text: .constant(""), kind: .email)
        AuthField("Password", text: .constant(""), kind: .password(isNew: false))
    }
}
