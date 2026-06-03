# Profile Screen – Requirements

## 1. Trigger / Entry Point

- **File:** `HomeView.swift`
- **Function:** `topAppBar()`
- **UI Element:**
  ```swift
  Circle()
      .fill(.lightYellow)
      .frame(width: 40, height: 40)
      .overlay(content: {
          Image("user")
              .resizable()
              .scaledToFit()
              .frame(width: 20)
      })
      .onTapGesture {
          activeSheet = .user
      }
  ```
- When the user taps this circular button, the app should navigate/present **ProfileView**.

---

## 2. Layout & Base Component

- The Profile Screen **reuses `BaseWishieScreen`** as its base container.
- The **TopAppBar** of ProfileView must include:
  - A **Back button** styled consistently with other screens in the project that have a back button.
  - A title, or left empty depending on the project's current design convention.

---

## 3. UI Content

### 3.1 Avatar
- Display a **user icon** (`Image("user")` or an equivalent SF Symbol) as a temporary avatar placeholder.
- The avatar should be prominently positioned at the top of the screen (e.g., centered, below the topAppBar).

### 3.2 User Information
Display the following fields fetched from Firebase:

| Field             | Description                        |
|-------------------|------------------------------------|
| **Full Name**     | The user's full name               |
| **Date of Birth** | The user's date of birth           |
| **Email**         | The user's email address           |
| **Phone**         | The user's phone number            |

### 3.3 Logout Button
- A **Logout** button placed at the bottom of the screen (or another appropriate position).
- When tapped, it triggers the sign-out action following the project's existing logout flow.

---

## 4. Data Source

- All user information (full name, date of birth, email, phone) is **fetched from Firebase**.
- Data is retrieved via the existing function:
  ```swift
  // File: AuthenticateService.swift
  func getUserInfo() { ... }
  ```
- `ProfileView` (or its corresponding ViewModel) should call `getUserInfo()` when the screen is initialized or appears.
- A **loading state** must be shown while waiting for the Firebase response.
- An **error state** must be handled if the data fetch fails.

---

## 5. Files to Create / Modify

| File | Action |
|------|--------|
| `ProfileView.swift` | **Create** – the Profile screen UI |
| `ProfileViewModel.swift` | **Create** (if following MVVM) – calls `getUserInfo()` and manages screen state |
| `AuthenticateService.swift` | **Reuse** `func getUserInfo()` – do not modify existing logic |
| `HomeView.swift` | **Modify** – ensure `activeSheet = .user` correctly presents `ProfileView` |

---

## 6. Additional Notes

- The avatar is **temporary** (user icon). It can be extended later to support real photo uploads.
- The back button and all UI components must be **visually consistent** with other screens in the project.
- Do not create new services or alter any logic inside `AuthenticateService.swift`; only call the existing function.
