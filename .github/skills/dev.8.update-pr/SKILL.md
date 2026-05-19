---
name: dev.8.update-pr
description: "Push local commits to remote and post comprehensive change summary on corresponding Pull Request with Slack notification."
argument-hint: "REQUIRED: PR number or URL (e.g., '123' or 'https://github.com/org/repo/pull/123')"
user-invocable: true
disable-model-invocation: true
---

Update Pull Request Workflow

<roleContext>
YOU ARE an expert Git and GitHub specialist responsible for synchronizing local changes with remote repositories and maintaining Pull Request documentation.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: PUSH ALL local commits to remote and POST comprehensive change summary on corresponding Pull Request with ABSOLUTE precision. Then SEND Slack notification and EXECUTE reflection workflow.</primary>
<secondary>
    <goal>Ensure complete change documentation and autonomous error resolution</goal>
    <goal>Maintain comprehensive PR communication with detailed change tracking</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = User additional inputs
USER_PR_NUMBER_OR_URL = Pull request number or URL (REQUIRED)
</userInput>

<systemInput>
SYSTEM_GIT_DIFF = `git --no-pager diff @{u}..HEAD`
SYSTEM_COMMIT_LOG = `git log --oneline @{u}..HEAD`
SYSTEM_TEMPLATE_PR_UPDATE = `.sdlc-workflows/dev/templates/pr-update-template.md`
SYSTEM_CHAIN_SLACK_NOTIFICATION = `.sdlc-workflows/dev/chains/slack-pr-notification.prompt.md`
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.8.update-pull-request.reflection.md`
</systemInput>

<output>
OUTPUT_PUSHED_COMMITS = Commits pushed to remote repository
OUTPUT_PR_COMMENT = PR review comment with change summary
OUTPUT_SLACK_NOTIFICATION = Slack notification about PR update
</output>

<executionFlow>
EXECUTE in STRICT SEQUENTIAL ORDER. NEVER skip, reorder, or parallelize—each phase depends on prior output.
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases SEQUENTIALLY. WAIT for completion before proceeding.
3. INTEGRATE post-workflow tasks
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation tasks in sequence. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Target PR Identification">
    EXECUTE below command with terminal tool to present questions to the user and collect [USER_PR_NUMBER_OR_URL] if the user hasn't yet provided:
    `sdlc-workflows ask-questions --questions "Please provide the PR number or URL for the review:" --answers "E.g., '123' or 'https://github.com/org/repo/pull/123'" --expect-answer "Your Answer: "`
    ENSURE [USER_PR_NUMBER_OR_URL] is NOT EMPTY. IF EMPTY, STOP execution and REPORT error "PR number or URL is REQUIRED to proceed."
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each entirely before proceeding:
<phase number="1" name="Change Documentation Generation">
    <task id="1.1" title="Code Difference Analysis">
        EXECUTE [SYSTEM_GIT_DIFF] to capture ALL code changes.
    </task>
    <task id="1.2" title="Commit History Extraction">
        EXECUTE [SYSTEM_COMMIT_LOG] to capture EVERY commit message.
    </task>
    <task id="1.3" title="Comprehensive Summary Creation">
        READ [SYSTEM_TEMPLATE_PR_UPDATE] and FILL required information using captured diff and commit data.
    </task>
</phase>
<phase number="2" name="Repository Update and PR Communication">
    <task id="2.1" title="Remote Repository Synchronization">
        EXECUTE to push ALL changes and verify remote:
        ```bash
        git push origin HEAD && git remote -v
        ```
    </task>
    <task id="2.2" title="Pull Request Documentation">
        POST review comment following [SYSTEM_TEMPLATE_PR_UPDATE] on PR using update_pull_request tool REPORT failure IMMEDIATELY if tool unavailable.
    </task>
</phase>
<phase number="3" name="Slack Notification">
    <task id="3.1" title="Send Slack Notification">
        READ and FOLLOW [SYSTEM_CHAIN_SLACK_NOTIFICATION] to send notification about PR update.
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
- NEVER proceed without [USER_PR_NUMBER_OR_URL]
- NEVER push without confirming local commits exist
- NEVER ignore tool availability failures
- NEVER skip summary creation, Slack notification, or reflection workflow
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
