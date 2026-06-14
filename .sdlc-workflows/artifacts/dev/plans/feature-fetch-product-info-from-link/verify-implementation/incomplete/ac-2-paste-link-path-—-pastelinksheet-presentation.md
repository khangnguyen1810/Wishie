# AC 2: Paste-Link Path — PasteLinkSheet Presentation

- [x] **Scenario: Selecting "Paste a product link" opens PasteLinkSheet**
  - Given: `AddItemOptionSheet` is currently presented (test data namespace: `ac2-paste-link`)
  - When: The user taps the "Paste a product link" option
  - Then: `AddItemOptionSheet` is dismissed and `PasteLinkSheet` is presented, containing a URL input field and a submit/fetch trigger
  - Verify:
    - `AddItemOptionSheet`'s "paste link" action sets a state flag that triggers presentation of `PasteLinkSheet`
    - `PasteLinkSheet` contains a `TextField` (or equivalent) bound to a URL string property
    - A confirm/fetch button is present and enabled only when the URL field is non-empty

---
