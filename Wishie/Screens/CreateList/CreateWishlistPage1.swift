//
//  CreateWishlistPage1.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import SwiftUI


struct CreateWishlistPage1: View {
    enum CreateWishlistField {
        case name
        case description
    }
    @EnvironmentObject var createWishlistViewModel: CreateWishlistViewModel
    @FocusState private var focusedField: CreateWishlistField?
    var body: some View {
        VStack {
            TextField("Wishlist name", text: $createWishlistViewModel.name)
                .font(.wishies(.regular, 17))
                .padding(.horizontal,15)
                .textInputAutocapitalization(.never)
                .background {
                    RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                        .frame(height: 56)
                }
                .padding(.bottom,30)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }
                .focused($focusedField, equals: .name)
            WishieTextView(
                nil,
                "Description...",
                text: $createWishlistViewModel.description,
                maxLength: 200,
                focus: $focusedField,
                equals: .description
            )
            .padding(.bottom,20)
            DateInputView(isCreating: .constant(true), date: $createWishlistViewModel.dueDate)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}

#Preview {
    CreateWishlistPage1()
        .environmentObject(CreateWishlistViewModel())
}
