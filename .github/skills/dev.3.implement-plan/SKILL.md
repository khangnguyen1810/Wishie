---
name: dev.3.implement-plan
description: "Shard task context into individual files, auto-implement all tasks in parallel with production-ready quality, and commit."
argument-hint: "Optional: additional instructions or constraints"
user-invocable: true
disable-model-invocation: true
---

Automated Implementation Workflow

<roleContext>
YOU ARE an Expert Software Engineer Agent specialized in production-ready code implementation.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: SHARD task context into individual files, AUTO-IMPLEMENT all tasks in parallel with PRODUCTION-READY quality, and move completed tasks to complete/ directory.</primary>
<secondary>
    <goal>SHARD task context into individual task files for parallel processing</goal>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
    <goal>TRACK progress via file-based incomplete/ to complete/ movement</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Optional additional instructions or constraints
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_TASK_CONTEXT = task-context.md from Implementation Initialization task
SYSTEM_IMPLEMENTATION_DIR = parent directory of [SYSTEM_TASK_CONTEXT]
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.3.implement-plan.reflection.md`
SYSTEM_KNOWLEDGE_CODING = `.sdlc-workflows/artifacts/dev/docs/knowledge.coding.md`
</systemInput>

<output>
OUTPUT_INCOMPLETE_DIR = [SYSTEM_IMPLEMENTATION_DIR]/incomplete/
OUTPUT_COMPLETE_DIR = [SYSTEM_IMPLEMENTATION_DIR]/complete/
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
BEFORE STARTING: EXECUTE validation. STOP and REPORT if fails:
<task title="Implementation Initialization">
    EXECUTE below command with terminal tool:
    `sdlc-workflows implementation-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH]`
</task>
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase before proceeding:
<phase number="1" name="Implementation Execution">
    <task id="1.1" title="Shard Task Context">
        USE shard_markdown tool with heading level 1 to split [SYSTEM_TASK_CONTEXT] into [OUTPUT_INCOMPLETE_DIR].
    </task>
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent
    <task id="1.2" title="Subagent Implementation">
        For each file in [OUTPUT_INCOMPLETE_DIR] (excluding share-context.md):
        RUN sub-agent in parallel for each task with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-3-implement-plan",
            "description": "Implement <task_file_name>",
            "prompt": "EXECUTE with CONTEXT:
                USER_TASK_FILE: [OUTPUT_INCOMPLETE_DIR]/<task_file_name>
                USER_SHARED_CONTEXT: [OUTPUT_INCOMPLETE_DIR]/share-context.md
                USER_COMPLETE_DIR: [OUTPUT_COMPLETE_DIR]
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
</phase>
<phase number="2" name="Implementation Auditor">
    <task id="2.1" title="Run Implementation Auditor">
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
<phase number="3" name="Final Commit">
    <task id="3.1" title="Git Commit">
        RUN sub-agent with the EXACT prompt below.
        ```json
        {
            "agentName": "dev-git-commit",
            "description": "Git Commit",
            "prompt": "EXECUTE with CONTEXT:
                USER_COMMIT_MESSAGE: Implement | [short and concise task Name]
                USER_CHANGED_FILES: all unstaged changes"
        }
        ```
    </task>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER ALL phases:
<task title="Execute Reflection Workflow">
    READ and FOLLOW [SYSTEM_PROMPT_REFLECTION] workflow
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- MUST execute `implementation-init` command before working on workflowPhases
- Sub-agents MUST read share-context.md before implementing their task
- Blind fast writers MUST NOT build, lint, or git add
- Implementation auditor MUST achieve clean build before exiting
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
