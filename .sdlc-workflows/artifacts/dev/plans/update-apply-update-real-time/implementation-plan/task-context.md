# Share Context

## Important Instructions for Implementation

- All Firestore listener closures MUST use `[weak self]` to prevent retain cycles
- All `@MainActor`-isolated property updates from listener callbacks MUST be wrapped in `Task { @MainActor [weak self] in }`
- `ListenerRegistration` (from `FirebaseFirestore`) MUST be stored as a private property and removed in `deinit`
- Do NOT add loading state (`isGettingList`, `isShowLoading`) for subsequent real-time listener callbacks in `HomeViewModel` — only on initial load
- Do NOT remove the `.refreshable` pull-to-refresh block in `HomeView`; it remains as an explicit user-initiated refresh path
- Do NOT remove `setInitialWishlist` from `WishlistDetailViewController`; it is still used by `WishlistDetailScreen.onAppear` for immediate content display when navigating from `HomeView`
- `WishlistDetailViewController` and `HomeViewModel` must add `import FirebaseFirestore` since `ListenerRegistration` is a FirebaseFirestore type

## Reused Existing Functions/Utilities

- `WishlistModel(dictionary:)`: Failable initializer for parsing Firestore document data into `WishlistModel`; located in `Wishie/Models/WishlistModel.swift`
- `getWishlist(by:)`: Fetches a `WishlistModel` and its owner `UserModel` from Firestore; located in `Wishie/Services/WishlistService.swift` — reused by `getUserWishlists()` which is reused by `refreshWishlists()`
- `getUserWishlists()`: Fetches all user wishlist tuples `[(WishlistModel, UserModel)]`; located in `Wishie/Services/WishlistService.swift` — reused inside `refreshWishlists()`
- `fetchMemberUsers()`: Fetches `UserModel` for each member ID from `wishlistInfo.members`; located in `Wishie/Screens/Detail/WishlistDetailViewController.swift` — called inside listener callback
- `setInitialWishlist(_:)`: Sets `wishlistInfo` from a pre-loaded `WishlistModel` and triggers `fetchMemberUsers()`; located in `Wishie/Screens/Detail/WishlistDetailViewController.swift` — still invoked by `WishlistDetailScreen.onAppear`
- `WishieConstants.userIdKey`: Key for retrieving userId from `UserDefaults`; `"userid"`; located in `Wishie/Constants/WishieConstants.swift`
- `WishieConstants.firebaseUserPath`: Firestore collection path `"users"`; located in `Wishie/Constants/WishieConstants.swift`
- `WishieConstants.firebaseWishlistPath`: Firestore sub-collection path `"wishlists"`; located in `Wishie/Constants/WishieConstants.swift`

## Shared Contracts

### Interfaces

- `WishlistServiceProtocol`: Extended with two new methods — `observeWishlist(by:onChange:) -> ListenerRegistration` and `observeUserWishlistIds(onChange:) -> ListenerRegistration?`; defined in `Wishie/Services/WishlistService.swift`

---

# Task 1: Add Real-time Observer Methods to WishlistService

- [ ] 1.1: In `Wishie/Services/WishlistService.swift` UPDATE:
  - Add `func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void) -> ListenerRegistration` to `WishlistServiceProtocol`
  - Add `func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> ListenerRegistration?` to `WishlistServiceProtocol`
  - Implement `observeWishlist(by:onChange:)` in `WishlistService`: call `db.collection("wishList").document(id).addSnapshotListener`; in the closure guard on `snapshot?.data()`, parse with `WishlistModel(dictionary:)`, call `onChange(wishlist)` on success; return the `ListenerRegistration`
  - Implement `observeUserWishlistIds(onChange:)` in `WishlistService`: guard on `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)` — return `nil` if absent; call `db.collection(WishieConstants.firebaseUserPath).document(userId).collection(WishieConstants.firebaseWishlistPath).order(by: "joinedAt").addSnapshotListener`; in the closure guard on `snapshot?.documents`, call `onChange(docs.map { $0.documentID })`; return the `ListenerRegistration`

# Task 2: Add Real-time Listener Management to WishlistDetailViewController

- [ ] 2.1: In `Wishie/Screens/Detail/WishlistDetailViewController.swift` UPDATE:
  - Add `import FirebaseFirestore` at the top of the file (after existing imports)
  - Add private stored property `private var wishlistListener: ListenerRegistration?`
  - Add `func startObservingWishlist(wishlistId: String, showInitialLoading: Bool = false)`:
    - Set `isShowLoading = showInitialLoading`
    - Call `wishlistListener?.remove()` to clean up any previous listener
    - Call `wishlistService.observeWishlist(by: wishlistId)` and store the result in `wishlistListener`
    - In the `onChange` closure, wrap updates in `Task { @MainActor [weak self] in }`: set `self.wishlistInfo = updatedWishlist`, set `self.isShowLoading = false`, `await self.fetchMemberUsers()`
  - Add `deinit { wishlistListener?.remove() }`

# Task 3: Add Real-time Listener Management to HomeViewModel

- [ ] 3.1: In `Wishie/Screens/Home/HomeViewModel.swift` UPDATE:
  - Add `import FirebaseFirestore` at the top of the file (after existing imports)
  - Add private stored property `private var userWishlistsListener: ListenerRegistration?`
  - Add `private func refreshWishlists() async`:
    - Call `try await service.getUserWishlists()` and handle the `Result`
    - On `.success(let list)`: set `isGettingList = false`; guard on `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)`; set `self.myWishlists = list.filter { $0.0.members[userId] == .owner }`; set `self.myFriendWishlists = list.filter { $0.0.members[userId] == .member }`
    - On `.failure(let error)`: set `isGettingList = false`; set `self.errorMessage = error.localizedDescription`
    - In the `catch` block: set `isGettingList = false`; set `self.errorMessage = error.localizedDescription`
  - Add `func startObservingWishlists()`:
    - Set `isGettingList = myWishlists.isEmpty && myFriendWishlists.isEmpty` (shows loading only on initial load when lists are empty)
    - Call `userWishlistsListener?.remove()` to clean up any previous listener
    - Call `service.observeUserWishlistIds` and store the result in `userWishlistsListener`
    - In the `onChange` closure, wrap in `Task { @MainActor [weak self] in }`: call `await self?.refreshWishlists()`
  - Add `deinit { userWishlistsListener?.remove() }`

# Task 4: Update WishlistDetailScreen to Use Real-time Observer

- [ ] 4.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE:
  - Replace the existing `.task` modifier body:
    - Change `guard let wishlistId else { return }` to `let id = wishlistId ?? wishlist?.id` with `guard let id else { return }`
    - Replace `await viewModel.getWishlistInfo(wishListId: wishlistId)` with `viewModel.startObservingWishlist(wishlistId: id, showInitialLoading: wishlist == nil)`
    - This ensures that when navigating from `HomeView` (where `wishlist` is provided but `wishlistId` is nil), the wishlist ID is derived from `wishlist?.id` and no loading indicator is shown; when navigating via route (where `wishlistId` is provided but `wishlist` is nil), loading is shown until the first snapshot fires

# Task 5: Update HomeView to Use Real-time Observer

- [ ] 5.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE:
  - Replace the contents of the `.task` modifier:
    - Keep `await authViewModel.getUserInfo()` at the start
    - Remove the `if homeViewModel.myWishlists.isEmpty && homeViewModel.myFriendWishlists.isEmpty` conditional block with `await homeViewModel.getListWishlist()`
    - Add `homeViewModel.startObservingWishlists()` — this method internally handles the initial-load-only loading indicator and registers the real-time listener
