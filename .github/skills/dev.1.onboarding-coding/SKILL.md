---
name: dev.1.onboarding-coding
description: "Analyze a SwiftUI iOS application and generate a technical onboarding guide (knowledge.coding.md) covering architecture, design patterns, file structure, and design choices."
argument-hint: "Optional: additional context or focus areas for architecture analysis"
user-invocable: true
disable-model-invocation: true
---

Coding Knowledge Base Generation

<roleContext>
YOU ARE an expert software architect specialized in Swift and iOS application architecture, including SwiftUI, Xcode project structure, and modular UI/service decomposition.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: ANALYZE a SwiftUI iOS application codebase and GENERATE [OUTPUT_KNOWLEDGE_CODING] from [OUTPUT_KNOWLEDGE_CODING_TEMPLATE] as a technical onboarding guide focused on app architecture, UI composition, state flow, services, and platform conventions.</primary>
<secondary>
    <goal>DOCUMENT architectural patterns, file structure, design choices</goal>
    <goal>MAP cross-cutting concerns and system-wide functionalities</goal>
    <goal>CREATE objective technical documentation on system structure</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Optional additional context or focus areas for analysis
</userInput>

<systemInput>
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.1.onboarding-coding.reflection.md`
</systemInput>

<output>
OUTPUT_KNOWLEDGE_CODING = knowledge.coding.md from onboarding Initialization task
OUTPUT_KNOWLEDGE_CODING_TEMPLATE = `.sdlc-workflows/dev/templates/knowledge.coding.template.md`
</output>

<executionFlow>
EXECUTE in STRICT SEQUENTIAL ORDER. NEVER skip, reorder, or parallelize—each phase depends on prior output.
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. DETERMINE project type (Backend-only, Frontend-only, or Full-stack).
3. EXECUTE phases SEQUENTIALLY based on project type. SKIP phases not applicable.
4. INTEGRATE post-workflow tasks
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation and setup tasks in sequence. STOP and REPORT if any fails:
    <task title="Account User Inputs">
        CONSIDER [USER_INPUT] before proceeding (if not empty).
    </task>
    <task title="onboarding Initialization">
        EXECUTE below command with terminal tool:
        `sdlc-workflows onboarding-init`
    </task>
    <task title="Determine Project Type">
        ANALYZE the codebase to DETERMINE the project type:
        - **Backend-only**: No frontend framework detected (no React, Angular, Vue, Svelte, etc.)
        - **Frontend-only**: No backend framework detected (no Express, NestJS, Spring, Django, etc.)
        - **Full-stack**: Both frontend and backend components detected
        RECORD the project type for use in subsequent phases.
    </task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase entirely before proceeding.
SKIP phases marked with applicability conditions that do not match the detected project type.
<phase number="1" name="Architectural Assessment">
    <applicability>ALL project types</applicability>
    <task id="1.1" title="System Architecture Mapping">
        ANALYZE root directory structure and system components. DETERMINE architecture type (monorepo, monolith, microservices, Hexagonal/Ports & Adapters). IDENTIFY Frontend, Backend services, Databases, and Message Brokers. DOCUMENT communication protocols (REST, GraphQL, WebSocket, gRPC, Pub/Sub). CREATE high-level MermaidJS diagram.
    </task>
    <task id="1.2" title="Design Patterns Identification">
        IDENTIFY design patterns used (Repository, Factory, Singleton, Strategy, CQRS, Observer, Module). DOCUMENT each pattern and WHY it was chosen based on code structure.
    </task>
    <task id="1.3" title="Implementation Patterns">
        DOCUMENT standard conventions for feature implementation. IDENTIFY typical flow for new features. DOCUMENT code organization rules, naming conventions, and file structure patterns.
        IF Backend: IDENTIFY where business logic resides (Service vs Controllers). DOCUMENT database query structure (ORM/Repository layer).
        IF Frontend: ANALYZE 'src' directory for entry point and routing conventions. DETERMINE routing patterns, layout hierarchy, page organization. DOCUMENT route groups, parallel routes, intercepting routes if present.
    </task>
    <task id="1.4" title="Shared Code Conventions">
        INVESTIGATE shared code directories. DOCUMENT patterns and locations for: utilities, DTOs/interfaces, constants, base classes, reusable components.
        IF Frontend: INCLUDE common hooks and shared component libraries.
    </task>
    <task id="1.5" title="Cross-Cutting Concerns">
        FIND and DOCUMENT system-wide implementations:
        ALL: logging, exception handling, configuration, authentication/authorization, caching, observability.
        IF Backend: transaction management.
        IF Frontend: middleware, auth flow, analytics/metrics.
    </task>
    <task id="1.6" title="Update Output">
        UPDATE [OUTPUT_KNOWLEDGE_CODING] with architectural assessment.
    </task>
</phase>
<phase number="2" name="Application-Level Design">
    <applicability>ALL project types</applicability>
    <task id="2.1" title="Application Design Description">
        ANALYZE each runnable project source structure. DOCUMENT internal design pattern and primary folder responsibilities.
    </task>
    <task id="2.2" title="Update Output">
        UPDATE [OUTPUT_KNOWLEDGE_CODING] with application-level design analysis.
    </task>
</phase>
<phase number="3" name="State Management and Data Flow">
    <applicability>SKIP if Backend-only project</applicability>
    <task id="3.1" title="State Management Analysis">
        DISTINGUISH between state types:
        - Server State: caching solutions (React Query, SWR, Apollo Client)
        - Global Client State: state libraries (Redux, Zustand, Context API)
        - Local State: component-level useState patterns
        DOCUMENT Global Store schema if applicable.
    </task>
    <task id="3.2" title="Update Output">
        UPDATE [OUTPUT_KNOWLEDGE_CODING] with state management analysis.
    </task>
</phase>
<phase number="4" name="Component Patterns and Styling">
    <applicability>SKIP if Backend-only project</applicability>
    <task id="4.1" title="Component Architecture Patterns">
        DOCUMENT component patterns:
        - Architecture: pattern used (Atomic Design, Feature-based, Container/Presentational)
        - Types: Smart/Container vs Dumb/Presentational components
        - Composition: HOCs, Render Props, Custom Hooks
        - Props: naming patterns, prop drilling limits, context vs props usage
        - Structure: internal organization (imports, types, logic, styles, exports)
        - Reusability: when to extract shared vs keep local
    </task>
    <task id="4.2" title="Styling Approach">
        DOCUMENT styling:
        - Method: CSS Modules, Styled Components, Tailwind, CSS-in-JS
        - UI Library: component library usage and customization
        - Responsive: breakpoint patterns and mobile-first approach
    </task>
    <task id="4.3" title="Form Patterns">
        DOCUMENT form handling:
        - Strategy: Controlled vs Uncontrolled components
        - Libraries: Formik, React Hook Form, native forms
        - Validation: approach and error handling
    </task>
    <task id="4.4" title="Update Output">
        UPDATE [OUTPUT_KNOWLEDGE_CODING] with component patterns and styling.
    </task>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER COMPLETING all applicable phases.
    <task title="Remove Irrelevant Sections">
        REVIEW [OUTPUT_KNOWLEDGE_CODING] and REMOVE any template sections that are not relevant to the detected project type (as noted in the template comments).
    </task>
    <task title="Execute Reflection Workflow">
        READ and FOLLOW [SYSTEM_PROMPT_REFLECTION]
    </task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- NEVER include business-specific logic details
- NEVER count or enumerate specific features or API endpoints
- NEVER include implementation details unrelated to architecture
- ALWAYS focus ONLY on structural and design aspects
- MUST maintain objective, technical tone
- MUST not contain code snippets or pseudo-code
- MUST SKIP phases not applicable to the detected project type
- MUST REMOVE template sections not relevant to the project type from [OUTPUT_KNOWLEDGE_CODING]
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution following <executionFlow>.</command>
<autonomyLevel>Full autonomous execution with HIGH-LEVEL progress reporting only.</autonomyLevel>
</executionInstructions>
