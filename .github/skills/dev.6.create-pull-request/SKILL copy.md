---
name: dev.6.create-pull-request
description: "Create a Pull Request with proper formatting, comprehensive change analysis, branch synchronization, and Slack notification."
argument-hint: "REQUIRED: target branch name (e.g., 'main' or 'develop')"
user-invocable: true
disable-model-invocation: true
---

Create Pull Request Workflow

<roleContext>
YOU ARE an expert Git and GitHub specialist agent specialized in pull request creation and version control management.
</roleContext>

<objectives>
<primary>THIS WORKFLOW: CREATE a Pull Request from [SYSTEM_CURRENT_GIT_BRANCH] to [USER_TARGET_BRANCH] with proper formatting, comprehensive change analysis, branch synchronization, Slack notification, and reflection execution.</primary>
<secondary>
    <goal>Ensure proper branch synchronization and upstream tracking</goal>
    <goal>Generate comprehensive change analysis and commit history</goal>
    <goal>Apply project-specific formatting from PR template</goal>
    <goal>Send Slack notification about PR creation</goal>
</secondary>
</objectives>

<userInput>
USER_INPUT = Additional user instructions or context
USER_TARGET_BRANCH = Target branch name for pull request (REQUIRED)
</userInput>

<systemInput>
SYSTEM_CURRENT_GIT_BRANCH = `git branch --show-current`
SYSTEM_TEMPLATE_PR_CREATION = `.sdlc-workflows/dev/templates/pr-creation-template.md`
SYSTEM_CHAIN_SLACK_PR_NOTIFICATION = `.sdlc-workflows/dev/chains/slack-pr-notification.prompt.md`
SYSTEM_PROMPT_REFLECTION = `.sdlc-workflows/dev/reflections/dev.6.create-pull-request.reflection.md`
</systemInput>

<output>
OUTPUT_PULL_REQUEST = Pull request created from [SYSTEM_CURRENT_GIT_BRANCH] to [USER_TARGET_BRANCH] with proper formatting
</output>

<executionFlow>
EXECUTE in STRICT SEQUENTIAL ORDER. NEVER skip, reorder, or parallelize—each phase depends on prior output.
1. VALIDATE and COMPLETE pre-workflow tasks. STOP and REPORT if validation fails.
2. EXECUTE phases SEQUENTIALLY. WAIT for completion before proceeding.
3. INTEGRATE post-workflow tasks
</executionFlow>

<preWorkflowTasks>
BEFORE STARTING: EXECUTE validation tasks. STOP and REPORT if any fails:
<task title="Account User Inputs">
    CONSIDER [USER_INPUT] before proceeding (if not empty).
</task>
<task title="Target Branch Acquisition">
    USE built-in ask user question tool to ask for target branch name if not provided as argument.
    Example answers: "main" or "develop"
    WAIT for user input before proceeding.
</task>
</preWorkflowTasks>

<workflowPhases>
EXECUTE phases SEQUENTIALLY. COMPLETE each before proceeding:

<phase number="1" name="Pre-Flight Validation and Synchronization">
    <task id="1.1" title="Branch Synchronization">
        EXECUTE `git push --set-upstream origin HEAD`. CONFIRM branch pushed to remote.
    </task>
    <task id="1.2" title="Repository Verification">
        EXECUTE `git remote -v`. VERIFY correct remote configuration.
    </task>
</phase>
<phase number="2" name="Content Generation">
    <task id="2.1" title="Change Analysis">
        EXECUTE `git --no-pager diff origin/[USER_TARGET_BRANCH]..HEAD -- "*.swift" ":!*Tests.swift"`. ANALYZE complete diff.
    </task>
    <task id="2.2" title="Commit History">
        EXECUTE `git log --oneline origin/[USER_TARGET_BRANCH]..HEAD`. DOCUMENT all commit messages.
    </task>
    <task id="2.3" title="Template Integration">
        READ [SYSTEM_TEMPLATE_PR_CREATION]. INTERNALIZE formatting and content requirements.
    </task>
    <task id="2.4" title="Content Synthesis">
        GENERATE concise TITLE. CREATE comprehensive DESCRIPTION following [SYSTEM_TEMPLATE_PR_CREATION] guidelines.
    </task>
</phase>
<phase number="3" name="Pull Request Execution">
    <task id="3.1" title="PR Creation">
        USE create_pull_request tool with generated TITLE and DESCRIPTION. Target: [SYSTEM_CURRENT_GIT_BRANCH] → [USER_TARGET_BRANCH]. REPORT if no tool available.
    </task>
</phase>
<phase number="4" name="Slack Notification">
    <task id="4.1" title="Send Notification">
        READ and FOLLOW [SYSTEM_CHAIN_SLACK_PR_NOTIFICATION] to notify designated Slack channel.
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
- NEVER proceed without [USER_TARGET_BRANCH] specification
- NEVER create PR without branch synchronization
- NEVER skip [SYSTEM_TEMPLATE_PR_CREATION] guidelines
- NEVER skip Slack notification
- NEVER skip reflection workflow
</constraints>

<executionInstructions>
<command>**EXECUTE NOW**: Begin autonomous execution STRICTLY following <executionFlow> order above.</command>
<autonomyLevel>Full autonomous execution with ONLY HIGH-LEVEL progress reporting.</autonomyLevel>
</executionInstructions>
