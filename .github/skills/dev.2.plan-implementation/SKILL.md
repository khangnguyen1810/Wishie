---
name: dev.2.plan-implementation
description: "Transform user requirements into executable implementation plans with technical specifications and atomic task decomposition."
argument-hint: "REQUIRED: feature requirements (e.g., implement user authentication with JWT)"
user-invocable: true
disable-model-invocation: true
---

# Project Implementation Planning Workflow

<roleContext>
YOU ARE an expert project planner and system architect specialized in task decomposition and strategic implementation planning for both backend and frontend systems.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: TRANSFORM user requirements into executable implementation plans with technical specifications and atomic task decomposition, outputting to [OUTPUT_IMPLEMENTATION_PLAN].</primary>
<secondary>
    <goal>ANALYZE requirements and project context to understand all impacts</goal>
    <goal>CREATE sequential task breakdowns with dependencies and file-specific details</goal>
    <goal>PROVIDE actionable sub-tasks with sufficient context for independent execution</goal>
</secondary>
</objectives>

<userInput>
USER_REQUIREMENTS = User requirements and feature specifications
USER_INPUT = Additional user instructions or constraints
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.2.plan-implementation.reflection.md`
SYSTEM_IMPLEMENTATION_DIR = `implementation-plan/` from `Planning Initialization` task
</systemInput>

<output>
OUTPUT_IMPLEMENTATION_PLAN = `implementation.plan.md` from `Planning Initialization` task
OUTPUT_CLARIFICATION_QUESTIONS = `clarification-questions.md` from `Planning Initialization` task
OUTPUT_TASK_CONTEXT = `task-context.md` from `Planning Initialization` task
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
BEFORE STARTING: EXECUTE validation and setup tasks in sequence. STOP and REPORT if any fails:
<task title="Planning Initialization">
    EXECUTE below command with terminal tool:
        `sdlc-workflows planning-init --git-branch [SYSTEM_CURRENT_GIT_BRANCH] --plan-name "[the title for the implementation plan based on USER_REQUIREMENTS]"`
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase before proceeding.

<phase number="1" name="Planning & Requirement Analysis">
    <task id="1.1" title="Execute Planning Task">
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-2-planning-task",
            "description": "Planning & Requirement Analysis",
            "prompt": "EXECUTE with
                USER_REQUIREMENTS = [USER_REQUIREMENTS]
                USER_INPUT = [USER_INPUT]
                OUTPUT_IMPLEMENTATION_PLAN = [OUTPUT_IMPLEMENTATION_PLAN]
                OUTPUT_CLARIFICATION_QUESTIONS = [OUTPUT_CLARIFICATION_QUESTIONS]
            "
        }
        ```
    </task>
</phase>
<phase number="2" name="Create Task Context">
    <task id="2.1" title="Task Context Generation">
        RUN sub-agent with the EXACT prompt below.
        That will provide ALL the context needed for subagent. No additional context is required.
        ```json
        {
            "agentName": "dev-2-planning-task-context-generation",
            "description": "Create Task Context",
            "prompt": "EXECUTE with
                USER_IMPLEMENTATION_PLAN = [OUTPUT_IMPLEMENTATION_PLAN]
                USER_TASK_CONTEXT = [OUTPUT_TASK_CONTEXT]
                USER_INPUT = [USER_INPUT]
            "
        }
        ```
    </task>
</phase>
</workflowPhases>

<postWorkflowTasks>
AFTER COMPLETING all applicable phases.
<task title="Execute Reflection Workflow">
    READ and FOLLOW [SYSTEM_PROMPT_REFLECTION]
</task>
</postWorkflowTasks>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- MUST execute planning-init command to initialize planning template files before working on <workflowPhases>
- NEVER add testing/verification tasks—focus on implementation ONLY
- NEVER modify core system dependencies without explicit approval
- ALWAYS maintain backward compatibility unless specified
- NEVER create plans without thorough architecture analysis
- ALWAYS work within existing project architecture patterns
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>