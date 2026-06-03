---
name: dev.2.plan-and-implement-task
description: "Full plan-and-implement workflow: transforms requirements into verified implementation with planning, user approval, parallel implementation, delegated verification via chain prompt, auditing, and commit."
argument-hint: "REQUIRED: feature requirements (e.g., implement user authentication with JWT). OPTIONAL: --yolo to skip user approval gate (phase 2)."
user-invocable: true
disable-model-invocation: true
---

# Plan and Implement Task Workflow

<roleContext>
YOU ARE an Expert Software Engineer and System Architect specialized in end-to-end feature delivery — from requirements analysis and implementation planning through production-ready code implementation, verification, and commit.
</roleContext>

<objectives>
<primary>TRANSFORM user requirements into a complete, verified implementation: plan the work, get user approval, implement in parallel with blind fast writers, verify implementation via delegated chain, audit, and commit — all in a single automated workflow.</primary>
<secondary>
    <goal>DECOMPOSE plans into atomic, independently executable tasks with authoritative shared contracts</goal>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
    <goal>IMPLEMENT all tasks in parallel using blind fast writer sub-agents for maximum throughput</goal>
    <goal>AUDIT implementation with a dedicated auditor that verifies, fills integration gaps, and achieves build readiness</goal>
    <goal>VERIFY implementation against acceptance and edge case scenarios via delegated chain</goal>
    <goal>COMMIT verified implementation with proper git conventions</goal>
</secondary>
</objectives>
<userInput>
USER_REQUIREMENTS = User requirements and feature specifications
USER_INPUT = Additional user instructions or constraints
USER_FAST_MODE = Optional flag from argument-hint: if "--yolo" is present, skip Phase 2 approval gate only
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_IMPLEMENTATION_DIR = `implementation-plan/` from `Planning Initialization` task
SYSTEM_KNOWLEDGE_CODING = `.sdlc-workflows/artifacts/dev/docs/knowledge.coding.md`
SYSTEM_PROMPT_GENERATE_VERIFICATION_CONTEXT = `.sdlc-workflows/dev/chains/generate-verification-context.prompt.md`
SYSTEM_PROMPT_VERIFY_AND_RESOLVE = `.sdlc-workflows/dev/chains/verify-and-resolve-scenarios.prompt.md`
</systemInput>

<output>
OUTPUT_IMPLEMENTATION_PLAN = `implementation.plan.md` from `Planning Initialization` task
OUTPUT_TASK_CONTEXT = `task-context.md` from `Planning Initialization` task
OUTPUT_INCOMPLETE_DIR = [SYSTEM_IMPLEMENTATION_DIR]/incomplete/
OUTPUT_COMPLETE_DIR = [SYSTEM_IMPLEMENTATION_DIR]/complete/
</output>

<executionFlow>
EXECUTION RULES:
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases in STRICT SEQUENTIAL order. NEVER skip or reorder phases. Each phase depends on prior phase output.
3. Within each phase, execute tasks in listed order UNLESS under <parallel-group>.
4. Tasks within a <parallel-group> MUST be launched CONCURRENTLY. Each task in a <parallel-group> is INDEPENDENT and can run simultaneously using sub-agent
5. AFTER all phases complete, EXECUTE reflection validation from .sdlc-workflows/dev/reflections/dev.2.plan-and-implement-task.reflection.md
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation and setup tasks. STOP and REPORT if any fails:
<task title="Planning Initialization">
    EXECUTE below command with terminal tool:
        `sdlc-workflows planning-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH] --plan-name "[the title for the implementation plan based on USER_REQUIREMENTS]"`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase before proceeding:

<phase number="1" name="Combined Planning & Task Context Generation">
    <task id="1.1" title="Combined Planning & Task Context Sub-agent">
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-2-planning-and-task-context",
            "description": "Combined Planning & Task Context Generation",
            "prompt": "EXECUTE with CONTEXT:
                USER_REQUIREMENTS: [USER_REQUIREMENTS]
                USER_IMPLEMENTATION_PLAN: [OUTPUT_IMPLEMENTATION_PLAN]
                USER_TASK_CONTEXT: [OUTPUT_TASK_CONTEXT]
                USER_KNOWLEDGE_CODING: [SYSTEM_KNOWLEDGE_CODING]
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
</phase>
<phase number="2" critical-step="true" name="User Approval Gate">
    <task id="2.0" title="Check Fast Mode">
        IF [USER_FAST_MODE] is set (i.e., "--yolo" was passed in the arguments):
        SKIP tasks 2.1 and 2.2 entirely and PROCEED directly to Phase 3.
    </task>
    <task id="2.1" title="Request User Approval">
        EXECUTE below command with terminal tool to present approval request to the user:
        `sdlc-workflows ask-questions --questions "Continue to implement the plan?" --answers "Yes / No" --expect-answer "Your Answer: "`
    </task>
    <task id="2.2" title="Evaluate User Response">
        IF user answered "No" → STOP execution and EXIT workflow immediately.
        IF user answered "Yes" → PROCEED to Phase 3.
    </task>
