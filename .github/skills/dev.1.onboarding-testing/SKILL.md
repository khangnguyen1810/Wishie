---
name: dev.1.onboarding-testing
description: "Analyze an iOS project testing codebase and generate a technical testing onboarding guide (knowledge.testing.md) with framework analysis, test structure documentation, and testing strategy."
argument-hint: "Optional: additional context or focus areas for testing framework analysis"
user-invocable: true
disable-model-invocation: true
---

Project Testing Knowledge Base Generation Workflow

<roleContext>
YOU ARE an expert iOS testing architect specialized in XCTest and XCUITest analysis for Swift application test suites.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: ANALYZE the iOS project testing codebase and GENERATE [OUTPUT_KNOWLEDGE_TESTING] as a technical testing onboarding guide focused on XCTest structure, UI test organization, test helpers, and execution commands.</primary>
<secondary>
    <goal>Document testing frameworks, patterns, and execution strategies</goal>
    <goal>Extract testing workflow commands for team onboarding</goal>
    <goal>Map testing infrastructure and cross-cutting concerns</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Additional context or focus areas for testing framework analysis
</userInput>

<systemInput>
SYSTEM_TEMPLATE_KNOWLEDGE_TESTING = `.sdlc-workflows/dev/templates/knowledge.testing.template.md`
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.1.onboarding-testing.reflection.md`
</systemInput>

<output>
OUTPUT_KNOWLEDGE_TESTING = `.sdlc-workflows/artifacts/dev/docs/knowledge.testing.md` - Comprehensive testing documentation
</output>

<executionFlow>
EXECUTE in STRICT SEQUENTIAL ORDER. NEVER skip, reorder, or parallelize—each phase depends on prior output.
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases SEQUENTIALLY. WAIT for completion before proceeding.
3. INTEGRATE post-workflow tasks
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation and setup tasks. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Create Empty Knowledge Files">
    USE terminal to: `cp [SYSTEM_TEMPLATE_KNOWLEDGE_TESTING] [OUTPUT_KNOWLEDGE_TESTING]`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase before proceeding:
<phase number="1" name="Testing Framework & Structure Analysis">
    <task id="1.1" title="Explore Testing Framework and Structure">
        ANALYZE testing directory structure and IDENTIFY all frameworks. EXAMINE test organization patterns: directory structure, file naming conventions, test type categorization (unit, integration, e2e).
    </task>
    <task id="1.2" title="Update Knowledge File">
        UPDATE [OUTPUT_KNOWLEDGE_TESTING] with "Testing Frameworks & Structure Patterns" section (or mark "N/A" if none found).
    </task>
</phase>
<phase number="2" name="Test Types & Patterns Analysis">
    <task id="2.1" title="Explore Test Types and Patterns">
        EXAMINE test files to IDENTIFY testing patterns. ANALYZE test locations, suite organization, and established conventions.
    </task>
    <task id="2.2" title="Update Knowledge File">
        UPDATE [OUTPUT_KNOWLEDGE_TESTING] with "Test Organization Patterns & Type Categorization" section (or mark "N/A" if none found).
    </task>
</phase>
<phase number="3" name="Test Execution & Commands Analysis">
    <task id="3.1" title="Explore Test Execution and Configuration">
        ANALYZE test configuration files and scripts. IDENTIFY execution commands, coverage tools, CI/CD integration, and reporting mechanisms.
    </task>
    <task id="3.2" title="Update Knowledge File">
        UPDATE [OUTPUT_KNOWLEDGE_TESTING] with "Test Execution Commands & Workflows" section (or mark "N/A" if none found).
    </task>
</phase>
<phase number="4" name="Mocking & Utilities Analysis">
    <task id="4.1" title="Explore Mocking and Test Utilities">
        LOCATE mocking strategies, test helpers, and shared utilities. ANALYZE mock patterns, fixture management, setup/teardown approaches.
    </task>
    <task id="4.2" title="Update Knowledge File">
        UPDATE [OUTPUT_KNOWLEDGE_TESTING] with "Mocking Strategies & Test Utilities" section (or mark "N/A" if none found).
    </task>
</phase>
<phase number="5" name="Test Data & Environment Analysis">
    <task id="5.1" title="Explore Test Data and Environment Management">
        ANALYZE fixture patterns, seed data strategies, database setup. EXAMINE environment configuration, data isolation, infrastructure requirements.
    </task>
    <task id="5.2" title="Update Knowledge File">
        UPDATE [OUTPUT_KNOWLEDGE_TESTING] with "Test Data Management & Environment Setup" section (or mark "N/A" if none found).
    </task>
</phase>
<phase number="6" name="Fill Remaining Sections">
    <task id="6.1" title="Complete Documentation">
        REVIEW [OUTPUT_KNOWLEDGE_TESTING] for unfilled sections. EXCLUDE or complete based on prior analysis.
    </task>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER COMPLETING all phases.
<task title="Execute Reflection Workflow">
    READ and FOLLOW [SYSTEM_PROMPT_REFLECTION]
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- NEVER include business-specific logic details
- NEVER count or enumerate specific test cases
- NEVER include implementation details unrelated to testing architecture
- ALWAYS focus ONLY on testing structural and framework aspects
- MUST maintain objective, technical tone
- MUST not contain code snippets or pseudo-code
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
