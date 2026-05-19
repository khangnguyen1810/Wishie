Verify and Resolve Scenarios Workflow

<roleContext>
YOU ARE an expert QA engineer specializing in implementation verification and acceptance testing.
THIS CHAIN: Shards verification scenarios into per-category files, verifies each category (concurrently for code-review/api-testing, sequentially for ui-testing), and resolves any failures.
</roleContext>

<objectives>
<primary>Generate, shard, verify, and resolve verification scenarios across acceptance and edge case categories using parallel sub-agents</primary>
<secondary>
    <goal>LAUNCH tasks within each <parallel-group> CONCURRENTLY — this is CRITICAL for performance</goal>
    <goal>SHARD verification context files into per-category files before verification</goal>
    <goal>For `code-review` and `api-testing`: verify ALL categories concurrently</goal>
    <goal>For `ui-testing`: verify ONE category at a time sequentially to avoid browser/UI conflicts</goal>
    <goal>Report verification failures with detailed context</goal>
    <goal>Address failures through corrective actions per category</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Additional user instructions or constraints (optional)
USER_TESTING_INFO = Testing context from upstream (server URL, application URL, etc.) (optional)
</userInput>

<systemInput>
SYSTEM_IMPLEMENTATION_PLAN = `implementation.plan.md` from verify-init command output
SYSTEM_CLARIFICATION_QUESTIONS = `clarification-questions.md` from verify-init command output
SYSTEM_ACCEPTANCE_CONTEXT = "verification-context-acceptance.md" from verify-init command output
SYSTEM_EDGECASE_CONTEXT = "verification-context-edgecase.md" from verify-init command output
SYSTEM_TASK_CONTEXT = Path to `task-context.md` from verify-init command output (optional)
SYSTEM_INCOMPLETE_DIR = `[SYSTEM_VERIFY_DIR]/incomplete/`
SYSTEM_PASSED_DIR = `[SYSTEM_VERIFY_DIR]/passed/`
SYSTEM_FAILED_DIR = `[SYSTEM_VERIFY_DIR]/failed/`
SYSTEM_KNOWLEDGE_CODING = `.sdlc-workflows/artifacts/dev/docs/knowledge.coding.md`
</systemInput>

<output>
OUTPUT_PASSED_DIR = [SYSTEM_PASSED_DIR] containing passed category files (acceptance + edgecase)
OUTPUT_FAILED_DIR = [SYSTEM_FAILED_DIR] containing failed category files, if any (acceptance + edgecase)
</output>


<executionFlow>
EXECUTION RULES:
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases in STRICT SEQUENTIAL order. NEVER skip or reorder phases UNLESS an <earlyExit> condition is met. Each phase depends on prior phase output.
3. Within each phase, execute tasks in listed order UNLESS under <parallel-group>.
4. Tasks within a <parallel-group> MUST be launched CONCURRENTLY. Each task in a <parallel-group> is INDEPENDENT and can run simultaneously using using sub-agent
5. INTEGRATE post-workflow tasks after all phases complete.
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation tasks in sequence. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
</preWorkflowTasks>


<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each phase before proceeding:
<phase number="1" name="Determine Verification Type">
    <task id="1.1" title="Determine Type from User Input">
        CHECK [USER_INPUT] for an explicit verification type keyword: `code-review`, `api-testing`, or `ui-testing`.
        - IF explicitly specified: USE that verification type.
        - IF NOT specified: CHECK [USER_TESTING_INFO] for context clues:
            - Contains a server URL or API endpoint reference → `api-testing`
            - Contains an application URL or web app reference → `ui-testing`
        - IF neither provides a type: DEFAULT to `code-review`.
    </task>
    <task id="1.2" title="Validate Testing Info for Non-Code-Review Types">
        IF determined type is `api-testing` or `ui-testing`:
        - EXTRACT the target URL from [USER_TESTING_INFO] first, then fall back to [USER_INPUT]
        - IF no target URL can be extracted from either source:
            STOP the workflow and ASK the user for the required testing info using the ask tool:
            - For `api-testing`: ask for the server URL (e.g., `http://localhost:3000`)
            - For `ui-testing`: ask for the application URL (e.g., `http://localhost:3000`)
            DO NOT fall back to `code-review` silently.
    </task>
    <task id="1.3" title="Store Results">
        STORE:
        - DETERMINED_VERIFICATION_TYPE = the resolved verification type
        - DETERMINED_TESTING_INFO = the extracted testing info (URL, etc.), or empty if code-review
    </task>
</phase>
<phase number="2" name="Shard Verification Contexts">
    <task id="2.1" title="Shard Acceptance Scenarios">
        USE shard_markdown tool with heading level 3 to split [SYSTEM_ACCEPTANCE_CONTEXT] into [SYSTEM_INCOMPLETE_DIR].
    </task>
    <task id="2.2" title="Shard Edge Case Scenarios">
        USE shard_markdown tool with heading level 3 to split [SYSTEM_EDGECASE_CONTEXT] into [SYSTEM_INCOMPLETE_DIR].
    </task>
