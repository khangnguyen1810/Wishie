# EC 3: Sheet Stacking — Sequential Presentation Delay

- [x] **Scenario: Option sheet dismisses before manual entry sheet is presented**
  - Given: `AddItemOptionSheet` is currently presented on `WishlistDetailScreen`
  - When: The user taps "Fill in manually"
  - Then: `AddItemOptionSheet` is dismissed first, followed by a `DispatchQueue.main.asyncAfter` delay before `AddItemManualDetailSheet` is presented, preventing iOS sheet-stack conflicts
  - Verify: Confirm the view model or action handler sets the option sheet binding to `false` and then uses `asyncAfter` before setting the manual sheet binding to `true`

- [x] **Scenario: Option sheet dismisses before paste-link sheet is presented**
  - Given: `AddItemOptionSheet` is currently presented on `WishlistDetailScreen`
  - When: The user taps "Paste a product link"
  - Then: `AddItemOptionSheet` is dismissed first with a delay before `AddItemPasteLinkDetailSheet` is presented
  - Verify: Confirm the same `asyncAfter` dismiss-then-present pattern is applied for the paste-link entry path

---

