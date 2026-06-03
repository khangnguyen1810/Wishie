# Task 3: Interests Feature — ViewModel

- [ ] 3.1: In `Wishie/Screens/Interests/InterestsViewModel.swift` CREATE:
  - `@MainActor final class InterestsViewModel: ObservableObject`
  - `@Published var selectedInterestIds: Set<String>`
  - `@Published var isLoading: Bool = false`
  - `@Published var isSaveSuccess: Bool = false`
  - `@Published var errorMessage: String = ""`
  - `let categories: [HobbyCategory] = hobbyCategories` (uses `hobbyCategories` constant from task 1.2)
  - `private let authService: AuthenticateServiceProtocol`
  - `init(existingInterests: [String] = [], authService: AuthenticateServiceProtocol = AuthenticateService())` — initializes `selectedInterestIds` as `Set(existingInterests)`.
  - `func toggle(item: HobbyItem)`: if `selectedInterestIds.contains(item.id)`, remove it; otherwise insert it.
  - `func isSelected(_ item: HobbyItem) -> Bool`: returns `selectedInterestIds.contains(item.id)`.
  - `func saveInterests() async`: guard `userId` from `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)` else set `errorMessage = "User session not found."` and return; set `isLoading = true`, `errorMessage = ""`; call `try await authService.updateUserInterests(userId: userId, interests: Array(selectedInterestIds))`; on success set `isLoading = false`, `isSaveSuccess = true`; on catch set `isLoading = false`, `errorMessage = error.localizedDescription`.

---

