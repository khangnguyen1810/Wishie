# Task 4: Interests Feature — View

- [ ] 4.1: In `Wishie/Screens/Interests/InterestsSelectionView.swift` CREATE:
  - `struct InterestsSelectionView: View`
  - `@EnvironmentObject var rootNavigationCoordinator: RootNavigationCoordinator`
  - `@EnvironmentObject var authViewModel: AuthViewModel`
  - `@StateObject private var viewModel: InterestsViewModel` — initialized via `init()` as `_viewModel = StateObject(wrappedValue: InterestsViewModel())`.
  - In `body`, use `BaseWishieScreen` with a `TopAppBar` center slot displaying `Text("Your Interests").font(.wishies(.bold, 20))`.
  - Inside a `ScrollView(.vertical)`, render a `VStack(alignment: .leading, spacing: 24)` with one section per `HobbyCategory` from `viewModel.categories`:
    - Section header: `Text(category.title).font(.wishies(.bold, 16))`.
    - Chip grid: `LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10)` iterating over `category.items` and rendering each as `HobbyChipView` (from task 4.2), passing `isSelected: viewModel.isSelected(item)` and `onTap: { viewModel.toggle(item: item) }`.
  - Below the `ScrollView`, render `WishieButton(title: "Save & Continue", enabled: !viewModel.isLoading)` whose action is `Task { await viewModel.saveInterests() }`.
  - When `viewModel.errorMessage` is non-empty, display it below the button as `Text(viewModel.errorMessage).font(.wishies(.regular, 14)).foregroundStyle(.red)`.
  - Use `.onChange(of: viewModel.isSaveSuccess)` — when `true`, call `rootNavigationCoordinator.completeInterestsSetup()`.
  - On first appearance via `.onAppear`, call `viewModel.populate(existingInterests: authViewModel.userInfo.interests)` to pre-fill selections from the already-loaded `UserModel`.

- [ ] 4.2: In `Wishie/CustomView/HobbyChipView.swift` CREATE:
  - `struct HobbyChipView: View`
  - `let item: HobbyItem`
  - `let isSelected: Bool`
  - `let onTap: () -> Void`
  - `body` renders a `Button(action: onTap)` containing `Text("\(item.emoji) \(item.name)").font(.wishies(.regular, 14)).padding(.horizontal, 14).padding(.vertical, 8)` inside a `Capsule`:
    - Unselected: `.fill(Color.white).strokeBorder(Color.lightYellow, lineWidth: 1.5)`, text `foregroundStyle(.black)`.
    - Selected: `.fill(Color.lightYellow)`, text `foregroundStyle(.black)`, `scaleEffect(isSelected ? 1.05 : 1.0)`.
  - Apply `.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)` on the outermost view for chip toggle animation.

- [ ] 4.3: In `Wishie/Screens/Interests/InterestsViewModel.swift` UPDATE (add missing method from task 3.1):
  - Add `func populate(existingInterests: [String])`: sets `selectedInterestIds = Set(existingInterests)` — used by `InterestsSelectionView.onAppear` to pre-fill saved interests from `AuthViewModel.userInfo.interests`.
