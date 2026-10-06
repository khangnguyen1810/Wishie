//
//  AuthField.swift
//  Wishie
//

import SwiftUI

/// What an `AuthField` holds. Decides its keyboard, autofill behavior and identifiers.
enum AuthFieldKind: Equatable {
    case firstName
    case lastName
    case email
    case phone
    /// `isNew` asks iOS to offer saving a new password rather than filling a saved one.
    case password(isNew: Bool)

    var id: String {
        switch self {
        case .firstName: "firstName"
        case .lastName: "lastName"
        case .email: "email"
        case .phone: "phone"
        case .password: "password"
        }
    }

    var isPassword: Bool {
        if case .password = self { return true }
        return false
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .email: .emailAddress
        case .phone: .phonePad
        case .firstName, .lastName, .password: .default
        }
    }

    var contentType: UITextContentType {
        switch self {
        case .firstName: .givenName
        case .lastName: .familyName
        case .email: .emailAddress
        case .phone: .telephoneNumber
        case .password(let isNew): isNew ? .newPassword : .password
        }
    }

    var capitalization: TextInputAutocapitalization {
        switch self {
        case .firstName, .lastName: .words
        case .email, .phone, .password: .never
        }
    }
}

enum AuthFieldChromeState {
    case idle
    case focused
    case error
}

/// The white rounded box shared by every auth field, with its idle, focused and error borders.
private struct AuthFieldChrome: ViewModifier {
    let state: AuthFieldChromeState

    private var borderColor: Color {
        switch state {
        case .idle: Color("obInk").opacity(0.12)
        case .focused: Color("obInk")
        case .error: Color("obError")
        }
    }

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: state == .idle ? 1.5 : 2)
            }
            .background {
                if state == .focused {
                    RoundedRectangle(cornerRadius: 19)
                        .fill(Color.lightYellow)
                        .padding(-3)
                }
            }
    }
}

extension View {
    func authFieldChrome(_ state: AuthFieldChromeState) -> some View {
        modifier(AuthFieldChrome(state: state))
    }
}

/// A labeled text field for the auth screens. Shows a focus ring while editing and an inline
/// message when `error` is set. The password kinds add a show/hide button.
struct AuthField: View {
    let label: String
    let placeHolder: String
    @Binding var text: String
    let kind: AuthFieldKind
    var error: String?

    /// Drives the border only. Screens attach their own `.focused` to move between fields.
    @FocusState private var isFocused: Bool
    @State private var isRevealed = false
    @Environment(\.authScrollToField) private var scrollToField

    init(_ label: String,_ placeHolder: String = "", text: Binding<String>, kind: AuthFieldKind, error: String? = nil) {
        self.label = label
        self._text = text
        self.kind = kind
        self.error = error
        self.placeHolder = placeHolder
    }

    private var chromeState: AuthFieldChromeState {
        if error != nil { return .error }
        return isFocused ? .focused : .idle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.wishies(.bold, 15))
                .foregroundStyle(Color("obInk"))
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                input
                if kind.isPassword {
                    revealButton
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, kind.isPassword ? 4 : 16)
            .frame(minHeight: 56)
            .authFieldChrome(chromeState)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
            if let error {
                Text(error)
                    .font(.wishies(.medium, 13))
                    .foregroundStyle(Color("obError"))
                    .accessibilityIdentifier("auth.\(kind.id)Error")
            }
        }
        .id(kind.id)
        .task(id: isFocused) {
            guard isFocused else { return }
            // iOS scrolls only the text line into view. Once the keyboard has finished rising,
            // bring the whole box clear of the keyboard's Done bar. The task is cancelled if
            // focus leaves first.
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            scrollToField(kind.id)
        }
    }

    private var input: some View {
        Group {
            if kind.isPassword && !isRevealed {
                SecureField(placeHolder, text: $text)
            } else {
                TextField(placeHolder, text: $text)
            }
        }
        .frame(minHeight: 56)
        .focused($isFocused)
        .font(.wishies(.regular, 17))
        .foregroundStyle(Color("obInk"))
        .keyboardType(kind.keyboardType)
        .textContentType(kind.contentType)
        .textInputAutocapitalization(kind.capitalization)
        .autocorrectionDisabled()
        .accessibilityLabel(label)
        .accessibilityHint(error ?? "")
        .accessibilityIdentifier("auth.field.\(kind.id)")
    }

    private var revealButton: some View {
        Button {
            // Swapping SecureField and TextField drops focus, so hand it back.
            let wasFocused = isFocused
            isRevealed.toggle()
            if wasFocused {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
        } label: {
            Image(isRevealed ? "eye-slash-solid-full" : "eye-solid-full")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
    }
}

#Preview {
    VStack(spacing: 18) {
        AuthField("Email", text: .constant("linh@example.com"), kind: .email)
        AuthField("Email", text: .constant("linh@example"), kind: .email, error: AuthValidation.emailErrorMessage)
        AuthField("Password", text: .constant("secret123"), kind: .password(isNew: false))
    }
    .padding(30)
    .background(Color("obScreenBg"))
}
