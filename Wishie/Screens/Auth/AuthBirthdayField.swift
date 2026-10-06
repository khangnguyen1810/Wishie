//
//  AuthBirthdayField.swift
//  Wishie
//

import SwiftUI

/// The Sign up birthday field. Looks like an `AuthField`; tapping it opens a date picker sheet.
struct AuthBirthdayField: View {
    @Binding var date: Date

    @State private var showPicker = false
    /// The picker edits a copy, so the binding changes only when Done is tapped.
    @State private var draft = Date()

    private var formattedDate: String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Birthday")
                .font(.wishies(.bold, 15))
                .foregroundStyle(Color("obInk"))
                .accessibilityHidden(true)
            Button {
                hideKeyboard()
                draft = date
                showPicker = true
            } label: {
                Text(formattedDate)
                    .font(.wishies(.regular, 17))
                    .foregroundStyle(Color("obInk"))
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .padding(.horizontal, 16)
                    .authFieldChrome(showPicker ? .focused : .idle)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Birthday")
            .accessibilityValue(formattedDate)
            .accessibilityIdentifier("auth.field.birthday")
        }
        .sheet(isPresented: $showPicker) {
            VStack(spacing: 16) {
                DatePicker("Birthday", selection: $draft, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                WishieButton(
                    title: "Done",
                    enabled: true,
                    filColor: Color("obInk"),
                    titleColor: .white
                ) {
                    date = draft
                    showPicker = false
                }
                .accessibilityIdentifier("auth.birthdayDoneButton")
            }
            .padding(.horizontal, 30)
            .padding(.top, 16)
            .presentationDetents([.height(340)])
            .presentationBackground(Color("obScreenBg"))
        }
    }
}

#Preview {
    AuthBirthdayField(date: .constant(Date()))
        .padding(30)
        .background(Color("obScreenBg"))
}
