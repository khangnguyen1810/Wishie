# Task 4: Redesign Bottom Sheet (`bottomSheet`, `bottomSheetOption`)

- [ ] 4.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE `bottomSheet(type:)`:
  - Change `Color.lightYellow1.ignoresSafeArea()` background to a `LinearGradient(colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")], startPoint: .top, endPoint: .bottom).ignoresSafeArea()`.
  - Add a `Text("What would you like to do?")` header label above the options `VStack`, using `.wishies(.bold, 16)` and `.darkGrey`, padded `.padding(.top, 8)`.

- [ ] 4.2: In `Wishie/Screens/Home/HomeView.swift` UPDATE `bottomSheetOption(image:title:)`:
  - Replace `RoundedRectangle.fill(.lightYellow)` background with a `RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.6)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F1D790"), lineWidth: 1))`.
  - Change icon container from a plain `Image` to a `ZStack`: `RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(hex: "#F1D790"), Color(hex: "#FEF3D7")], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 40, height: 40)` with `Image(image).resizable().aspectRatio(contentMode: .fit).frame(width: 24).padding(.leading, 8)` overlaid.
  - Update title font to `.wishies(.bold, 17)` and color to `.black`.
