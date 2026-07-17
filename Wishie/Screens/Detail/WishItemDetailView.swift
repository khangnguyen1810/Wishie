import SwiftUI
import SDWebImageSwiftUI

private enum DetailField: Hashable {
    case name, description, price, link
}

private struct FocusableFieldBackground: ViewModifier {
    let fillColor: Color
    let borderColor: Color
    let isFocused: Bool
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
                    .opacity(isFocused ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

private extension View {
    func focusableFieldBackground(fillColor: Color, borderColor: Color, isFocused: Bool) -> some View {
        modifier(FocusableFieldBackground(fillColor: fillColor, borderColor: borderColor, isFocused: isFocused))
    }
}

struct WishItemDetailView: View {
    @ObservedObject var viewModel: WishlistDetailViewController
    let wishlistId: String
    @Environment(\.dismiss) private var dismiss
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: DetailField?
    let isEdit: Bool
    var wishItem: WishlistItem? {
        didSet {
            viewModel.newItemName = wishItem?.name ?? ""
            viewModel.newItemRemoteImageUrl = wishItem?.image ?? ""
            viewModel.newItemImage = wishItem?.localImage ?? nil
            viewModel.newItemPrice = wishItem?.price ?? ""
            viewModel.newItemDescription = wishItem?.description ?? ""
            viewModel.newItemLink = wishItem?.itemLink ?? ""
        }
    }
    var body: some View {
        let primaryColor =  Color(hex: viewModel.wishlistInfo.theme.primary)
        let secondaryColor =  Color(hex: viewModel.wishlistInfo.theme.secondary)
        ZStack {
            primaryColor.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                
                Text(isEdit ? "Edit item" : "Add a gift idea")
                    .font(.wishies(.bold, 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                if isEdit && viewModel.itemSelected.localImage == nil {
                    WishieWebImage(url: viewModel.newItemRemoteImageUrl ?? "", contentMode: .fit)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: secondaryColor.opacity(0.65), radius: 30, x: 0, y: 10)
                        .padding(.bottom, 20)
                } else {
                    ImagePickerBox(height: 160, selectedImage: $viewModel.newItemImage) {
                        ZStack {
                            if let image = viewModel.newItemImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                VStack(spacing: 8) {
                                    Image("upload")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                    Text("Add photo")
                                        .font(.wishies(.regular, 14))
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(Color.wishiePink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: secondaryColor.opacity(0.65), radius: 30, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                TextField("Item name", text: $viewModel.newItemName)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .name)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .name)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                TextField("About this item...", text: $viewModel.newItemDescription, axis: .vertical)
                    .font(.wishies(.italic, 14))
                    .lineLimit(2...4)
                    .frame(height: 74, alignment: .topLeading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .description)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .description)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                TextField("Item's price", text: $viewModel.newItemPrice)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .price)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .price)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                TextField("Paste product link", text: $viewModel.newItemLink)
                    .font(.wishies(.regular, 15))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .link)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .link)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                Spacer()
                
                WishieButton(
                    title: isEdit ? "Save" : "Add to wishlist",
                    enabled: !viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty,
                    filColor: secondaryColor
                ) {
                    Task {
                        if isEdit {
                            await viewModel
                                .editWishlistItem(
                                    wishListId: wishlistId
                                )
                        } else {
                            await viewModel.addNewWishlistItem(wishlistId: wishlistId)
                        }
                        dismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}
