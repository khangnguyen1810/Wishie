# Task 5: Update `ProfileView` — Avatar Display, Edit Navigation, and Post-Save Re-fetch

- [ ] 5.1: In `Wishie/Screens/Profile/ProfileView.swift` UPDATE:
  - Add `@State private var path = NavigationPath()` state property.
  - Wrap the entire existing `BaseWishieScreen { ... }` body inside `NavigationStack(path: $path) { ... }`.
  - In `TopAppBar`, add a `trailing:` slot with a `Circle().fill(.lightYellow).frame(width: 50, height: 50).overlay { Image("edit_icon").resizable().scaledToFit().frame(width: 20) }.onTapGesture { path.append(Route.editProfile) }`.
  - Replace the existing static placeholder avatar block (`Circle().fill(.lightYellow)...overlay { Image("user")... }`) with a conditional display: if `viewModel.userInfo.avatarUrl` is non-nil and non-empty, show `AsyncImage(url: URL(string: viewModel.userInfo.avatarUrl!))` — on `.success(let image)`: `image.resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())`; on `.failure` or `.empty`: the original `Circle().fill(.lightYellow).frame(width: 100, height: 100).overlay { Image("user").resizable().scaledToFit().frame(width: 50) }` placeholder. Preserve `.padding(.top, 20)`.
  - Add `.navigationDestination(for: Route.self) { route in switch route { case .editProfile: EditProfileView(userModel: viewModel.userInfo).onDisappear { Task { await viewModel.fetchUserInfo() } } default: EmptyView() } }` inside the `NavigationStack` body (after the `BaseWishieScreen` closing brace).
