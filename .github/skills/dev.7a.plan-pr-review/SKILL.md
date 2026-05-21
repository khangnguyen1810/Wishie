---
name: dev.7a.plan-pr-review
description: "Analyze pull request changes, generate contextual review comments, and organize solutions for systematic resolution."
argument-hint: "REQUIRED: PR number or URL (e.g., '123' or 'https://github.com/org/repo/pull/123')"
user-invocable: true
disable-model-invocation: true
---

Plan PR Review Workflow

<roleContext>
YOU ARE an expert software engineer specializing in PR review analysis and systematic feedback resolution.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: Analyze pull request changes, generate contextual review comments, and organize solutions for systematic resolution</primary>
<secondary>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
    <goal>Process all code changes comprehensively and deliver actionable feedback organized by review category</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Additional user instructions
USER_PR_NUMBER_OR_URL = Pull request number or URL (REQUIRED)
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.7.plan-pr-review.reflection.md`
</systemInput>

<output>
OUTPUT_PR_PLAN = `pull-request.plan.md` from `Initialize PR Plan` task'
OUTPUT_SHARDING_INCOMPLETE_PATH = `/incomplete` folder from `Initialize PR Plan` task
OUTPUT_SHARDING_COMPLETE_PATH = `/complete` folder from `Initialize PR Plan` task
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
BEFORE STARTING: EXECUTE validation tasks. STOP if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Validate PR Identifier">
    EXECUTE below command with terminal tool to present questions to the user and collect [USER_PR_NUMBER_OR_URL] if the user hasn't yet provided:
    `sdlc-workflows ask-questions --questions "Please provide the PR number or URL for the review:" --answers "E.g., '123' or 'https://github.com/org/repo/pull/123'" --expect-answer "Your Answer: "`
    ENSURE [USER_PR_NUMBER_OR_URL] is NOT EMPTY. IF EMPTY, STOP execution and REPORT error "PR number or URL is REQUIRED to proceed."
</task>
<task title="Initialize PR Plan">
    EXECUTE below command with terminal tool:
    `sdlc-workflows pr-plan-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH]`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each before proceeding:
<phase number="1" name="Context Acquisition and Plan Generation">
    <task id="1.1" title="Execute Context Acquisition Subagent">
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-7a-context-acquisition",
            "description": "Pull PR comments",
            "prompt": "EXECUTE with context:
                USER_PR_NUMBER_OR_URL = [USER_PR_NUMBER_OR_URL]
                USER_PR_PLAN = [OUTPUT_PR_PLAN]
                USER_INPUT = [USER_INPUT]
            EXPECT: Status report confirming plan file written successfully or error details"
        }
        ```
    </task>
</phase>
<phase number="2" name="Shard Plan Directory">
    <task id="2.1" title="Shard Pull Request Plan">
        USE shard_markdown tool with heading level 3 to split [OUTPUT_PR_PLAN] into individual files in [OUTPUT_SHARDING_INCOMPLETE_PATH].
    </task>
</phase>
<phase number="3" name="Status Analysis and Solution Generation">
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="3.1" title="Generate Solution For The Plan File">
        FOR each file in [OUTPUT_SHARDING_INCOMPLETE_PATH]:
        RUN sub-agent in parallel for each file with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-7-pr-review-solutions",
            "description": "Generate Solution Comments on <file_name>",
            "prompt": "EXECUTE workflow with context:
                USER_FILE_PATH = <file_path>
                USER_INPUT = [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER COMPLETING all phases.
<task title="Execute Reflection">
    READ and FOLLOW [SYSTEM_PROMPT_REFLECTION]
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS:
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- NEVER proceed without [USER_PR_NUMBER_OR_URL]
- NEVER skip context acquisition sub-agent
- NEVER skip "Shard Plan Directory" phase
- NEVER skip PR comment solutions sub-agent execution
- ENSURE process all sharded files completely in [OUTPUT_SHARDING_INCOMPLETE_PATH]
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
