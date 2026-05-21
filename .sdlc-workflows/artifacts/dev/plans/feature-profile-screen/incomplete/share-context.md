# Shared Context – Profile Screen Feature

## Project Overview

- **Project:** Wishie (iOS SwiftUI App)
- **Target:** Build Profile Screen feature following MVVM architecture
- **Branch:** feature/profile_screen

## Architecture & Patterns

- **UI Framework:** SwiftUI
- **Design Pattern:** MVVM (Model-View-ViewModel)
- **Navigation:** RootNavigationCoordinator (route-based navigation)
- **State Management:** AppState (global app state)

## Key Files & Services

- **AuthenticateService.swift** – Contains `getUserInfo()` for fetching user data from Firebase
- **BaseWishieScreen.swift** – Base container for all screens (provides consistent layout)
- **HomeView.swift** – Home screen that triggers profile navigation
- **Route.swift** – App navigation routes

## Project Coding Standards (from dev-rules.instructions.md)

1. **No code comments** – Write clear, self-explanatory code
2. **No debugging code** – Remove console.log, print statements
3. **No TODO/TBD comments** – Complete all tasks
4. **Error handling & input validation** – Required for all functions
5. **Functional programming principles** – Prefer pure functions, immutable data
6. **NO code comments explaining what code does** – Use clear naming and structure

## UI/UX Conventions

- Top navigation bar styling: Consistent back button
- Avatar display: Use `Image("user")` as placeholder
- Logout button: Place at bottom or appropriate position
- Loading states: Show during data fetch
- Error states: Handle gracefully

## Data Flow

1. **ProfileView** appears → triggers ViewModel init
2. **ProfileViewModel** calls `AuthenticateService.getUserInfo()`
3. **UserModel** is updated with fetched data
4. **ProfileView** displays user info with loading/error states

## File Structure

```
Wishie/
  Screens/
    Home/
      HomeView.swift
    [NEW] Profile/
      ProfileView.swift
      ProfileViewModel.swift
  Services/
    AuthenticateService.swift
  Models/
    UserModel.swift
```

## Existing Models & Services

- **UserModel** – Contains user properties (name, email, phone, date of birth)
- **AppState** – Global app state management
- **AuthenticateService.getUserInfo()** – Fetch user data from Firebase
