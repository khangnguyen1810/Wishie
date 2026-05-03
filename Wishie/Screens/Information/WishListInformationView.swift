//
//  CreateWishlistPage1.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//


import SwiftUI

struct CreateWishlistPage1: View {
    @EnvironmentObject var createWishlistViewModel: CreateWishlistViewModel
    @FocusState var isInputActive: Bool
    var body: some View {
        TextField("Wishlist name", text: $createWishlistViewModel.name)
            .font(.wishies(.regular, 17))
            .padding(.horizontal,15)
            .textInputAutocapitalization(.never)
            .background {
                RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                    .frame(height: 56)
            }
            .padding(.bottom,30)
        VStack(alignment: .trailing, spacing: 4) {
            TextField("Description...",text: $createWishlistViewModel.description, axis: .vertical)
                .font(.wishies(.regular, 17))
                .padding(.horizontal, 10)
                .frame(maxHeight: 100)
                .lineLimit(2...4)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.lightYellow)
                )
                .onChange(of: createWishlistViewModel.description) { _, newValue in
                    if newValue.count > 200 {
                        createWishlistViewModel.description = String(newValue.prefix(200))
                    }
                }
                .focused($isInputActive)
            Text("\(createWishlistViewModel.description.count)/200")
                .font(.caption)
                .foregroundColor(createWishlistViewModel.description.count == 200 ? .red : .gray)
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                VStack {
                    Spacer()
                    Button("Done") {
                        isInputActive = false
                    }
                }
            }
        }
        .padding(.bottom,20)
        DateInputView(date: $createWishlistViewModel.dueDate)
    }
}
