---
name: dev.setup-workflow
description: "Configure agent workflow by analyzing project tech stack and updating onboarding prompts, file filters, and conventions."
argument-hint: "User input to provide additional context for the setup process."
user-invocable: true
disable-model-invocation: true
---

# SDLC Workflow Setup

<roleContext>
YOU ARE an expert agent executing the SDLC workflow setup. FOLLOW instructions precisely.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: Configure agent workflow by analyzing project tech stack and updating onboarding prompts, file filters, and conventions.</primary>
</objectives>

<userInput>
USER_INPUT = Additional context for setup process
</userInput>

<systemInput>
CODING_CONVENTION_TEMPLATE = `.sdlc-workflows/dev/templates/coding-convention-template.md`
TESTING_CONVENTION_TEMPLATE = `.sdlc-workflows/dev/templates/testing-convention-template.md`
CODING_CONVENTION_OUTPUT = `.sdlc-workflows/artifacts/dev/docs/coding-convention.md`
TESTING_CONVENTION_OUTPUT = `.sdlc-workflows/artifacts/dev/docs/testing-convention.md`
ONBOARDING_CODING = `skills/dev.1.onboarding-coding`
ONBOARDING_TESTING = `skills/dev.1.onboarding-testing`
PLAN_AND_IMPLEMENT_CODE_REVIEW_CODING = `skills/dev.4a.plan-and-implement-code-review-coding`
PLAN_AND_IMPLEMENT_CODE_REVIEW_TESTING = `skills/dev.4a.plan-and-implement-code-review-testing`
PLAN_AND_IMPLEMENT_UNIT_TEST = `skills/dev.5a.plan-and-implement-unit-test`
CREATE_PR = `skills/dev.6.create-pull-request`
REFLECTION_SETUP = `.sdlc-workflows/dev/reflections/dev.workflow-setup-reflection.md`
</systemInput>

<output>
[ONBOARDING_CODING] - Revised backend onboarding prompt (if backend exists)
[ONBOARDING_TESTING] - Revised testing onboarding prompt (if tests exist)
[CODING_CONVENTION_OUTPUT] - Filled coding conventions
[TESTING_CONVENTION_OUTPUT] - Filled testing conventions
Updated file extension filters in prompt files based on detected tech stack
</output>

<executionFlow>
EXECUTION RULES:
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases in STRICT SEQUENTIAL order. NEVER skip or reorder phases. Each phase depends on prior phase output.
3. Within each phase, execute tasks in listed order UNLESS under <parallel-group>.
4. Tasks within a <parallel-group> MUST be launched CONCURRENTLY. Each task in a <parallel-group> is INDEPENDENT and can run simultaneously using using sub-agent
5. INTEGRATE post-workflow tasks after all phases complete.
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE these validation and setup tasks in sequence. STOP and REPORT if any task fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Create Coding Conventions File">
    EXECUTE: `cp [CODING_CONVENTION_TEMPLATE] [CODING_CONVENTION_OUTPUT]`
</task>
<task title="Create Testing Conventions File">
    EXECUTE: `cp [TESTING_CONVENTION_TEMPLATE] [TESTING_CONVENTION_OUTPUT]`
</task>
<task title="Install Playwright CLI for Ui Testing">
   EXECUTE: `npm install -g @playwright/cli@latest`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE the following phases SEQUENTIALLY. COMPLETE each phase entirely before proceeding:
<phase number="1" name="Revise Coding Onboarding Prompts">
    <task id="1.1" title="Analyze Project Tech Stack">
        REVIEW codebase to IDENTIFY programming languages, frameworks, and libraries.
    </task>
    <task id="1.2" title="Understand Project Structure">
        ANALYZE project structure, design patterns, and code organization for cross-cutting concerns.
    </task>
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="1.3" title="Update Git Language Drivers">
        Based on the detected languages,
        UPDATE/CREATE .gitattributes file at the project root to set appropriate language drivers.
        For all the programming languages used in the project, follow this template for each language:
        ```
        *.<extension> diff=<language-driver>
        ```
    </task>
    <task id="1.4" title="Revise Coding Onboarding">
        IF backend exists: READ [ONBOARDING_CODING] and REVISE its task's content but respect existing structure for better agent guidance.
        NO Testing details should be added to coding onboarding prompts.
    </task>
    <task id="1.5" title="Revise Testing Onboarding">
        IF tests exist:
        EXPLORE project testing structure and IDENTIFY frameworks in use.
        READ [ONBOARDING_TESTING] and REVISE its task's content but respect existing structure for better agent guidance.
        ONLY Testing details should be added to testing onboarding prompt. No coding details should be added.
    </task>
    </parallel-group>
</phase>
<phase number="2" name="Revise Testing File Filter Patterns">
    <task id="2.1" title="Detect File Patterns">
        ANALYZE project structure: IDENTIFY primary language and framework conventions.
        LOCATE testing patterns from existing test files.
    </task>
    <task id="2.2" title="Filter by Semantic Roles">
        INCLUDE (Logic-Bearing):
        - Files with algorithms, control flow, state mutations, API handlers
        - Core domain logic (Services, Controllers, Reducers, Models with methods)
        - Utility scripts with data transformation
        EXCLUDE (Declarative & Static):
        - Type/Interface definitions
        - DTOs without behavior
    </task>
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="2.3" title="Update Testing File Filters">
        UPDATE Git filter to INCLUDE only testing file extensions/paths, EXCLUDE coding files in:
        - [PLAN_AND_IMPLEMENT_UNIT_TEST]
        - [PLAN_AND_IMPLEMENT_CODE_REVIEW_TESTING]
    </task>
    <task id="2.4" title="Update Coding Review File Filters">
        UPDATE Git filter to INCLUDE only logic-bearing source code paths, EXCLUDE test files in:
        - [PLAN_AND_IMPLEMENT_CODE_REVIEW_CODING]
        - [CREATE_PR]
    </task>
    </parallel-group>
</phase>
<phase number="3" name="Generate Project Convention Files">
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="3.1" title="Fill Coding Conventions">
        READ [CODING_CONVENTION_OUTPUT] and REPLACE [] placeholders with project conventions.
    </task>
    <task id="3.2" title="Fill Testing Conventions">
        READ [TESTING_CONVENTION_OUTPUT] and REPLACE [] placeholders with project conventions.
    </task>
    </parallel-group>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER COMPLETING all phases.
<task title="Execute Reflection Workflow">
    READ and FOLLOW [REFLECTION_SETUP]
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- SCAN entire codebase for pattern discovery
- DOCUMENT all discovered patterns
- APPLY correct filters for coding vs testing files
- NEVER modify core system files during analysis
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
