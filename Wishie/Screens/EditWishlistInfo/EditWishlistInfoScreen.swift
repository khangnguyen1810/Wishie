//
//  EditWishlistInfoScreen.swift
//  Wishie
//

import SwiftUI

struct EditWishlistInfoScreen: View {
    let wishlistId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditWishlistInfoViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case description
    }

    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image("back_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17)
                    }
                    .onTapGesture {
                        dismiss()
                    }
                    .padding(.trailing, 10)
            } center: {
                Text("Change info")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Wishlist name", text: $viewModel.name)
                        .font(.wishies(.regular, 17))
                        .padding(.horizontal, 15)
                        .textInputAutocapitalization(.never)
                        .background {
                            RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                                .frame(height: 56)
                        }
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .focused($focusedField, equals: .name)

                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("Description...", text: $viewModel.description, axis: .vertical)
                            .font(.wishies(.regular, 17))
                            .padding(10)
                            .frame(maxHeight: 100, alignment: .topLeading)
                            .lineLimit(2...4)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.lightYellow)
                            )
                            .onChange(of: viewModel.description) { _, newValue in
                                if newValue.count > 200 {
                                    viewModel.description = String(newValue.prefix(200))
                                }
                            }
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }
                            .focused($focusedField, equals: .description)
                        Text("\(viewModel.description.count)/200")
                            .font(.caption)
                            .foregroundColor(viewModel.description.count == 200 ? .red : .gray)
                    }

                    DateInputView(isCreating: .constant(true), date: $viewModel.dueDate)

                    Text("Choose your theme color")
                        .font(.wishies(.regular, 17))
                        .padding(.top)

                    ThemeColorPicker(selectedTheme: $viewModel.selectedTheme)
                }
                .padding(.top, 20)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }

            WishieButton(
                title: "Save changes",
                enabled: !viewModel.name.isEmpty
            ) {
                Task { await viewModel.save(wishlistId: wishlistId) }
            }
            .padding(.bottom, 20)
        }
        .showFullScreenDialog($viewModel.isLoading)
        .task {
            await viewModel.load(wishlistId: wishlistId)
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                dismiss()
            }
        }
    }
}

#Preview {
    EditWishlistInfoScreen(
        wishlistId: "136D375B-7015-4C9A-97BE-830C5C46F24A"
    )
}
