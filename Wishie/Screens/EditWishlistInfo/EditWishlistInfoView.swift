
//
//  EditWishlistInfoScreen.swift
//  Wishie
//

import SwiftUI


struct EditWishlistInfoView: View {
    let wishlistId: String
    let user: UserModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditWishlistInfoViewModel()
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case name
        case description
    }
    
    var body: some View {
        BaseWishieScreen ( topBar: {
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
            .padding(10)
        }, content: {
            ScrollView {
                editViewContent
            }
            .padding(.horizontal, 5)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HomeItemViewCell(item: (viewModel.previewWishlist, user), horizontalPadding: 0)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .padding(10)
            }
            .safeAreaInset(edge: .bottom) {
                WishieButton(
                    title: "Save changes",
                    enabled: !viewModel.name.isEmpty
                ) {
                    Task { await viewModel.save(wishlistId: wishlistId) }
                }
                .padding(.bottom, 20)
                .padding(.horizontal, 15)
            }
            
        }, contentPadding: 0)
        .showFullScreenDialog($viewModel.isLoading)
        .showDialogIfNeeded($viewModel.isShowError, title: viewModel.errorTitle, message: viewModel.errorMsg)
        .task {
            await viewModel.load(wishlistId: wishlistId)
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                dismiss()
            }
        }
    }
    @ViewBuilder
    var editViewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            WishieTextField(
                "Wishlist name",
                "Andie's Birthday",
                text: $viewModel.name,
                kind: .firstName,
                error: nil
            )
            .focused($focusedField, equals: .name)
            
            WishieTextView(
                "Description",
                "This is a wishlist...",
                text: $viewModel.description,
                maxLength: 200,
                focus: $focusedField,
                equals: .description
            )
            
            WishieBirthdayField(date: $viewModel.dueDate)
            
            Text("Choose your theme color")
                .font(.wishies(.bold, 15))
                .foregroundStyle(Color("obInk"))
            
            ThemeColorPicker(selectedTheme: $viewModel.selectedTheme)
        }
        .padding(.top, 20)
        .padding(.horizontal,5)
    }
}
