# Coding Knowledge Base Template

<!-- When scanning the codebase, **exclude any section that is not relevant to the project's tech stack**. For example, skip "State Management" and "Component Patterns" for a pure backend project, or skip "Database & Data Access Patterns" for a pure frontend project. keep all the section if it is a full-stack project. -->

## Purpose

Capture the codebase's architecture, design patterns, implementation conventions, and cross-cutting concerns to provide shared context for planning and implementation workflows.

## System Architecture

{{Provide a high-level diagram (using MermaidJS) of the system components. Identify the Frontend, Backend services, Databases, and Message Brokers. Explain the communication protocols between them (e.g., REST, gRPC, Pub/Sub).}}

## Key Design Patterns

{{Identify the primary architectural style (e.g., Monolithic, Microservices, Hexagonal/Ports & Adapters). List specific software design patterns used frequently (e.g., Repository Pattern, Factory Pattern, Singleton, Strategy) and explain *why* they were chosen.}}

## Implementation Patterns

{{Describe the standard way features are implemented. Example: "All business logic must reside in Service classes, not Controllers. Database queries must go through the ORM/Repository layer."}}

## State Management (Frontend)

<!-- *Exclude this section if the project has no frontend.* -->

{{Define how state is handled. Distinguish between:

Server State: (e.g., React Query, SWR, Apollo Client) - caching API data.

Global Client State: (e.g., Redux, Zustand, Context API) - user settings, auth status.

Local State: Component-level useState. Provide a schema of the Global Store if applicable.}}

## Component Patterns (Frontend)

<!-- *Exclude this section if the project has no frontend.* -->

{{Define the standard patterns for building UI components.

* **Component Architecture:** (e.g., Atomic Design, Feature-based, Container/Presentational pattern)
* **Component Types:** Distinguish between Smart/Container components vs Dumb/Presentational components
* **Composition Strategy:** How are components composed? (e.g., Higher-Order Components, Render Props, Custom Hooks)
* **Props Conventions:** Naming patterns, prop drilling limits, when to use context vs props
* **Component Structure:** Standard internal organization (imports, types, component logic, styles, exports)
* **Reusability Guidelines:** When to extract a shared component vs keep it local
* **Style Approach:** (e.g., CSS Modules, Styled Components, Tailwind utility classes, CSS-in-JS)
* **Form Patterns:** Standard approach to form handling and validation (e.g., Controlled vs Uncontrolled, Form libraries like Formik/React Hook Form)}}

## Cross-cutting Concerns

{{Explain how systemic issues are handled centrally. Describe the implementation of Caching strategies, Global Transaction Management, and Observability (Metrics/Tracing).}}
