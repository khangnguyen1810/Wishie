import SwiftUI

struct HobbyChipView: View {
    let item: HobbyItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(item.emoji) \(item.name)")
                .font(.wishies(.regular, 14))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.lightYellow : Color.white)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.lightYellow, lineWidth: isSelected ? 0 : 1.5)
                        )
                )
                .foregroundStyle(.black)
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
