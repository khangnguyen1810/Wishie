# Task 1: Extend WishlistItem with price field

- [ ] 1.1: In `Wishie/Models/WishlistItem.swift` UPDATE:
  - Add `var price: String?` property to `WishlistItem` struct, positioned after `itemLink`.
  - Add `price: String? = nil` parameter to the memberwise `init(id:name:description:image:pickedUserId:isPicked:isMostDesired:localImage:itemLink:)`, positioned after `itemLink`.
  - Assign `self.price = price` in the init body.
  - In the `init(dictionary:)` extension initializer, add `self.price = dictionary["price"] as? String` (optional, no guard required since it is optional).

---

