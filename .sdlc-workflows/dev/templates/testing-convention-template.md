# Testing Convention Template

## Purpose
Define the project's testing conventions including frameworks, file organization, naming patterns, and coverage expectations to enforce consistent testing practices across code reviews and unit test implementation.

## Frameworks & Tooling
- Unit/Integration Runner: [e.g., Jest, Vitest, PyTest, JUnit, Mocha]
- E2E Framework: [e.g., Cypress, Playwright, Selenium]
- Assertions Library: [e.g., Chai, Jest built-in, PyHamcrest]
- Supplementary Tools: [e.g., React Testing Library, Supertest, MSW for API mocking]

## File Organization & Naming
- File Location: [e.g., Co-located (`User.test.ts` next to `User.ts`) or centralized `__tests__` folder]
- File Naming Pattern: [e.g., `*.test.ts`, `*.spec.ts`, `test_*.py`]
- Test Suite Naming: [e.g., Describe block matches component name? `describe('UserComponent', ...)`]

## Test Structure & Style
- Pattern: [e.g., AAA (Arrange-Act-Assert) required? Yes/No]
- Description Style: [e.g., BDD style (`it('should render...')`) or imperative (`test('renders...')`)]
- Nesting: [e.g., Are nested `describe` blocks allowed for grouping scenarios? Yes/No]
- Hooks Usage: [e.g., Prefer `beforeEach` for setup vs. helper functions inside tests]

## Mocking & Dependencies
- Mocking Strategy: [e.g., Mock all external imports (Unit) vs. Mock only HTTP requests (Integration)]
- External APIs: [e.g., Use MSW (Mock Service Worker), Nock, or manual mocks]
- Date/Time: [e.g., Must use fake timers/system time? (`jest.useFakeTimers`)]
- Global Objects: [e.g., How to mock `window`, `localStorage`, or `session`]

## Test Data & Fixtures
- Data Generation: [e.g., Use Factories (`UserFactory.create()`) vs. Static JSON fixtures]
- Database Handling: [e.g., In-memory DB (SQLite), Docker container, or rollback transaction per test]
- Cleanup: [e.g., Auto-cleanup via framework or manual `afterAll` teardown]

## Component / UI Specifics (If applicable)
- Selector Strategy: [e.g., Strictly use `data-testid`, or allow text/role queries?]
- Snapshot Testing: [e.g., Encouraged for UI structure? Banned due to brittleness?]
- Event Simulation: [e.g., `userEvent` (preferred) vs. `fireEvent`]

## Shared Test Utilities
- Location: [e.g., `src/test-utils`, `tests/helpers`]
- Custom Matchers: [e.g., Are custom assertions allowed? (e.g., `expect(response).toBeValidUser()`)]
- Authentication: [e.g., Use a global `login()` helper that bypasses UI?]

## Coverage & Quality Gates
- Metric Requirements: [e.g., 80% Statements, 90% Functions]
- Critical Paths: [e.g., Which folders require 100% coverage? (e.g., `src/utils`)]
- Exclusions: [e.g., Ignore `index.ts` barrels, interfaces, and DTOs]

## Framework Best Practices

### [Framework is used in this project]
- [Best practices related to this framework in bullet points]

### [another framework are used in this project]
- [Best practices related to this framework in bullet points]

## Build Commands & Tooling
- [ Depend on the project tech stack, e.g., `npm run test`, `pytest tests/`, `mvn test` with any necessary flags or environment variables]
