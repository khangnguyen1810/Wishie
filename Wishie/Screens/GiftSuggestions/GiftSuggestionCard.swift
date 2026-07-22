import SwiftUI

struct GiftSuggestionCard: View {
    let suggestion: GiftSuggestion
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if suggestion.metadata.hasImage {
                WishieProductImage(
                    localImage: suggestion.metadata.localImage,
                    url: suggestion.metadata.imageUrl
                )
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.metadata.title.isEmpty ? suggestion.idea.name : suggestion.metadata.title)
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(.black)
                    .lineLimit(2)

                let price = suggestion.metadata.price?.isEmpty == false ? suggestion.metadata.price! : suggestion.idea.price
                if !price.isEmpty {
                    Text(price)
                        .font(.wishies(.bold, 13))
                        .foregroundStyle(.wishiePink)
                }

                if !suggestion.idea.description.isEmpty {
                    Text(suggestion.idea.description)
                        .font(.wishies(.regular, 12))
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.wishiePink))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.wishiePink.opacity(0.12), lineWidth: 1.5))
        )
    }
}
