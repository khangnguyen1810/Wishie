# AC 9: Error Surfacing via ViewModel

- [x] **Scenario: Errors during add flow are surfaced through isShowError and errorMessage**
  - Given: An error occurs during image upload or `addWishlistItem` for item `'item-ac9-error'`
  - When: The error handling (catch blocks or failure callbacks) in `WishlistDetailViewController` is reviewed
  - Then: `isShowError` is set to `true` and `errorMessage` is populated with a descriptive, non-empty error string in every failure path of the add operation
  - Verify: Code review confirms both `isShowError` and `errorMessage` are set together in each catch block; neither is set in isolation
