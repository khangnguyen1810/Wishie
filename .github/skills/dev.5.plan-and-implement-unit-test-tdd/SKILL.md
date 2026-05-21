---
name: dev.5.plan-and-implement-unit-test-tdd
description: "End-to-end TDD unit test workflow: plan generation, auditing, sharding, user approval, parallel implementation, test verification, and commit."
argument-hint: "Optional: additional test requirements, focus areas, or constraints. OPTIONAL: --yolo to skip user approval gate (Phase 4)"
user-invocable: true
disable-model-invocation: true
---

# Plan and Implement Unit Test Workflow (TDD Approach)

<roleContext>
YOU ARE a Workflow Orchestrator for TDD unit test planning and implementation.
THIS WORKFLOW: Coordinates sub-agents to generate, audit, and shard a comprehensive unit test plan, then implements all test items with parallel sub-agents and ensures all tests pass.
</roleContext>

<objectives>
<primary>Orchestrate end-to-end TDD unit test workflow: plan generation, auditing, sharding, user approval, parallel implementation, and test verification</primary>
<secondary>
    <goal>LAUNCH generator sub-agent to derive test scenarios from planning documents</goal>
    <goal>LAUNCH auditor sub-agent to cross-reference and fix gaps in the generated plan</goal>
    <goal>SHARD the final plan and GET user approval before implementation</goal>
    <goal>LAUNCH implementation sub-agents CONCURRENTLY for each test shard</goal>
    <goal>LAUNCH test auditor sub-agent to verify ALL tests pass with ZERO failures</goal>
    <goal>COMMIT final implementation</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Optional test requirements, focus areas, or constraints
USER_FAST_MODE = Optional flag from argument-hint: if "--yolo" is present, skip Phase 4 approval gate only
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_TASK_CONTEXT = task-context.md from Initialization task
SYSTEM_VERIFICATION_CONTEXT_ACCEPTANCE = verification-context-acceptance.md from Initialization task
SYSTEM_VERIFICATION_CONTEXT_EDGECASE = verification-context-edgecase.md from Initialization task
SYSTEM_TESTING_CONVENTION = `.sdlc-workflows/artifacts/dev/docs/testing-convention.md`
SYSTEM_KNOWLEDGE_TESTING = `.sdlc-workflows/artifacts/dev/docs/knowledge.testing.md`
SYSTEM_PROMPT_REFLECTION_PLAN = `.sdlc-workflows/dev/reflections/dev.5.plan-unit-test-tdd.reflection.md`
SYSTEM_PROMPT_REFLECTION_IMPLEMENT = `.sdlc-workflows/dev/reflections/dev.5.implement-unit-test.reflection.md`
SYSTEM_PROMPT_GENERATE_VERIFICATION_CONTEXT = `.sdlc-workflows/dev/chains/generate-verification-context.prompt.md`
</systemInput>

<output>
OUTPUT_UNIT_TEST_PLAN = `unit-test.plan.md` from Initialization task
OUTPUT_SHARDING_INCOMPLETE_PATH = `incomplete/` from Initialization task
OUTPUT_SHARDING_COMPLETE_PATH = `complete/` from Initialization task
</output>

<executionFlow>
EXECUTION RULES:
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases in STRICT SEQUENTIAL order. NEVER skip or reorder phases. Each phase depends on prior phase output.
3. Within each phase, execute tasks in listed order UNLESS under <parallel-group>.
4. Tasks within a <parallel-group> MUST be launched CONCURRENTLY. Each task in a <parallel-group> is INDEPENDENT and can run simultaneously using sub-agent
5. INTEGRATE post-workflow tasks after all phases complete.
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation and setup. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="verify Initialization">
    READ and FOLLOW [SYSTEM_PROMPT_GENERATE_VERIFICATION_CONTEXT] with:
    - USER_CURRENT_GIT_BRANCH = [SYSTEM_CURRENT_GIT_BRANCH]
    - USER_INPUT = [USER_INPUT]
</task>
<task title="Initialize Unit Test TDD">
    EXECUTE with terminal tool:
    `sdlc-workflows unit-test-tdd-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH]`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase entirely before proceeding:

