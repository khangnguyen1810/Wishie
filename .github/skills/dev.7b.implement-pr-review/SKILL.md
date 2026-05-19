---
name: dev.7b.implement-pr-review
description: "Implement PR review feedback using parallel sub-agents, then commit the changes."
argument-hint: "Optional: additional context or priority for addressing PR feedback"
user-invocable: true
disable-model-invocation: true
---

Implement PR Review Workflow

<roleContext>
YOU ARE a Senior Software Engineer specializing in SRP, KISS, DRY, YAGNI, and SOLID principles.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: IMPLEMENT PR review feedback from [SYSTEM_SHARDING_INCOMPLETE_PATH] using sub-agent, then MOVE completed items to [SYSTEM_SHARDING_COMPLETE_PATH]</primary>
<secondary>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
    <goal>ENSURE all review items pass quality standards before completion</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Optional additional context or priority
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_SHARDING_INCOMPLETE_PATH = incomplete directory from implement-pr-review Initialization task
SYSTEM_SHARDING_COMPLETE_PATH = complete directory from implement-pr-review Initialization task
SYSTEM_PR_COMPLETE_PATH = `.sdlc-workflows/artifacts/dev/plans/[SYSTEM_CURRENT_GIT_BRANCH]/pull-request-plan/complete/`
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.7.implement-pr-review.reflection.md`
</systemInput>

<output>
OUTPUT_CODE_CHANGES = Code changes addressing all PR feedback
OUTPUT_COMPLETED_ITEMS = [SYSTEM_SHARDING_COMPLETE_PATH] with all items moved from [SYSTEM_SHARDING_INCOMPLETE_PATH]
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
<task title="implement-pr-review Initialization">
    EXECUTE below command with terminal tool:
    `sdlc-workflows implement-pr-review-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH]`
</task>
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase entirely before proceeding:
<phase number="1" name="Implementation Execution">
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="1.1" title="Subagent PR Review Execution">
        FOR each file in [SYSTEM_SHARDING_INCOMPLETE_PATH]:
        RUN sub-agent in parallel for each file with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-7b-implement-pr-feedback",
            "description": "Address PR Review <file_name>",
            "prompt": "EXECUTE workflow with context:
                USER_PR_REVIEW_FILE = <pr_review_file_path>
                USER_PR_COMPLETE_PATH = [SYSTEM_PR_COMPLETE_PATH]
                USER_INPUT = [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
    <task id="1.2" title="Self-Recovery">
        REVIEW each subagent report. LAUNCH additional sub-agent to ADDRESS findings or errors if needed.
    </task>
</phase>
<phase number="2" name="Final Commit">
    <task id="2.1" title="Git Commit">
        AFTER ALL tasks in [SYSTEM_SHARDING_INCOMPLETE_PATH] are completed,
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-git-commit",
            "description": "Git Commit",
            "prompt": "EXECUTE with CONTEXT:
                USER_COMMIT_MESSAGE: Fix Review | [short and concise task Name]
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
- MUST use sub-agent for each review item in [SYSTEM_SHARDING_INCOMPLETE_PATH]
- MUST follow subagent prompt template: `EXECUTE workflow ON <pr_review_file_path>`
- MUST address all subagent findings with additional executions if needed
- MUST move completed items to [SYSTEM_SHARDING_COMPLETE_PATH] immediately after implementation
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
