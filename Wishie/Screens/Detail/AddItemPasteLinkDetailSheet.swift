import SwiftUI
import DotLottie

struct AddItemPasteLinkDetailSheet: View {
    @ObservedObject var viewModel: WishlistDetailViewController
    let wishlistId: String

    @Environment(\.dismiss) private var dismiss
    @State private var urlInput: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 16)

            Text("Paste a product link")
                .font(.wishies(.bold, 20))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            HStack(spacing: 10) {
                TextField("https://...", text: $urlInput)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.wishies(.regular, 15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.lightYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    Task {
                        await viewModel.fetchProductMetadataForNewItem(from: urlInput.trimmingCharacters(in: .whitespaces))
                    }
                } label: {
                    Text("Fetch")
                        .font(.wishies(.bold, 15))
                        .foregroundStyle(Color.wishiePink)
                }
                .disabled(urlInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isFetchingMetadata)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if viewModel.isFetchingMetadata {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.lightYellow)
                    .frame(
                        width: UIScreen.main.bounds.width/4,
                        height:  UIScreen.main.bounds.width/4
                    )
                    .overlay {
                        DotLottieAnimation(fileName: "giftloading", config: AnimationConfig(autoplay: true, loop: true)).view()
                            .frame(width: 80)
                    }
                    .padding(.vertical, 16)
            }

            if let error = viewModel.metadataFetchError {
                Text(error)
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            if !viewModel.newItemName.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if let imageUrl = viewModel.newItemRemoteImageUrl {
                        WishieWebImage(url: imageUrl)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Text(viewModel.newItemName)
                        .font(.wishies(.bold, 15))

                    if !viewModel.newItemDescription.isEmpty {
                        Text(viewModel.newItemDescription)
                            .font(.wishies(.regular, 13))
                            .lineLimit(2)
                            .foregroundStyle(Color.gray)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            Spacer()

            WishieButton(title: "Add to wishlist", enabled: !viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty && viewModel.metadataFetchError == nil) {
                Task {
                    await viewModel.addNewWishlistItem(wishlistId: wishlistId)
                    if !viewModel.showDuplicateItemDialog {
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(
            DialogView(
                isShowDialog: $viewModel.showDuplicateItemDialog,
                errorTitle: "Item Already Exists",
                errorMessage: "This gift is already in your wishlist.",
                showCancel: false,
                onConfirm: {
                    DispatchQueue.main.async {
                        urlInput = ""
                        viewModel.newItemName = ""
                    }
                }
            )
        )
    }
}
