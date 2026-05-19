# Technical Onboarding Guide for Wishie iOS

## Purpose

Capture the codebase architecture, design patterns, implementation conventions, and cross-cutting concerns for the frontend SwiftUI app.

## System Architecture

Wishie is a single SwiftUI iOS app target. The application entry point is `WishieApp.swift`, which configures Firebase via `AppDelegate`, initializes auth state, and injects `AuthViewModel` into the environment.

The app is frontend-only within this repository. It integrates with external backend services for authentication, database persistence, and media storage through Firebase and Supabase clients. There is no internal server-side project in the repository.

## Key Design Patterns

The repo uses a layered UI architecture:

- MVVM-inspired structure: SwiftUI views render state owned and managed by observable view models.
- Protocol-based service abstraction: `AuthenticateServiceProtocol` and `WishlistServiceProtocol` separate interface from implementation.
- Singleton infrastructure manager: `SupabaseManager.shared` centralizes Supabase client creation.
- State-driven navigation: view selection is based on auth and onboarding state rather than a separate router.

## Implementation Patterns

Feature implementation follows an established convention:

- UI is defined in `Wishie/Screens` and reusable elements are placed under `Wishie/CustomView`.
- Domain and payload models are defined in `Wishie/Models`.
- Service integration and backend communication are centralized in `Wishie/Services`.
- Shared helpers, extensions, and platform utilities are placed in `Wishie/Utils`, `Wishie/Helper`, and `Wishie/Manager`.
- View models contain business logic, validation, and state transitions. Views handle layout and user interactions.

## State Management (Frontend)

This app uses SwiftUI native state management:

- Local State: `@State` is used for transient UI state inside views.
- Shared State: `@StateObject` creates persistent view models and `@EnvironmentObject` shares state across child views.
- Published State: view models expose state via `@Published` properties for view binding.
- External State: authentication session data and onboarding completion are persisted via `AppStorage` and `UserDefaults`.

## Component Patterns (Frontend)

UI components follow reusable SwiftUI conventions:

- Component Architecture: View files are organized by screen and reusable component boundaries, with base screen wrappers in `BaseWishieScreen`.
- Component Types: Reusable view components are extracted into `Wishie/CustomView`; screen-specific layouts remain in `Wishie/Screens`.
- Composition Strategy: Views are composed from small nested SwiftUI views and custom view builder methods.
- Props Conventions: Data is passed through bindings and environment objects instead of global state.
- Component Structure: Files typically define one main view type alongside private helper methods.
- Reusability Guidelines: Extract shared UI patterns when they are used across multiple screens.
- Style Approach: Styling is implemented with SwiftUI view modifiers, asset colors, and color extensions rather than a separate styling framework.
- Form Patterns: Form fields are bound to view model state and validation logic is handled in view models.

## Cross-cutting Concerns

Systemic concerns are handled centrally:

- Authentication: `AuthViewModel` coordinates login, signup, and session state using `AuthenticateService`.
- Configuration: Firebase is initialized in `AppDelegate`, and Supabase client configuration is centralized in `SupabaseManager`.
- Error Handling: Service failures and validation issues are surfaced through published error state and UI bindings.
- Persistence: User session keys and onboarding flags are persisted using `AppStorage` and `UserDefaults`.
- Observability: SwiftUI view updates are driven by published state changes, with asynchronous service results propagated through view models.

## Notes

This guide is specific to the frontend SwiftUI application in this repository. Since there is no internal backend project here, backend-specific implementation patterns and service host orchestration are not part of this analysis.
