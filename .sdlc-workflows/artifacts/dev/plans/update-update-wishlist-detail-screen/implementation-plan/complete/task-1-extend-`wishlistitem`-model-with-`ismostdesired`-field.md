# Task 1: Extend `WishlistItem` model with `isMostDesired` field

- [ ] 1.1: In `Wishie/Models/WishlistItem.swift` UPDATE:
  - Add `var isMostDesired: Bool` property to the `WishlistItem` struct body, positioned after `isPicked: Bool`.
  - Add `isMostDesired: Bool = false` parameter to the designated `init(id:name:description:image:pickedUserId:isPicked:localImage:itemLink:)`, positioned after `isPicked`.
  - Assign `self.isMostDesired = isMostDesired` in the initializer body.
  - In the `init(dictionary:)` extension initializer, parse `self.isMostDesired = dictionary["isMostDesired"] as? Bool ?? false` after the `self.itemLink` assignment.

---

