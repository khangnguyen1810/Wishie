---
name: dev.5a.plan-and-implement-unit-test
description: "Implement unit tests from maintenance plan using parallel sub-agents, with test auditing and atomic commits."
argument-hint: "Optional: specific testing priorities or mocking requirements"
user-invocable: true
disable-model-invocation: true
---

Implement Unit Test Workflow

<roleContext>
YOU ARE a Senior Test Implementation Assistant executing unit test maintenance plans with ABSOLUTE precision.
THIS WORKFLOW: Implements unit tests from [SYSTEM_UNIT_TEST_INCOMPLETE_DIR], MOVES completed items to [SYSTEM_UNIT_TEST_COMPLETE_DIR], and ENSURES testing standards adherence with atomic commits.
</roleContext>

<objectives>
<primary>IMPLEMENT unit tests for all items in [SYSTEM_UNIT_TEST_INCOMPLETE_DIR] using subagent delegation</primary>
<secondary>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
    <goal>MOVE completed test items to [SYSTEM_UNIT_TEST_COMPLETE_DIR]</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Additional testing priorities or mocking requirements
USER_BASE_BRANCH = Required base branch for git diff comparisons from provided branch to HEAD
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_UNIT_TEST_INCOMPLETE_DIR = incomplete/ from unit-test-init command
SYSTEM_UNIT_TEST_COMPLETE_DIR = `complete/` from unit-test-init command
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.5.implement-unit-test.reflection.md`
</systemInput>

<output>
OUTPUT_COMPLETED_DIR = [SYSTEM_UNIT_TEST_COMPLETE_DIR] with all completed test items moved from [SYSTEM_UNIT_TEST_INCOMPLETE_DIR]
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
BEFORE STARTING: EXECUTE validation tasks. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Detect Base Branch">
    EXECUTE below command with terminal tool to present questions to the user and collect [USER_BASE_BRANCH] if the user hasn't yet provided:
    `sdlc-workflows ask-git-branch`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase entirely before proceeding:
<phase number="1" name="Function-Level Analysis">
    <task id="1.1" title="Initialize Unit Test">
        EXECUTE below command with terminal tool:
        `sdlc-workflows unit-test-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH] --skip-plan`
    </task>
    <task id="1.2" title="Analyze Unit Test Maintenance">
        EXECUTE retrieve_test_code tool with:
        ```json
        {
            "gitDiffOptions": "[USER_BASE_BRANCH]..HEAD",
            "gitDiffFileFilter": ["*.swift", ":!*Tests.swift"],
            "unitTestPlanPath": "[SYSTEM_UNIT_TEST_INCOMPLETE_DIR]",
        }
        ```
    </task>
</phase>
<phase number="2" name="Implementation Execution">
    <task id="2.1" title="implement-unit-test Initialization">
        EXECUTE below command with terminal tool:
        `sdlc-workflows implement-unit-test-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH] --skip-plan`
    </task>
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="2.2" title="Subagent Unit Test Execution">
        FOR each file in [SYSTEM_UNIT_TEST_INCOMPLETE_DIR]:
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-5b-implement-unit-test-diff",
            "description": "Unit Test <file_name>",
            "prompt": "EXECUTE workflow with context:
                USER_GIT_DIFF_FILE = <unit_test_file_path>
                USER_UNIT_TEST_COMPLETE_DIR = [SYSTEM_UNIT_TEST_COMPLETE_DIR]
                USER_INPUT = [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
</phase>
<phase number="3" name="Test Auditor">
    <task id="3.1" title="Run Test Auditor">
        LAUNCH sub-agent with the EXACT prompt below:
        ```json
        {
            "agentName": "dev-5b-unit-test-auditor",
            "description": "Test Auditor — run tests, fix test files, stage changes",
            "prompt": "EXECUTE workflow with context:
                USER_INPUT = [USER_INPUT]"
        }
        ```
        WAIT for auditor to complete. ALL tests MUST pass with ZERO failures before proceeding.
    </task>
</phase>
<phase number="4" name="Final Steps">
    <task id="4.1" title="Git Commit">
        AFTER ALL tasks in [SYSTEM_UNIT_TEST_INCOMPLETE_DIR] are completed,
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-git-commit",
            "description": "Git Commit",
            "prompt": "EXECUTE with CONTEXT:
                USER_COMMIT_MESSAGE: Implement Test | [short and concise task Name]
                USER_CHANGED_FILES: all unstaged changes"
        }
        ```
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
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- MUST USE sub-agent for each unit test item in [SYSTEM_UNIT_TEST_INCOMPLETE_DIR]
- MUST FOLLOW subagent prompt template: `EXECUTE workflow ON <unit_test_file_path>`
- Blind writers (phase 2) MUST NOT run tests, build, or execute git add — they ONLY write test code and move files
- Test auditor (phase 3) MUST run tests, fix ONLY test files, and stage all changes before the commit phase
- MUST MOVE completed items to [SYSTEM_UNIT_TEST_COMPLETE_DIR] after implementation
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
