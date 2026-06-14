# AC 10: MVVM Compliance — Business Logic in ViewController

- [x] **Scenario: New sheets delegate all async and business logic to WishlistDetailViewController**
  - Given: Source code of `AddItemManualDetailSheet` and `AddItemPasteLinkDetailSheet` for feature `'feature-ac10-mvvm'`
  - When: The view files are reviewed for any direct service calls or async operations
  - Then: Both views contain only layout and user interaction code; all service calls (`WishlistService`, `ProductMetadataService`), state mutations, and async operations are implemented as methods on `WishlistDetailViewController`
  - Verify: Code review confirms views receive `viewModel: WishlistDetailViewController` (or equivalent `@ObservedObject`) and invoke `viewModel.someMethod()` for actions rather than performing work inline