</phase>
<phase number="3" name="Verify Per Category">
    SELECT the agent and execution strategy based on [DETERMINED_VERIFICATION_TYPE]:
    <task id="3.x-code-review" title="Verify ALL Categories Concurrently (code-review)">
        USE WHEN [DETERMINED_VERIFICATION_TYPE] = `code-review`.
        <parallel-group>
        LAUNCH ALL sub-agents concurrently — one per file in [SYSTEM_INCOMPLETE_DIR].
        RUN sub-agent with the EXACT prompt below (for EACH file in incomplete/).
        ```json
        {
            "agentName": "dev-3-verify-code-review",
            "description": "Verify Category [filename]",
            "prompt": "EXECUTE with CONTEXT:
                USER_CATEGORY_FILE: [SYSTEM_INCOMPLETE_DIR]/[filename]
                USER_PASSED_DIR: [SYSTEM_PASSED_DIR]
                USER_FAILED_DIR: [SYSTEM_FAILED_DIR]
                USER_INPUT: [USER_INPUT]
                USER_VERIFICATION_TYPE: [DETERMINED_VERIFICATION_TYPE]
                USER_TASK_CONTEXT: [SYSTEM_TASK_CONTEXT]"
        }
        ```
        </parallel-group>
    </task>
    <task id="3.x-api" title="Verify ALL Categories Concurrently (api-testing)">
        USE WHEN [DETERMINED_VERIFICATION_TYPE] = `api-testing`.
        <parallel-group>
        LAUNCH ALL sub-agents concurrently — one per file in [SYSTEM_INCOMPLETE_DIR].
        RUN sub-agent with the EXACT prompt below (for EACH file in incomplete/).
        ```json
        {
            "agentName": "dev-3-verify-manual",
            "description": "Verify Category [filename]",
            "prompt": "EXECUTE with CONTEXT:
                USER_CATEGORY_FILE: [SYSTEM_INCOMPLETE_DIR]/[filename]
                USER_PASSED_DIR: [SYSTEM_PASSED_DIR]
                USER_FAILED_DIR: [SYSTEM_FAILED_DIR]
                USER_INPUT: [USER_INPUT]
                USER_VERIFICATION_TYPE: [DETERMINED_VERIFICATION_TYPE]
                USER_TESTING_INFO: [DETERMINED_TESTING_INFO]"
        }
        ```
        </parallel-group>
    </task>
    <task id="3.x-ui" title="Verify Categories Sequentially (ui-testing)">
        USE WHEN [DETERMINED_VERIFICATION_TYPE] = `ui-testing`.
        EXECUTE ONE test case at a time — launch a sub-agent for each file in [SYSTEM_INCOMPLETE_DIR] SEQUENTIALLY. Wait for the current sub-agent to complete before launching the next.
        RUN sub-agent with the EXACT prompt below (for EACH file in incomplete/, one at a time).
        ```json
        {
            "agentName": "dev-3-verify-manual",
            "description": "Verify Category [filename]",
            "prompt": "EXECUTE with CONTEXT:
                USER_CATEGORY_FILE: [SYSTEM_INCOMPLETE_DIR]/[filename]
                USER_PASSED_DIR: [SYSTEM_PASSED_DIR]
                USER_FAILED_DIR: [SYSTEM_FAILED_DIR]
                USER_INPUT: [USER_INPUT]
                USER_VERIFICATION_TYPE: [DETERMINED_VERIFICATION_TYPE]
                USER_TESTING_INFO: [DETERMINED_TESTING_INFO]"
        }
        ```
    </task>
</phase>
<phase number="4" name="Parallel Resolve Failures">
    SKIP this phase if no failed files exist in [SYSTEM_FAILED_DIR].
    <parallel-group>
    LAUNCH ALL of the following tasks concurrently using sub-agent.
    FOR EACH file in [SYSTEM_FAILED_DIR], launch a sub-agent:
    <task id="4.x" title="Resolve Failure [filename]">
        RUN sub-agent with the EXACT prompt below (for EACH file in failed/).
        ```json
        {
            "agentName": "dev-3-resolve-failure-category",
            "description": "Resolve Failure [filename]",
            "prompt": "EXECUTE with CONTEXT:
                USER_FAILED_FILE: [SYSTEM_FAILED_DIR]/[filename]
                USER_PASSED_DIR: [SYSTEM_PASSED_DIR]
                USER_KNOWLEDGE_CODING: [SYSTEM_KNOWLEDGE_CODING]
                USER_INPUT: [USER_INPUT]"
        }
        ```
    </task>
    </parallel-group>
</phase>
</workflowPhases>

<constraints>
ABSOLUTE RESTRICTIONS - NEVER violate:
- **CRITICAL**: Tasks inside a <parallel-group> MUST be launched CONCURRENTLY using sub-agent — NEVER run them sequentially. This applies to ALL phases containing a <parallel-group>. Sequential execution of parallel-group tasks is a VIOLATION of this workflow.
- ALWAYS shard verification context files before verification
- ALWAYS launch ONE sub-agent PER category file for verification:
  - `code-review`: ALL concurrently (parallel-group)
  - `api-testing`: ALL concurrently (parallel-group)
  - `ui-testing`: ONE at a time sequentially — wait for each to complete before launching the next
- ALWAYS launch ONE sub-agent PER failed category file for resolution — ALL concurrently in a single parallel-group
- IF no failed files exist in [SYSTEM_FAILED_DIR] RETURN
- MUST use shard_markdown tool with heading level 3 for sharding
- MUST instruct generation sub-agents to use `### AC N:` / `### EC N:` heading format for categories
- MUST provide detailed failure reports and resolution attempts for all failed scenarios
- MUST ensure generated scenarios enforce test data isolation: each scenario uses unique, scenario-namespaced identifiers in Given preconditions — no shared mutable state across scenarios or categories
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
