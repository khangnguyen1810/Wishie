# Task 2: Redesign `HomeView` Top Bar and Tab Selector

- [ ] 2.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE `topAppBar()`:
  - Change greeting `Text` from `"Are you gud? \(authViewModel.userInfo.firstName)"` to `"Hey, \(authViewModel.userInfo.firstName)! 🎁"` using `.wishies(.bold, 22)` and `.black` foreground.
  - Wrap the greeting `Text` in a `VStack(alignment: .leading, spacing: 2)` with a subtitle `Text("What are you wishing for?")` using `.wishies(.regular, 13)` and `.darkGrey`.
  - Redesign the trailing `add` action button: replace `Circle().fill(.lightYellow)` with a `ZStack` containing a `Circle` filled with a `LinearGradient(colors: [Color(hex: "#F1D790"), Color(hex: "#FEF3D7")], startPoint: .topLeading, endPoint: .bottomTrailing)` at 42×42, overlaying `Image("add")` at 20×20.
  - Redesign the trailing profile button identically: same gradient `Circle` at 42×42 overlaying `Image("user")` at 20×20.

- [ ] 2.2: In `Wishie/Screens/Home/HomeView.swift` UPDATE `typeSegmentItem(title:tab:)`:
  - Replace `RoundedRectangle.fill(.lightYellow.opacity(0.2))` container background with `Capsule().fill(Color(hex: "#FEF3D7").opacity(0.3))` on the outer `HStack` container.
  - Change the selected indicator from `RoundedRectangle(cornerRadius: 20).fill(.lightYellow)` to `Capsule().fill(LinearGradient(colors: [Color(hex: "#F1D790"), Color(hex: "#FEF3D7")], startPoint: .leading, endPoint: .trailing))`.
  - Update unselected text color from `.lightGrey` to `.darkGrey`.
  - Keep the `.matchedGeometryEffect(id: "TAB", in: animation)` and `.animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)` unchanged.

---

