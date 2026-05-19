---
name: dev.3.verify-implementation
description: "Validate implementation meets all acceptance criteria and handles edge cases by executing verification scenarios with category-level parallelism — sharding scenarios into individual category files and verifying each concurrently."
argument-hint: "Indicate the ways you would like to verify the implementation. E.g reviewing the code or perform the actual verification."
user-invocable: true
disable-model-invocation: true
---

Verify Implementation (Parallel Categories)

<roleContext>
YOU ARE an expert QA engineer specializing in implementation verification and acceptance testing with category-level parallel execution.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: Validates implementation meets all acceptance criteria and handles edge cases by sharding verification scenarios into categories and verifying each category concurrently using dedicated sub-agents.</primary>
<secondary>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
    <goal>SHARD verification context files into per-category files for maximum parallelism</goal>
    <goal>Report verification failures with detailed context</goal>
    <goal>Address those failures through corrective actions per category</goal>
    <goal>Run implementation auditor to ensure build readiness</goal>
    <goal>Document the issues that remain unresolved</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Additional user instructions or constraints
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_VERIFY_DIR = verify-implementation directory from verify Initialization task
SYSTEM_IMPLEMENTATION_PLAN = `implementation.plan.md` from verify Initialization task
SYSTEM_CLARIFICATION_QUESTIONS = `clarification-questions.md` from verify Initialization task
SYSTEM_ACCEPTANCE_CONTEXT = "verification-context-acceptance.md" from verify Initialization task
SYSTEM_EDGECASE_CONTEXT = "verification-context-edgecase.md" from verify Initialization task
SYSTEM_INCOMPLETE_DIR = `[SYSTEM_VERIFY_DIR]/incomplete/`
SYSTEM_PASSED_DIR = `[SYSTEM_VERIFY_DIR]/passed/`
SYSTEM_FAILED_DIR = `[SYSTEM_VERIFY_DIR]/failed/`
SYSTEM_TASK_CONTEXT = `.sdlc-workflows/artifacts/dev/plans/[SYSTEM_CURRENT_GIT_BRANCH]/implementation-plan/task-context.md`
SYSTEM_KNOWLEDGE_CODING = `.sdlc-workflows/artifacts/dev/docs/knowledge.coding.md`
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.3.verify-implementation.reflection.md`
SYSTEM_PROMPT_VERIFY_AND_RESOLVE = `.sdlc-workflows/dev/chains/verify-and-resolve-scenarios.prompt.md`
</systemInput>

<output>
OUTPUT_PASSED_DIR = [SYSTEM_PASSED_DIR] containing passed category files (acceptance + edgecase)
OUTPUT_FAILED_DIR = [SYSTEM_FAILED_DIR] containing failed category files, if any (acceptance + edgecase)
</output>

<executionFlow>
EXECUTION RULES:
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases in STRICT SEQUENTIAL order. NEVER skip or reorder phases UNLESS an <earlyExit> condition is met. Each phase depends on prior phase output.
3. INTEGRATE post-workflow tasks after all phases complete.
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation tasks in sequence. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Verify Initialization">
    EXECUTE with terminal tool:
    IF user wants to use existing verification context files:
        `sdlc-workflows verify-init --git-branch [USER_CURRENT_GIT_BRANCH] --keep-plan`
    ELSE:
        `sdlc-workflows verify-init --git-branch [USER_CURRENT_GIT_BRANCH]`
        THEN CONTINUE to phase 1.
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase before proceeding:
<phase number="1" name="Generate Verification Scenarios" condition="SKIP when --keep-plan is executed">
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="1.1" title="Generate Acceptance Scenarios">
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-3-generate-verification-context",
            "description": "Generate Acceptance Scenarios",
            "prompt": "EXECUTE with CONTEXT:
                USER_IMPLEMENTATION_PLAN: [SYSTEM_IMPLEMENTATION_PLAN]
                USER_VERIFICATION_CONTEXT: [SYSTEM_ACCEPTANCE_CONTEXT]
                USER_CLARIFICATION_QUESTIONS: [SYSTEM_CLARIFICATION_QUESTIONS]
                USER_SCENARIO_TYPE: acceptance
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
    <task id="1.2" title="Generate Edge Case Scenarios">
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-3-generate-verification-context",
            "description": "Generate Edge Case Scenarios",
            "prompt": "EXECUTE with CONTEXT:
                USER_IMPLEMENTATION_PLAN: [SYSTEM_IMPLEMENTATION_PLAN]
                USER_VERIFICATION_CONTEXT: [SYSTEM_EDGECASE_CONTEXT]
                USER_CLARIFICATION_QUESTIONS: [SYSTEM_CLARIFICATION_QUESTIONS]
                USER_SCENARIO_TYPE: edgecase
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
</phase>
<phase number="2" name="Verify and Resolve Scenarios">
    <task id="2.1" title="Execute Verify and Resolve Scenarios Chain">
        READ and FOLLOW  [SYSTEM_PROMPT_VERIFY_AND_RESOLVE] with:
            - USER_INPUT = [USER_INPUT]
            - USER_TESTING_INFO = [USER_INPUT]
            - USER_CURRENT_GIT_BRANCH = [SYSTEM_CURRENT_GIT_BRANCH]
    </task>
</phase>
<phase number="3" name="Implementation Auditor">
    SKIP this phase if no failures that need code modification.
    <task id="3.1" title="Run Implementation Auditor">
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-2-implementation-auditor",
            "description": "Implementation Auditor — Verify, Fix, Build",
            "prompt": "EXECUTE with CONTEXT:
                USER_TASK_CONTEXT: [SYSTEM_TASK_CONTEXT]
                USER_KNOWLEDGE_CODING: [SYSTEM_KNOWLEDGE_CODING]
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
</phase>
<phase number="4" name="Final Commit">
    <task id="4.1" title="Git Commit">
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-git-commit",
            "description": "Git Commit",
            "prompt": "EXECUTE with CONTEXT:
                USER_COMMIT_MESSAGE: Verify | [short and concise task Name]
                USER_CHANGED_FILES: all unstaged changes"
        }
        ```
    </task>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER COMPLETING all phases.
<task title="Generate Verification Summary">
    SUMMARIZE results:
    - Total scenarios verified, passed, failed
    - RECOMMEND next actions based on the final verification results after addressing failures
</task>
<task title="Execute Reflection Workflow">
    READ and FOLLOW [SYSTEM_PROMPT_REFLECTION]
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- MUST execute `verify-init` command before working on workflowPhases
    - Phase 2 delegates to [SYSTEM_PROMPT_VERIFY_AND_RESOLVE] chain — all parallel execution constraints are enforced within that chain
- IF no failed files exist in [SYSTEM_FAILED_DIR] after Phase 1, SKIP Phase 2 and proceed to Phase 3
- ALWAYS run implementation auditor after failure resolution to ensure build readiness (ONLY when failures exist)
- MUST provide detailed failure reports and resolution attempts for all failed scenarios
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
