# Clarification Questions Template

## Purpose

Record questions raised during planning and their confirmed answers to resolve ambiguities in task requirements, ensuring the implementation plan reflects verified decisions.

# Guide:

- NEVER add question's options into this file, keep context small.
- ONLY add questions and it's answer following the template below.

# Template

```
- [the question]:
[the answer and its brief reasoning]
```

# Clarification Questions:

- Can only ONE item per wishlist be marked as 'most desired' at a time, or can multiple items have that status simultaneously?
  Multiple — any number of items can be marked as most desired independently. Each `isMostDesired` toggle is isolated to that item; no other items are affected.

- For the owner's swipe-to-delete, which approach should be used?
  Migrate item list to SwiftUI List with native `.swipeActions`. The `ForEach`-in-`VStack` layout in `listContent()` will be refactored to a `List` to unlock native swipe gesture support.

- When an owner deletes an item, should a confirmation dialog appear before the delete is committed?
  Yes — show a confirmation dialog before deleting. This prevents accidental deletion and aligns with the existing `showDialogIfNeeded` dialog pattern already used in the screen.

- What should the progress indicator look like in the detail header?
  Horizontal progress bar with a text label (e.g., "3 / 7 gifts selected"). A new custom view or inline modifier will be added to the header section.

- Can the owner delete an item that a member has already reserved (isPicked = true)?
  No — picked/reserved items are protected. The delete action (both swipe and bottom-sheet button) will be disabled or hidden when `item.isPicked` is `true`.
