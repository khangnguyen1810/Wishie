# EC 3: Weak Self Capture — No Retain Cycle in Listener Callbacks

- [x] **Scenario: Listener callback does not retain deallocated `HomeViewModel`**
  - Given: `HomeViewModel 'home-ec3-weakself'` registers a Firestore listener using `[weak self]` in the closure
  - When: The view model is released before a pending Firestore snapshot arrives and the snapshot callback fires
  - Then: The closure body is a no-op (guard let self exits early), and no crash or access-after-free occurs
  - Verify: Confirm `[weak self]` is present in the listener callback; confirm `guard let self` (or equivalent) exits gracefully when `self` is nil

