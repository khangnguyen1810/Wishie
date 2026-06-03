# EC 3: No Image Selected — Placeholder State

- [x] **Scenario: Card with no image selected shows centered upload placeholder** ✅ RESOLVED
  - Given: WishlistItemCard 'item-ec3-noimage' has no image selected (image binding is nil)
  - When: The card renders
  - Then: The image area displays the `Image("upload")` icon and an "Add photo" label centered within the fixed frame (`minHeight: 180`), and no crash or blank space occurs
  - Verify: Confirm the placeholder is vertically and horizontally centered within the frame; confirm tapping the area opens the image picker
  - **Resolution**:
    1. **Wrong icon** → Replaced `Image(systemName: "photo.badge.plus")` with `Image("upload")` asset; removed `.foregroundStyle(.wishiePink)` modifier
    2. **Wrong label text** → Changed `Text("Tap to add gift photo")` to `Text("Add photo")` with `.font(.wishies(.regular, 12)).foregroundStyle(.black)`
    3. **Wrong placeholder background** → Removed `LinearGradient` ZStack layer; added `.background(.wishiePink)` modifier on the ZStack
    4. **Frame sizing mismatch** → Removed `private let imageHeight: CGFloat = 196`; changed ZStack frame to `.frame(maxWidth: .infinity, minHeight: 180)`
  - **Affected Files**:
    - [Wishie/Screens/CreateList/CreateWishlistPage2.swift](Wishie/Screens/CreateList/CreateWishlistPage2.swift#L74-L97) — `else` branch of `WishlistItemCard` image section

