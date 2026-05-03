// 1. Tạo PreferenceKey để truyền height
struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 2. Hàm helper để đo height của Text
func measureTextHeight(
    text: String,
    font: Font,
    width: CGFloat,           // chiều rộng tối đa mà Text sẽ chiếm
    lineSpacing: CGFloat = 0  // nếu bạn có .lineSpacing()
) -> some View {
    
    Text(text)
        .font(font)
        .foregroundStyle(.black)
        .frame(maxWidth: width, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)  // quan trọng: cho phép text xuống dòng thật
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: TextHeightKey.self, value: geometry.size.height)
            }
        )
}

// 3. Sử dụng trong View của bạn
struct WishlistView: View {
    @State private var wishlistTitle: String? = "Wishlist's name rất dài có thể xuống nhiều dòng để test line height"
    @State private var measuredHeight: CGFloat = 0
    
    var body: some View {
        VStack {
            // Text thật (bạn muốn hiển thị)
            Text(wishlistTitle ?? "Wishlist's name")
                .font(.wishies(.bold, 25))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(   // đo height mà không ảnh hưởng layout
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: TextHeightKey.self, value: geo.size.height)
                    }
                )
                .onPreferenceChange(TextHeightKey.self) { height in
                    measuredHeight = height
                }
            
            Text("Chiều cao đo được: \(measuredHeight, specifier: "%.2f") pt")
                .font(.caption)
        }
        .padding()
    }
}