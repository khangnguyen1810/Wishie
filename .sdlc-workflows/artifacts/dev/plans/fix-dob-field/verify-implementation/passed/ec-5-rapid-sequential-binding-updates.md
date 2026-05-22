# EC 5: Rapid Sequential Binding Updates

- [x] **Scenario: dateOfBirth converges to the final value after multiple rapid updates**
  - Given: `DateInputView` is mounted with `date` binding pointing to `dob-ec5-start` = February 1, 2000
  - When: The `date` binding is updated in rapid succession to `dob-ec5-mid` = April 10, 1985, then immediately to `dob-ec5-final` = September 30, 1992 before any re-render settles
  - Then: `dateOfBirth` ultimately equals `dob-ec5-final` = September 30, 1992, and the picker sheet — when opened — displays September 30, 1992
  - Verify: Confirm no intermediate value (`dob-ec5-start` or `dob-ec5-mid`) persists in `dateOfBirth`; confirm the picker wheel is positioned at `dob-ec5-final`
