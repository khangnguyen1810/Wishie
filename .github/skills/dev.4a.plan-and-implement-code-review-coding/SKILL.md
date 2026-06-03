---
name: dev.4a.plan-and-implement-code-review-coding
description: "Plan and implement code review for coding files. Refactor code based on SRP, KISS, DRY, YAGNI, and SOLID principles using parallel blind fast writers."
argument-hint: "REQUIRED: the base branch for git diff comparisons from provided branch to HEAD. Optional: additional user inputs (coding standards focus areas, specific files to review)"
user-invocable: true
disable-model-invocation: true
---

Plan Self Review Workflow

<roleContext>
YOU ARE a Clean Code expert specializing in SRP, KISS, DRY, YAGNI, and SOLID principles.
THIS WORKFLOW: REFACTOR code based on items in [SYSTEM_REFACTOR_INCOMPLETE_DIR]
</roleContext>

<objectives>
<primary>GENERATE structured refactoring the code based on number of files changed in [SYSTEM_REFACTOR_INCOMPLETE_DIR]</primary>
<secondary>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = User additional inputs (coding standards focus areas, specific files to review)
USER_BASE_BRANCH = Required base branch for git diff comparisons for git diff comparisons from provided branch to HEAD
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_REFACTOR_INCOMPLETE_DIR = incomplete/ from implement-code-review Initialization task
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.4.implement-code-review.reflection.md`
SYSTEM_CODING_CONVENTION = `.sdlc-workflows/artifacts/dev/docs/coding-convention.md`
</systemInput>

<output>
OUTPUT_REFACTOR_PLAN = `code-review.plan.md` from `Initialize Code Review` task
OUTPUT_SHARDING_INCOMPLETE_PATH = `incomplete` folder from `Initialize Code Review` task
OUTPUT_SHARDING_COMPLETE_PATH = `complete` folder from `Initialize Code Review` task
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
BEFORE STARTING: EXECUTE validation/setup tasks. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Detect Base Branch">
    EXECUTE below command with terminal tool to present questions to the user and collect [USER_BASE_BRANCH] if the user hasn't yet provided:
    `sdlc-workflows ask-git-branch`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each entirely before proceeding:
<phase number="1" name="Identify changed code">
    <task id="1.1" title="Initialize Code Review">
        EXECUTE below command with terminal tool:
        `sdlc-workflows code-review-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH] --skip-plan`
    </task>
    <task id="1.2" title="Identify changes">
        EXECUTE retrieve_new_changes tool with:
        ```json
        {
            "gitDiffOptions": "[USER_BASE_BRANCH]..HEAD",
            "gitDiffFileFilter": ["*.swift", ":!*Tests.swift"],
            "codeReviewPlanPath": "[OUTPUT_REFACTOR_PLAN]"
        }
        ```
    </task>
</phase>
<phase number="2" name="Parallel Blind Fast Writers">
    <task id="2.1" title="Prepare for Implementation">
        EXECUTE below command with terminal tool:
        `sdlc-workflows implement-code-review-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH]`
        If the command failed, do phase 1 again to ensure the plan is properly generated and sharded.
    </task>
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="2.2" title="Parallel Blind Fast Writer Refactoring">
        FOR each file in [SYSTEM_REFACTOR_INCOMPLETE_DIR]
        RUN sub-agent in parallel for each file with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-4b-implement-code-review",
            "description": "Refactor <file_name>",
            "prompt": "EXECUTE workflow with context:
                USER_REFACTOR_FILE = <refactor_file_path>
                USER_CONVENTION = [SYSTEM_CODING_CONVENTION]
                USER_COMPLETE_DIR = [OUTPUT_SHARDING_COMPLETE_PATH]
                USER_INPUT = [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
</phase>
<phase number="3" name="Parallel Implementation Auditors">
    <task id="3.1" title="Parallel Auditor Execution">
        RUN sub-agent in parallel for each file with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-4b-code-review-auditor",
            "description": "Audit & Fix <file_name>",
            "prompt": "EXECUTE workflow with context:
                USER_INPUT = [USER_INPUT]
                USER_CONVENTION = [SYSTEM_CODING_CONVENTION]"
        }
        ```
    </task>
</phase>
<phase number="4" name="Final Commit">
    <task id="4.1" title="Git Commit">
        AFTER ALL tasks in [SYSTEM_REFACTOR_INCOMPLETE_DIR] are completed,
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-git-commit",
            "description": "Git Commit",
            "prompt": "EXECUTE with CONTEXT:
                USER_COMMIT_MESSAGE: Refactor | [short and concise task Name]
                USER_CHANGED_FILES: all unstaged changes"
        }
        ```
    </task>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER COMPLETING all phases.
<task title="Execute Reflection">
    READ and FOLLOW [SYSTEM_PROMPT_REFLECTION]
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- MUST use [USER_BASE_BRANCH]..HEAD for git diff comparisons
- MUST verify [OUTPUT_REFACTOR_PLAN] updated after analysis
- MUST shard all items into [OUTPUT_SHARDING_INCOMPLETE_PATH]
- Blind fast writers MUST NOT build, lint, or git add
- Blind fast writers MUST move completed files from incomplete/ to complete/
- Implementation auditors MUST verify build passes before staging
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
