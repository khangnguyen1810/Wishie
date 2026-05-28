# AC 2: Upload Placeholder Display

- [x] **Scenario: WishlistItemCard shows centered upload placeholder when no image is selected** ❌ FAILED → ✅ RESOLVED
  - Given: A `WishlistItem` named "item-ac2-placeholder" has no image selected and is rendered inside `WishlistItemCard`
  - When: The card appears on screen
  - Then: The image area displays a centered `Image("upload")` icon and an "Add photo" label; no real image content is shown
  - Verify: Confirm the placeholder container occupies the same fixed frame (`maxWidth: .infinity`, `minHeight: 180`) as the image state; confirm both the upload icon and "Add photo" label are vertically and horizontally centered within that area
  - **Failure**: Implementation diverges from the scenario spec on every placeholder detail
  - **Root Cause**: Task 1.1 placeholder requirements were not implemented as specified. The developer used a different SF symbol, different label text, a gradient background instead of a solid `.wishiePink` fill, a fixed height of `196` instead of `minHeight: 180`, and different VStack spacing (`8` vs `6`). Additionally, the `Image("upload")` asset does not exist anywhere in `Assets.xcassets`, so the spec itself cannot be satisfied without adding that asset.
  - **Affected Files**: [Wishie/Screens/CreateList/CreateWishlistPage2.swift](../../../../../Wishie/Screens/CreateList/CreateWishlistPage2.swift) — `WishlistItemCard` `else` branch (lines ~91–108)
  - **Code Snippet** (actual):
    ```swift
    } else {
        LinearGradient(
            colors: [Color.lightYellow, Color.lightYellow1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(.wishiePink)
            Text("Tap to add gift photo")
                .font(.wishies(.bold, 13))
                .foregroundStyle(.black.opacity(0.75))
        }
    }
    // container: .frame(maxWidth: .infinity).frame(height: 196)
    ```
  - **Expected Behavior**:
    - Background: `.background(.wishiePink)` (solid)
    - Icon: `Image("upload").resizable().scaledToFit().frame(width: 28, height: 28)`
    - Label: `Text("Add photo").font(.wishies(.regular, 12)).foregroundStyle(.black)`
    - VStack spacing: `6`
    - Container frame: `.frame(maxWidth: .infinity, minHeight: 180)`
  - **Actual Behavior**:
    - Background: `LinearGradient(colors: [.lightYellow, .lightYellow1], ...)`
    - Icon: `Image(systemName: "photo.badge.plus")` at `26×26` with `.wishiePink` tint
    - Label: `"Tap to add gift photo"` in `.bold` weight at `13pt`
    - VStack spacing: `8`
    - Container frame: `.frame(maxWidth: .infinity).frame(height: 196)` (fixed height, not `minHeight: 180`)
    - The `"upload"` image asset does not exist in `Assets.xcassets`

