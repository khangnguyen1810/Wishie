# Task 3: Refactor ProfileView and EditProfileView to eliminate ProfileViewModel and network fetches

- [ ] 3.1: In `Wishie/Screens/Profile/ProfileView.swift` UPDATE:
  - Remove `@StateObject private var viewModel: ProfileViewModel = ProfileViewModel()`.
  - Add `@StateObject private var editViewModel: EditProfileViewModel = EditProfileViewModel()`.
  - Replace all references to `viewModel.userInfo` with `authViewModel.userInfo`.
  - Replace `viewModel.errorMessage` with `authViewModel.userInfoError`.
  - Remove `.showFullScreenDialog($viewModel.isLoading)` from the view body.
  - Remove `.task { await viewModel.fetchUserInfo() }` from the view body.
  - In `navigationDestination(for: Route.self)` for the `.editProfile` case, change `EditProfileView(userModel: viewModel.userInfo)` to `EditProfileView(userModel: authViewModel.userInfo, viewModel: editViewModel)` and remove the `.onDisappear { Task { await viewModel.fetchUserInfo() } }` block entirely.
  - Add `.onChange(of: editViewModel.updatedUser) { _, updated in if let updated { authViewModel.userInfo = updated } }` on the `NavigationStack`.

- [ ] 3.2: In `Wishie/Screens/Profile/EditProfileView.swift` UPDATE:
  - Change `@StateObject private var viewModel = EditProfileViewModel()` to `@ObservedObject var viewModel: EditProfileViewModel`.
  - Update the struct initializer to accept `userModel: UserModel` and `viewModel: EditProfileViewModel` as parameters, matching the updated call site in Task 3.1.
  - During `onAppear`, before calling `viewModel.populate(from: userModel)`, show a brief loading indicator if the `userModel` contains empty/default values (e.g., `firstName.isEmpty`). This provides visual feedback while the async initialization settles. Once `populate()` completes, the form will display populated values.