</phase>
<phase number="3" name="Parallel Implementation">
    <task id="3.1" title="Implementation Initialization">
        EXECUTE below command with terminal tool:
        `sdlc-workflows implementation-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH]`
    </task>
    <task id="3.2" title="Shard Task Context">
        USE shard markdown tool with heading level 1 to split [OUTPUT_TASK_CONTEXT] into [OUTPUT_INCOMPLETE_DIR].
    </task>
    <task id="3.3" title="Parallel Blind Fast Writer Implementation">
        FOR each file in [OUTPUT_INCOMPLETE_DIR] (excluding share-context.md):
        RUN sub-agent in parallel for each task with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-2-implement-task",
            "description": "Implement <task_file_name>",
            "prompt": "EXECUTE with CONTEXT:
                USER_TASK_FILE: [OUTPUT_INCOMPLETE_DIR]/<task_file_name>
                USER_SHARED_CONTEXT: [OUTPUT_INCOMPLETE_DIR]/share-context.md
                USER_COMPLETE_DIR: [OUTPUT_COMPLETE_DIR]
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
</phase>
<phase number="4" name="Verify and Resolve Scenarios">
    <task id="4.1" title="Generate Verification Context">
        READ and FOLLOW [SYSTEM_PROMPT_GENERATE_VERIFICATION_CONTEXT] with:
            - USER_CURRENT_GIT_BRANCH = [SYSTEM_CURRENT_GIT_BRANCH]
            - USER_INPUT = [USER_INPUT]
    </task>
    <task id="4.2" title="Execute Verify and Resolve Chain">
        READ and FOLLOW [SYSTEM_PROMPT_VERIFY_AND_RESOLVE] with:    
            - USER_INPUT = [USER_INPUT]
            - USER_TESTING_INFO = only code review performed in this phase
            - USER_CURRENT_GIT_BRANCH = [SYSTEM_CURRENT_GIT_BRANCH]
    </task>
</phase>
<phase number="5" name="Implementation Auditor">
    SKIP if no failures needing code modification after Phase 4.
    <task id="5.1" title="Run Implementation Auditor">
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-2-implementation-auditor",
            "description": "Implementation Auditor — Verify, Fix, Build",
            "prompt": "EXECUTE with CONTEXT:
                USER_KNOWLEDGE_CODING: [SYSTEM_KNOWLEDGE_CODING]
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
</phase>
<phase number="6" name="Final Commit">
    <task id="6.1" title="Git Commit">
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-git-commit",
            "description": "Git Commit",
            "prompt": "EXECUTE with CONTEXT:
                USER_COMMIT_MESSAGE: Implement | [short and concise task name based on USER_REQUIREMENTS]
                USER_CHANGED_FILES: all unstaged changes"
        }
        ```
    </task>
</phase>
</workflowPhases>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- MUST execute planning-init command to initialize planning template files before working on workflowPhases
- MUST get user approval before proceeding to implementation (Phase 2) UNLESS USER_FAST_MODE is set
- NEVER add testing/verification tasks to task-context.md — focus on implementation ONLY
- NEVER modify core dependencies without explicit approval
- ALWAYS work within existing architecture patterns
- MUST process tasks in parallel where specified using sub-agent
- Sub-agents MUST read share-context.md before implementing their task

- Blind fast writers MUST NOT build, lint, or git add
- Implementation auditor MUST achieve clean build before exiting
- Phase 4 delegates to [SYSTEM_PROMPT_VERIFY_AND_RESOLVE] chain — all verification constraints are enforced within that chain
- SKIP Phase 5 (Auditor) if no failures that need code modification after Phase 4
- MUST run implementation auditor ONLY ONCE at the end (Phase 5) — after all implementation and failure resolution — to ensure build readiness before commit
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
