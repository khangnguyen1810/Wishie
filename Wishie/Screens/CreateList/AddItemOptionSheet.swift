import SwiftUI

struct AddItemOptionSheet: View {
    let onPasteLink: () -> Void
    let onManual: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(.gray.opacity(0.3))
                .frame(width: 40, height: 4)

            Text("Add a gift idea")
                .font(.wishies(.bold, 20))

            optionCard(
                icon: "link",
                iconTint: .wishiePink,
                title: "Paste a product link",
                subtitle: "Auto-fill name, image & price from any site",
                borderColor: .wishiePink.opacity(0.15),
                action: onPasteLink
            )

            optionCard(
                icon: "pencil",
                iconTint: .black,
                title: "Fill in manually",
                subtitle: "Add item details yourself",
                borderColor: .black.opacity(0.08),
                action: onManual
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private func optionCard(
        icon: String,
        iconTint: Color,
        title: String,
        subtitle: String,
        borderColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(iconTint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.wishies(.bold, 16))
                    .foregroundStyle(.black)

                Text(subtitle)
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 1.5)
                )
        )
        .onTapGesture {
            action()
        }
    }
}
