import SwiftUI

struct PasteLinkSheet: View {
    @EnvironmentObject var createWishlistViewModel: CreateWishlistViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var urlInput: String = ""
    @State private var fetchedMetadata: ProductMetadata? = nil
    @State private var keyboardHeight: CGFloat = 0

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

                Button(action: performFetch) {
                    Text("Fetch")
                        .font(.wishies(.bold, 15))
                        .foregroundStyle(Color.wishiePink)
                }
                .disabled(urlInput.trimmingCharacters(in: .whitespaces).isEmpty || createWishlistViewModel.isFetchingMetadata)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if createWishlistViewModel.isFetchingMetadata {
                ProgressView("Fetching product info...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            if let error = createWishlistViewModel.metadataFetchError {
                Text(error)
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            if let metadata = fetchedMetadata {
                VStack(alignment: .leading, spacing: 8) {
                    if let imageUrl = metadata.imageUrl {
                        WishieWebImage(url: imageUrl)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Text(metadata.title)
                        .font(.wishies(.bold, 15))

                    if !metadata.productDescription.isEmpty {
                        Text(metadata.productDescription)
                            .font(.wishies(.regular, 13))
                            .lineLimit(2)
                            .foregroundStyle(Color.gray)
                    }

                    if let price = metadata.price {
                        Text(price)
                            .font(.wishies(.bold, 14))
                            .foregroundStyle(Color.wishiePink)
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

            WishieButton(title: "Add to wishlist", enabled: fetchedMetadata != nil) {
                confirmAdd()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .padding(.bottom, keyboardHeight)
        .keyboardHeight($keyboardHeight)
        .presentationDetents([.large])
    }

    private func performFetch() {
        let urlString = urlInput.trimmingCharacters(in: .whitespaces)
        guard !urlString.isEmpty else { return }
        fetchedMetadata = nil
        Task {
            let result = await createWishlistViewModel.fetchProductMetadata(from: urlString)
            if case .success(let metadata) = result {
                fetchedMetadata = metadata
            }
        }
    }

    private func confirmAdd() {
        guard let metadata = fetchedMetadata else { return }
        createWishlistViewModel.addItemFromMetadata(metadata)
        dismiss()
    }
}
