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

- How should the navigation coordinator represent app states internally?
  Single enum with associated values (e.g., AppState.welcome, AppState.authenticated(userId)). This approach is type-safe, enforces valid state combinations, and makes pattern matching easier in view rendering logic.

- Should transition animations be configurable?
  Fixed animations (specific animation per state transition, not user-configurable). This simplifies implementation and ensures consistent UX across all root navigation transitions, avoiding scope creep.

- How should the launch/splash screen be integrated with the coordinator?
  Keep LaunchScreen in WishieApp.swift (coordinator only handles navigation after app is ready). This maintains minimal refactoring of WishieApp and keeps lifecycle management separate from navigation routing.

- Should AuthViewModel remain responsible for auth state, or should its state move into the coordinator?
  Keep AuthViewModel as-is; coordinator observes isLoggedIn and determines navigation state. This minimizes refactoring of existing auth logic and maintains separation of concerns between auth operations and navigation decisions.

- Which refactoring aspect is highest priority to implement first?
  State centralization (create coordinator with unified state model). This is the foundation that unblocks animation improvements and scalability pattern implementation.
