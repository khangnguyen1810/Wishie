//
//  WishieTextView.swift
//  Wishie
//

import SwiftUI

/// A multi-line counterpart of `WishieTextField`. It shares the same box (`wishieTextFieldChrome`),
/// label, font and error styles, and grows from 2 to 4 lines. When `maxLength` is set it trims
/// extra input and shows a `count/max` counter under the box.
///
/// Focus is driven by the screen's own `@FocusState`, so its keyboard Done button can dismiss
/// this field too.
struct WishieTextView<Field: Hashable>: View {
    let label: String?
    let placeHolder: String
    @Binding var text: String
    var maxLength: Int?
    var error: String?

    private var focus: FocusState<Field?>.Binding
    private let field: Field

    init(
        _ label: String? = nil,
        _ placeHolder: String = "",
        text: Binding<String>,
        maxLength: Int? = nil,
        error: String? = nil,
        focus: FocusState<Field?>.Binding,
        equals field: Field
    ) {
        self.label = label
        self.placeHolder = placeHolder
        self._text = text
        self.maxLength = maxLength
        self.error = error
        self.focus = focus
        self.field = field
    }

    private var isFocused: Bool {
        focus.wrappedValue == field
    }

    private var chromeState: WishieTextFieldChromeState {
        if error != nil { return .error }
        return isFocused ? .focused : .idle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(Color("obInk"))
                    .accessibilityHidden(true)
            }
            TextField(placeHolder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .focused(focus, equals: field)
                .font(.wishies(.regular, 17))
                .foregroundStyle(Color("obInk"))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
                .wishieTextFieldChrome(chromeState)
                .contentShape(Rectangle())
                .onTapGesture {
                    focus.wrappedValue = field
                }
                .onChange(of: text) { _, newValue in
                    if let maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }
                .accessibilityLabel(label ?? placeHolder)
                .accessibilityHint(error ?? "")
            if let error {
                Text(error)
                    .font(.wishies(.medium, 13))
                    .foregroundStyle(Color("obError"))
            }
            if let maxLength {
                Text("\(text.count)/\(maxLength)")
                    .font(.wishies(.medium, 13))
                    .foregroundStyle(text.count == maxLength ? Color("obError") : Color("obInk").opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview {
    struct Demo: View {
        enum Field: Hashable { case description }
        @State private var text = "A cozy birthday list"
        @FocusState private var focus: Field?

        var body: some View {
            VStack(spacing: 18) {
                WishieTextView("Description", "Description...", text: $text, maxLength: 200, focus: $focus, equals: .description)
            }
            .padding(30)
            .background(Color("obScreenBg"))
        }
    }
    return Demo()
}
