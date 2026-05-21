# Project Coding Convention

## Purpose

Document the project's coding standards, naming conventions, and architectural patterns to serve as the authoritative reference during code reviews.

## Core Development Principles

- DRY (Don't Repeat Yourself): Extract common functionality into shared managers, utilities, and helper modules.
- Single Responsibility Principle: Each Swift type and SwiftUI view should have one clear responsibility.
- KISS (Keep It Simple, Stupid): Prefer readable and maintainable SwiftUI code over overly complex abstractions.
- Separation of Concerns: Keep views, view models, services, models, and utilities separated.

## Naming Conventions

- Variables: `camelCase`
- Functions: `camelCase` with action-oriented names (`fetchWishlists`, `saveUserSession`).
- Classes/Components: `PascalCase` for views, models, managers, and view models.
- Protocols/Types: `PascalCase` with descriptive names (`WishlistServiceProtocol`, `AuthRepository`).
- File Names: `PascalCase.swift` matching the primary type or view in the file.
- Private Members: use leading underscore only for private backing storage or internal state properties.

## File Structure & Organization

- Directory Hierarchy: Layered app organization with folders like `Screens`, `Models`, `Services`, `Manager`, `Utils`, `CustomView`, `Helper`, and `Resources`.
- Barrel Files: Not applicable in Swift. Keep one primary type or view per file.
- Component Co-location: Keep view definitions in view files and business logic in view models and services.

## Architectural Patterns

- API Interaction: Encapsulate network and Supabase logic in service/manager classes.
- Data Flow: Maintain unidirectional data flow from service layer through observable view models to SwiftUI views.
- Business Logic Location: Place business rules in `ViewModel` and service classes, avoiding dense logic inside view bodies.

## State Management

- Server State: Handle remote state with asynchronous service calls inside view models.
- Global Client State: Use `ObservableObject` view models or singleton managers for shared app state such as auth and navigation status.
- Local State: Use `@State`, `@StateObject`, `@ObservedObject`, and `@Binding` for view-local and presentation state.

## Language Specific Syntax

- Type Safety: Prefer explicit type annotations when helpful and avoid forced unwraps.
- Function Style: Prefer expressive methods and small helper functions.
- Asynchronous Handling: Prefer structured concurrency with `async/await` and avoid nested callback chains.

## Imports & Dependencies

- Import Order: system frameworks first, third-party frameworks next, then local project modules.
- Path Aliases: Not applicable for this Xcode Swift project.

## Logging Standards

- Mechanism: Prefer a centralized logger or structured debug output.
- Log Levels: Use debug and warning levels for development diagnostics.
- Production Cleaning: Remove debug-only logging from production code.
- PII/Sensitive Data: Never log passwords, auth tokens, or personal user data.

## Constants Management

- Definition Location: Keep app-wide constants in `WishieConstants.swift`; feature-specific values may live near the feature.
- Naming Pattern: Use `UPPER_SNAKE_CASE` for global config constants and `camelCase` for local constants.
- Magic Values: Replace literal numbers and strings with named constants.

## Shared Code & Common Modules

- Location: Shared helpers and utilities live in `Wishie/Utils`, `Wishie/Helper`, and `Wishie/Models`.
- Cross-Feature Imports: Share common modules across features through utility and manager folders, avoiding circular dependencies.
- Abstraction Level: Shared code should be UI-agnostic when possible and reusable across multiple features.

## Utilities & Helper Functions

- Location: Keep reusable helpers in `Wishie/Utils` and `Wishie/Helper`.
- Purity: Prefer pure utility functions with deterministic outputs; isolate side effects to explicit helper classes.
- Naming: Use `is` for boolean checks and `get`/`make` for value retrieval or creation.
- Testing Requirement: Cover reusable utilities with unit tests when they implement business logic.

## Error Handling

- Catching Strategy: Use `do/catch` in service and view model layers and propagate recoverable errors to the UI.
- Custom Errors: Use meaningful Swift `Error` types for domain-specific failures.

## Code Comments

- No code comments, docstring or TODO

## Framework Best Practices

### SwiftUI

- Keep view bodies concise and move stateful logic into view models.
- Use `@StateObject` for view models owned by a view and `@ObservedObject` for injected dependencies.
- Prefer view composition and reusable small views instead of large monolithic views.
- Use accessibility identifiers for UI tests and maintain accessible state in view definitions.

## Build Commands & Tooling

- Build command: `xcodebuild build -scheme Wishie -sdk iphonesimulator`
- Test command: `xcodebuild test -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 15'`
