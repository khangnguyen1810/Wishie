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

- Should email be editable in the profile?
  No — email is read-only. Changing it requires Firebase Auth re-authentication and introduces an additional authentication flow that is out of scope.

- Where should the edit UI live?
  A dedicated `EditProfileView` screen pushed from `ProfileView`. This follows the existing screen-per-feature pattern in the codebase.

- Should the user's avatar be visible beyond the Profile screen?
  No — avatar is displayed only within the Profile screen. No changes are needed to `AuthViewModel` or other screens.
