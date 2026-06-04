import SwiftUI

struct HomeTutorialOverlayView: View {
    let onDismiss: () -> Void
    @State private var isVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("How Wishie works 🎁")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(Color.black)

                hintRow(icon: "plus.circle.fill", text: "Tap + to create a new wishlist or join a friend's")
                hintRow(icon: "list.bullet.rectangle.portrait", text: "Switch between My list and Friend's list tabs")
                hintRow(icon: "arrow.left", text: "Swipe left on a wishlist to delete or leave it")

                Text("Tap anywhere to get started")
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(Color.darkGrey)
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "#F9C46B").opacity(0.6), lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, 32)
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear { isVisible = true }
        .onTapGesture {
            guard isVisible else { return }
            isVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        }
    }

    @ViewBuilder
    private func hintRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "#F9C46B"))

            Text(text)
                .font(.wishies(.regular, 14))
                .foregroundStyle(Color.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
