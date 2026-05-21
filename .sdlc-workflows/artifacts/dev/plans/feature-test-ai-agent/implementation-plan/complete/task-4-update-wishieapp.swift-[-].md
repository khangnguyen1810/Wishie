# Task 4: Update WishieApp.swift [ ]

Inject `RootNavigationCoordinator` as `@StateObject` and pass it to views via `@EnvironmentObject`. Maintain existing LaunchScreen logic.

- 4.1: In [Wishie/WishieApp.swift](Wishie/WishieApp.swift) **UPDATE**:
  - Add import statement `import Combine` if not already present
  - Add new property `@StateObject private var rootNavigationCoordinator: RootNavigationCoordinator` (declared after `@StateObject private var authViewModel`)
  - Modify the `body` computed property:
    - Before initializing `RootNavigationCoordinator`, replace the initializer in `body` to pass `authViewModel` to the coordinator: `@StateObject private var rootNavigationCoordinator: RootNavigationCoordinator = RootNavigationCoordinator(authViewModel: /* needs to be resolved */)`
    - This requires restructuring: Create `rootNavigationCoordinator` after `authViewModel` initialization, passing `authViewModel` to its init
  - Update the `environmentObject` chain in the ZStack/body to add: `.environmentObject(rootNavigationCoordinator)` after `.environmentObject(authViewModel)`
  - Keep all existing code: LaunchScreen rendering with `isActive` flag, Firebase initialization, onAppear animation timing
  - Ensure animations for `authViewModel.isLoggedIn` and `hasCompletedOnboarding` are preserved (these now trigger through coordinator's observed state)

- 4.2: In [Wishie/WishieApp.swift](Wishie/WishieApp.swift) **UPDATE** (alternative if direct init is problematic):
  - If `@StateObject` initialization cannot directly pass `authViewModel`, use a workaround:
    - Initialize `rootNavigationCoordinator` with a placeholder in property declaration
    - In `body.onAppear` or immediately, create new instance and assign with proper authViewModel reference
    - Or use `@StateObject` initialization closure: `@StateObject private var rootNavigationCoordinator = { let authVM = AuthViewModel(); return RootNavigationCoordinator(authViewModel: authVM) }()` (but this creates duplicate AuthViewModel, so prefer explicit handling)
  - Ensure solution maintains single AuthViewModel instance

---