<phase number="1" name="Generate Test Plan">
    <task id="1.1" title="Launch Generator Sub-Agent">
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-5a-generate-test-plan-tdd",
            "description": "Generate TDD Test Plan",
            "prompt": "EXECUTE with
                USER_TASK_CONTEXT = [SYSTEM_TASK_CONTEXT]
                USER_VERIFICATION_CONTEXT_ACCEPTANCE = [SYSTEM_VERIFICATION_CONTEXT_ACCEPTANCE]
                USER_VERIFICATION_CONTEXT_EDGECASE = [SYSTEM_VERIFICATION_CONTEXT_EDGECASE]
                USER_TESTING_CONVENTION = [SYSTEM_TESTING_CONVENTION]
                USER_OUTPUT_FILE = [OUTPUT_UNIT_TEST_PLAN]
                USER_INPUT = [USER_INPUT]
            "
        }
        ```
        IF sub-agent reports violations: STOP and REPORT failures. DO NOT proceed to Phase 2.
    </task>
</phase>
<phase number="2" critical-step="true" name="User Approval Gate">
    <task id="2.0" title="Check Fast Mode">
        IF [USER_FAST_MODE] is set (i.e., "--yolo" was passed in the arguments):
        SKIP tasks 2.1 and 2.2 entirely and PROCEED directly to Phase 3.
    </task>
    <task id="2.1" title="Request User Approval">
        EXECUTE below command with terminal tool to present approval request to the user:
        `sdlc-workflows ask-questions --questions "Continue to implement the unit test plan?" --answers "Yes / No" --expect-answer "Your Answer: "`
    </task>
    <task id="2.2" title="Evaluate User Response">
        IF user answered "No" → STOP execution and EXIT workflow immediately.
        IF user answered "Yes" → PROCEED to Phase 3.
    </task>
</phase>
<phase number="3" name="Implementation Initialization">
    <task id="3.1" title="Initialize Implementation">
        EXECUTE below command with terminal tool:
        `sdlc-workflows implement-unit-test-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH]`
    </task>
</phase>
<phase number="4" name="Shard Test Plan">
    <task id="4.1" title="Shard Unit Test Plan">
        USE shard_markdown tool with heading level 3 to split [OUTPUT_UNIT_TEST_PLAN] into [OUTPUT_SHARDING_INCOMPLETE_PATH].
    </task>
</phase>
<phase number="5" name="Parallel Implementation">
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="5.1" title="Subagent Unit Test Execution">
        FOR each file in [OUTPUT_SHARDING_INCOMPLETE_PATH]:
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-5b-implement-unit-test-tdd",
            "description": "Unit Test <file_name>",
            "prompt": "EXECUTE workflow with context:
                USER_UNIT_TEST_INSTRUCTION_FILE = <unit_test_file_path>
                USER_UNIT_TEST_COMPLETE_DIR = [OUTPUT_SHARDING_COMPLETE_PATH]
                USER_INPUT = [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
</phase>
<phase number="6" name="Test Auditor">
    <task id="6.1" title="Run Test Auditor">
        LAUNCH sub-agent with the EXACT prompt below:
        ```json
        {
            "agentName": "dev-5b-unit-test-auditor",
            "description": "Test Auditor — run tests, fix test files, stage changes",
            "prompt": "EXECUTE workflow with context:
                USER_INPUT = 'IF TDD is in the RED phase, stop the auditor process and response with the reason.'"
        }
        ```
        WAIT for auditor to complete. ALL tests MUST pass with ZERO failures before proceeding.
    </task>
</phase>
<phase number="7" name="Final Commit">
    <task id="7.1" title="Git Commit">
        AFTER ALL tasks in [OUTPUT_SHARDING_INCOMPLETE_PATH] are completed,
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
AFTER COMPLETING all phases:
<task title="Execute Implementation Reflection">
    READ and FOLLOW [SYSTEM_PROMPT_REFLECTION_IMPLEMENT]
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- MUST execute `unit-test-tdd-init` command before working on workflowPhases
- MUST USE sub-agent for each unit test item in [OUTPUT_SHARDING_INCOMPLETE_PATH]
- MUST FOLLOW subagent prompt template: `EXECUTE workflow ON <unit_test_file_path>`
- MUST ADDRESS all findings from subagent reports using additional subagent executions
- MUST MOVE completed items to [OUTPUT_SHARDING_COMPLETE_PATH] after implementation
- MUST get user approval before proceeding to implementation (Phase 3) UNLESS USER_FAST_MODE is set
- MUST shard the plan AFTER implementation initialization (Phase 4) and BEFORE parallel implementation (Phase 5)
- Blind writers (Phase 5) MUST NOT run tests, build, or execute git add — they ONLY write test code and move files
- Test auditor MUST run tests, fix ONLY test files, and stage all changes before commit phase
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
