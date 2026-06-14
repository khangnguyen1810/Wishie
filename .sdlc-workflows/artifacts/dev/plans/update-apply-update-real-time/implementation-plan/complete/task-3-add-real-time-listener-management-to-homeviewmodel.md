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

