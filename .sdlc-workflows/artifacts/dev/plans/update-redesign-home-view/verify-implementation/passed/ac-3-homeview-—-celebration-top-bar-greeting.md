# AC 3: HomeView — Celebration Top Bar Greeting

- [x] **Scenario: Top bar renders personalised celebration greeting with user's first name**
  - Given: an authenticated user `"user-ac3-greeting"` with `firstName = "Alex"` is loaded into `AuthViewModel`
  - When: `HomeView` renders and `topAppBar()` is built
  - Then: the greeting reads `"Hey, Alex! 🎁"` in bold 22pt `.black`, with a subtitle `"What are you wishing for?"` in regular 13pt `.darkGrey` below it
  - Verify: old greeting `"Are you gud?"` is absent; greeting uses `.wishies(.bold, 22)`; subtitle uses `.wishies(.regular, 13)` with `.darkGrey` foreground; both are inside a `VStack(alignment: .leading, spacing: 2)`

- [x] **Scenario: Top bar action buttons render with gold gradient circle backgrounds**
  - Given: `HomeView` is rendered for an authenticated user `"user-ac3-buttons"`
  - When: the top bar is displayed
  - Then: both the add button and the profile button show a `LinearGradient` circle (42×42) transitioning from `Color(hex: "#F1D790")` (top-leading) to `Color(hex: "#FEF3D7")` (bottom-trailing), overlaying `Image("add")` and `Image("user")` respectively at 20×20
  - Verify: plain `Circle().fill(.lightYellow)` backgrounds are absent; both icons are 20×20; gradient direction is top-leading to bottom-trailing

