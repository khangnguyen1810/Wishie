# EC 2: Empty / Partial User Data

- [x] **Scenario: Profile row shows fallback dash when a string field is empty** ✅ RESOLVED
  - Given: User "user-ec2-emptyfields" has `phone` stored as an empty string `""` in Firebase
  - When: ProfileView loads and `viewModel.userInfo.phone` is `""`
  - Then: The Phone row displays `"-"` as the value instead of blank text
  - Verify: `profileInfoRow(label:value:)` renders `Text("-")` when value is empty; confirm `value.isEmpty ? "-" : value` logic handles this
  - **Failure**: The fallback dash logic (`value.isEmpty ? "-" : value`) is correctly implemented and would display `"-"` for an empty phone string. However, the `profileInfoRow` layout violates the UI requirements: (1) it uses a `VStack` placing the label above the value instead of an `HStack` with label on the left and value on the right; (2) the value text is enclosed in a `RoundedRectangle` background, which is explicitly prohibited by the UI requirements.
  - **Root Cause**: `profileInfoRow` in `ProfileView.swift` is structured as a `VStack` with the value `Text` rendered below the label, and the value is wrapped with `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }`, creating a rectangle enclosure around each value.
  - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift#L72-L88) — `profileInfoRow` function: VStack layout (line 73) and RoundedRectangle background (lines 84–87)
  - ✅ RESOLVED: `profileInfoRow` refactored to `HStack(spacing: 16)` with label on the left (`minWidth: 110, alignment: .leading`) and value on the right (`maxWidth: .infinity, alignment: .leading`); `RoundedRectangle` background removed entirely.

- [x] **Scenario: Full Name row shows fallback when both firstName and lastName are empty** ✅ RESOLVED
  - Given: User "user-ec2-noname" has both `firstName` and `lastName` as `""` in Firebase
  - When: ProfileView loads and `viewModel.userInfo.getFullName()` returns `" "` (a single space)
  - Then: The Full Name row does not display a single invisible space; it displays `"-"` as the fallback value
  - Verify: `getFullName()` result of `" "` must be treated as empty — consider trimming whitespace before the empty check in `profileInfoRow`
  - **Failure**: `getFullName()` returns `"\(firstName) \(lastName)"` which produces `" "` (a single space) when both names are empty strings. In Swift, `" ".isEmpty` evaluates to `false`, so the whitespace-only string passes the empty check in `profileInfoRow` and the row displays an invisible space instead of `"-"`. No whitespace trimming is applied before the empty check.
  - **Root Cause**: Two compounding issues — (1) `UserModel.getFullName()` unconditionally concatenates with a space separator, producing a non-empty whitespace string when both names are `""`; (2) `profileInfoRow` uses `value.isEmpty ? "-" : value` without trimming, so `" "` bypasses the fallback. Additionally, the same UI layout violations apply (VStack instead of HStack, RoundedRectangle enclosure).
  - **Affected Files**:
    - [Wishie/Models/UserModel.swift](Wishie/Models/UserModel.swift#L30) — `getFullName()`: returns `" "` when both names are empty, line 30
    - [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift#L82) — `profileInfoRow`: `value.isEmpty` check (line 82) does not trim whitespace; VStack layout (line 73) and RoundedRectangle background (lines 84–87)
  - ✅ RESOLVED: `UserModel.getFullName()` updated to call `.trimmingCharacters(in: .whitespaces)` on the concatenated string, so both-empty names now return `""` and the `value.isEmpty ? "-" : value` check correctly displays `"-"`. `profileInfoRow` UI layout also fixed (HStack, no RoundedRectangle).

- [x] **Scenario: Date of Birth defaults to current date for user with no DOB stored** ✅ RESOLVED
  - Given: User "user-ec2-nodob" has no `dateOfBirth` field in their Firebase document
  - When: `UserModel.init(dictionary:)` is called and no `dateOfBirth` Timestamp exists
  - Then: `dateOfBirth` defaults to `Date()` (today's date), and the Date of Birth row displays today's date formatted as a short date string rather than `"-"`
  - Verify: Confirm the fallback `Date()` is visible in the DOB row; decide whether this should display `"-"` instead and update `profileInfoRow` or `UserModel` accordingly
  - **Failure**: The data logic is correct — `UserModel` defaults `dateOfBirth` to `Date()` when no Timestamp is present, and `toShortDateString()` produces a non-empty formatted string (e.g., "21 May, 26"), which `profileInfoRow` displays. However, the `profileInfoRow` layout violates the UI requirements: it uses a `VStack` (label above, value below) instead of an `HStack` (label on left, value on right), and the value is enclosed in a `RoundedRectangle` background, which is explicitly prohibited.
  - **Root Cause**: The `profileInfoRow` component layout is structurally incorrect for the required design. The `VStack` orientation and `RoundedRectangle` background wrapping the value `Text` conflict with the requirement that each row shows label-left and value-right on the same line with no rectangle enclosure.
  - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift#L72-L88) — `profileInfoRow` function: VStack layout (line 73) and RoundedRectangle background (lines 84–87)
  - ✅ RESOLVED: `profileInfoRow` restructured to `HStack(spacing: 16)` — label on left, value on right, no `RoundedRectangle` enclosure. DOB formatted string now displays correctly in the horizontal row layout.

