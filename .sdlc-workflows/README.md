# SDLC Workflow Apply Guide

## Install workflow

- npm install -g @kms-technology/sdlc-workflows@latest
- sdlc-workflows init

## setup workflow

1. Run dev.setup-workflow commands it will help you scan the repo and setup the workflow following the project context

## Workflow Execution flow:

- Work by the exact order that in the name of the from.

### DEV Workflow Notes

- Planning steps need to go with implementation steps which are consume the planning files.

### QA Workflow Notes:

- Run `qa.setup-workflow` once per repo to configure workflow filters.
- Run `qa.1` to onboard the agent to the project (re-run when the project changes significantly).
- Test implementation and code-review follow numeric order:
  - **qa.2a → qa.2b → qa.2c**: Single manual test case — plan, implement, verify.
  - **qa.3a → qa.3b**: Code-review the test files written in qa.2 (always run before qa.4).
  - **qa.4a → qa.4b**: Batch E2E scenarios — generate sharded plan, implement in parallel via sub-agents.
- Run `qa.5 → qa.6a → qa.6b → qa.7` in order for PR creation and review.
- Run `qa.audit` at any time to validate a completed workflow run.

# Jira MCP Setup (get_work_item tool)

The `get_work_item` tool retrieves Jira work items (tasks, stories, epics) with comments and attachments, and saves them as structured markdown files. It requires two environment variables:

| Variable | Description |
|----------|-------------|
| `JIRA_ENDPOINT` | Your Jira instance base URL |
| `JIRA_TOKEN` | Bearer token for API authentication |

## Step 1: Find your JIRA_ENDPOINT

- **Jira Cloud**: `https://<your-domain>.atlassian.net`
  - Example: `https://mycompany.atlassian.net`
  - Find it in your browser address bar when logged into Jira
- **Jira Data Center / Server**: Your self-hosted Jira URL
  - Example: `https://jira.mycompany.com`

## Step 2: Get your JIRA_TOKEN

The tool uses `Authorization: Bearer <token>` for all requests. How you obtain the token depends on your Jira deployment:

### Jira Data Center / Server (8.14+) — Personal Access Token (PAT)

1. Log in to Jira
2. Click your **profile icon** (top-right) → **Profile**
3. Go to **Personal Access Tokens** (left sidebar)
4. Click **Create token**
5. Give it a name (e.g., `sdlc-workflow`) and set an expiry
6. Copy the generated token — use it directly as `JIRA_TOKEN`

### Jira Cloud — API Token (Basic Auth encoded as Bearer)

Jira Cloud does not natively support PATs. Use one of these approaches:

Base64-encoded API Token (recommended for simplicity)**

1. Go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click **Create API token**, give it a label, and copy the token
3. Base64-encode your credentials: `email:api_token`
   
4. Use the base64 string as `JIRA_TOKEN`

> **Note:** When using this approach, you must update the MCP server's auth header from `Bearer` to `Basic`. Set the env var as:
> `JIRA_TOKEN=your-base64-string` and update the Authorization header in the tool config if needed. Alternatively, use Option B.

## Step 3: Add to MCP config

Add the env vars to your MCP settings file (`.vscode/mcp.json` or equivalent):

```json
{
  "servers": {
    "sdlc-workflow": {
      "env": {
        "JIRA_ENDPOINT": "https://your-domain.atlassian.net",
        "JIRA_TOKEN": "your-token-here",
        ...existing env vars...
      }
    }
  }
}
```

## Usage

The tool is invoked via MCP with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `provider` | string | Yes | — | Provider name (e.g., `"jira"`) |
| `taskId` | string | Yes | — | Task identifier (e.g., `"PROJ-123"`) |
| `includeParentTasks` | boolean | No | `true` | Fetch the parent task chain of the specified task |
| `destinationPath` | string | Yes | — | Output directory for generated files |

### Output Structure

With `includeParentTasks=true`:
```
outputs/
  EPIC-100/
    EPIC-100.md
    attachments/
    PROJ-123/                ← requested task
      PROJ-123.md
      attachments/
```

With `includeParentTasks=false`:
```
outputs/
  PROJ-123/
    PROJ-123.md
    attachments/
```

---

# Slack MCP setup

## Lookup SLACK_MCP_XOXC_TOKEN

1. Open Slack Web App and Press F12 to open your browser's Developer Console.
2. In Firefox, under Tools -> Browser Tools -> Web Developer tools in the menu bar
3. In Chrome, click the "three dots" button to the right of the URL Bar, then select More Tools -> Developer Tools
4. Switch to the console tab.
5. Type "allow pasting" and press ENTER.
6. Paste the following snippet and press ENTER to execute: JSON.parse(localStorage.localConfig_v2).teams\[document.location.pathname.match(/^/client/(\[A-Z0-9]+)/)\[1]].token
