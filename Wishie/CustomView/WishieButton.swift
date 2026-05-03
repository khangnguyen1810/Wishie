import SwiftUI

struct WishieButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.lightYellow)
                    .frame(
                        width: UIScreen.main.bounds.width * 0.9,
                        height: 60
                    )

                Text(title)
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        }
    }
}