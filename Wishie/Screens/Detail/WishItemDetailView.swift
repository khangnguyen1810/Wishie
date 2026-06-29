import SwiftUI
import SDWebImageSwiftUI

struct WishItemDetailView: View {
    @ObservedObject var viewModel: WishlistDetailViewController
    let wishlistId: String
    @Environment(\.dismiss) private var dismiss
    @State private var keyboardHeight: CGFloat = 0
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
                WishieWebImage(url: viewModel.newItemRemoteImageUrl ?? "")
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            TextField("Item name", text: $viewModel.newItemName)
                .font(.wishies(.bold, 17))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.lightYellow)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            TextField("About this item...", text: $viewModel.newItemDescription, axis: .vertical)
                .font(.wishies(.italic, 14))
                .lineLimit(2...4)
                .frame(height: 74, alignment: .topLeading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.lightYellow)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            TextField("Paste product link", text: $viewModel.newItemLink)
                .font(.wishies(.regular, 15))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.lightYellow)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            Spacer()
            
            WishieButton(
                title: isEdit ? "Save" : "Add to wishlist",
                enabled: !viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty
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
}
