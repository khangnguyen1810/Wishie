# Testing Convention Template

## Purpose

Define the project's testing conventions including frameworks, file organization, naming patterns, and coverage expectations to enforce consistent testing practices across code reviews and unit test implementation.

## Frameworks & Tooling

- Unit/Integration Runner: XCTest
- E2E Framework: XCUITest for UI interaction validation
- Assertions Library: XCTest built-in assertions
- Supplementary Tools: Xcode test harness and `xcodebuild` test execution

## File Organization & Naming

- File Location: Separate test targets under `WishieTests` for unit tests and `WishieUITests` for UI tests.
- File Naming Pattern: `*Tests.swift` for unit and UI test files.
- Test Suite Naming: Test class names mirror the tested component or view model with `Tests` suffix.

## Test Structure & Style

- Pattern: Use Arrange-Act-Assert consistently.
- Description Style: Use descriptive `test` function names such as `testLoginViewModelAuthenticatesUser`.
- Nesting: Avoid deep nesting; keep individual tests focused and explicit.
- Hooks Usage: Use `setUp()` and `tearDown()` for shared setup and cleanup.

## Mocking & Dependencies

- Mocking Strategy: Use manual mocks or stub implementations for service dependencies.
- External APIs: Isolate network calls by mocking the network layer or service wrappers.
- Date/Time: Inject fixed or test clock values rather than relying on system time.
- Global Objects: Avoid direct use of `UserDefaults`, `Keychain`, or system singletons in tests; inject wrappers instead.

## Test Data & Fixtures

- Data Generation: Use static test fixtures or factory helper methods for model instances.
- Database Handling: Prefer in-memory or stubbed persistence layers; avoid integration tests that depend on external databases.
- Cleanup: Use `tearDown()` to reset shared state after tests.

## Component / UI Specifics (If applicable)

- Selector Strategy: Use accessibility identifiers for SwiftUI views and UI elements in UI tests.
- Snapshot Testing: Avoid snapshot tests unless strictly necessary due to brittleness.
- Event Simulation: Use XCUITest gestures and element interactions for UI flows.

## Shared Test Utilities

- Location: Keep shared test helpers in `WishieTests` or `Tests/Helpers` if present.
- Custom Matchers: Prefer helper assertions for repeated verification logic.
- Authentication: Use dedicated helper methods to simulate authenticated state in tests.

## Coverage & Quality Gates

- Metric Requirements: Prioritize coverage for view models, managers, and service logic.
- Critical Paths: Focus on business logic in `ViewModel` and service classes.
- Exclusions: Exclude generated or Apple-provided framework code; test only project source and test-specific helpers.

## Framework Best Practices

### XCTest

- Structure unit tests around view models and service behavior.
- Keep tests deterministic and avoid network dependency in unit tests.
- Favor small, focused test methods over large, end-to-end cases.

### XCUITest

- Use accessibility identifiers to target UI elements reliably.
- Keep UI tests resilient by avoiding timing assumptions.
- Use UI tests for major user flows rather than granular component behavior.

## Build Commands & Tooling

- Run tests with Xcode or `xcodebuild`.
- Example test command: `xcodebuild test -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 15'`
