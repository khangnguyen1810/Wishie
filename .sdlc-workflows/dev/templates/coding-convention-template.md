# Project Coding Convention

## Purpose
Document the project's coding standards, naming conventions, and architectural patterns to serve as the authoritative reference during code reviews.

## Core Development Principles
- DRY (Don't Repeat Yourself): Extract common functionality into shared modules or utilities
- Single Responsibility Principle: Each function, class, or module should have one well-defined purpose
- KISS (Keep It Simple, Stupid): Favor simple, readable solutions over complex ones
- Separation of Concerns: Organize code by functionality and responsibility

## Naming Conventions
- Variables: [e.g., camelCase, snake_case]
- Functions: [e.g., camelCase; verb-noun pattern (getUser, calculateTotal)]
- Classes/Components: [e.g., PascalCase]
- Interfaces/Types: [e.g., PascalCase; prefix with 'I' or suffix with 'Type'?]
- File Names: [e.g., kebab-case.ts, PascalCase.tsx, snake_case.py]
- Private Members: [e.g., prefix with underscore `_variable`]

## File Structure & Organization
- Directory Hierarchy: [e.g., Feature-based (User/components) or Layer-based (components/, services/)]
- Barrel Files: [e.g., Do we use `index.ts` to export modules? Yes/No]
- Component Co-location: [e.g., CSS, Tests, and Component files stay in the same folder? Yes/No]

## Architectural Patterns
- API Interaction: [e.g., Repository pattern, Direct Axios calls, Custom Hooks]
- Data Flow: [e.g., Unidirectional props flow, Event bus, Dependency Injection]
- Business Logic Location: [e.g., Logic inside Services/Hooks, never inside UI components]


## State Management (EXCLUDE if project doesn't have FE)
- Server State: (e.g., React Query, SWR, Apollo Client) - caching API data.
- Global Client State: (e.g., Redux, Zustand, Context API) - user settings, auth status.
- Local State: Component-level useState. Provide a schema of the Global Store if applicable.}}

## Language Specific Syntax
- Type Safety: [e.g., Strict TypeScript usage, `any` is forbidden]
- Function Style: [e.g., Arrow functions vs Function declarations]
- Asynchronous Handling: [e.g., `async/await` preferred over `.then()`]

## Imports & Dependencies
- Import Order: [e.g., Built-in -> Third-party -> Internal absolute -> Internal relative]
- Path Aliases: [e.g., Use `@/components` instead of `../../../components`]

## Logging Standards
- Mechanism: [e.g., Standard `console.log`, custom logger wrapper, or external service like Datadog/Sentry]
- Log Levels: [e.g., Strict usage of `debug`, `info`, `warn`, `error`]
- Production Cleaning: [e.g., Are logs stripped in production builds? Yes/No]
- PII/Sensitive Data: [e.g., Strict rule: never log passwords, tokens, or email addresses]

## Constants Management
- Definition Location: [e.g., Top of the file vs. dedicated `constants.ts` file per feature vs. global `config` folder]
- Naming Pattern: [e.g., `UPPER_SNAKE_CASE` for global config, `camelCase` for internal file constants]
- Magic Values: [e.g., Strict ban on magic numbers/strings; must be assigned to a named constant]

## Shared Code & Common Modules
- Location: [e.g., `/src/shared`, `/src/common`, or a separate package in a monorepo]
- Cross-Feature Imports: [e.g., Can `Feature A` import directly from `Feature B`? Or must they share via `Shared`?]
- Abstraction Level: [e.g., Shared code must be purely functional and UI-agnostic? Yes/No]

## Utilities & Helper Functions
- Location: [e.g., `/utils` folder at root, or `utils.ts` inside feature folders]
- Purity: [e.g., Utility functions must be pure (deterministic, no side effects)]
- Naming: [e.g., `is*` for booleans, `get*` for retrieval, `format*` for data transformation]
- Testing Requirement: [e.g., Utilities require 100% unit test coverage? Yes/No]

## Error Handling
- Catching Strategy: [e.g., Global Error Boundary, Try/Catch in services only]
- Custom Errors: [e.g., Use specific `AppError` class with error codes]

## Code Comments
- No code comments, docstring or TODO

## Framework Best Practices

### [Framework is used in this project]
- [Best practices related to this framework in bullet points]

### [another framework are used in this project]
- [Best practices related to this framework in bullet points]

## Build Commands & Tooling
- [ Depend on the project tech stack, e.g., `npm run build`, `mvn package`, `docker build .` with any necessary flags or environment variables]