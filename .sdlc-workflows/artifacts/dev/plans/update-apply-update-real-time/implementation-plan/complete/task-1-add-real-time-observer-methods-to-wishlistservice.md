# Task 1: Add Real-time Observer Methods to WishlistService

- [ ] 1.1: In `Wishie/Services/WishlistService.swift` UPDATE:
  - Add `func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void) -> ListenerRegistration` to `WishlistServiceProtocol`
  - Add `func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> ListenerRegistration?` to `WishlistServiceProtocol`
  - Implement `observeWishlist(by:onChange:)` in `WishlistService`: call `db.collection("wishList").document(id).addSnapshotListener`; in the closure guard on `snapshot?.data()`, parse with `WishlistModel(dictionary:)`, call `onChange(wishlist)` on success; return the `ListenerRegistration`
  - Implement `observeUserWishlistIds(onChange:)` in `WishlistService`: guard on `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)` — return `nil` if absent; call `db.collection(WishieConstants.firebaseUserPath).document(userId).collection(WishieConstants.firebaseWishlistPath).order(by: "joinedAt").addSnapshotListener`; in the closure guard on `snapshot?.documents`, call `onChange(docs.map { $0.documentID })`; return the `ListenerRegistration`

