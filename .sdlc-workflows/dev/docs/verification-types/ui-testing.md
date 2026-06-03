# Verification Type: UI Testing

Verify each scenario by automating browser interactions using playwright-cli.

## Prerequisites

- EXTRACT the application URL from [USER_TESTING_INFO] first (e.g., `http://localhost:3000`)
- If not found in [USER_TESTING_INFO], fall back to extracting from [USER_INPUT]
- If no application URL is found in either, STOP and REPORT that an application URL is required
- READ the playwright-cli command reference

## Test Isolation

- Start a NEW browser session per scenario — never reuse sessions
- Each scenario's Given preconditions already contain unique, scenario-namespaced identifiers — USE these exact identifiers when setting up preconditions. Do NOT substitute generic names.
- No shared state or ordering assumptions between scenarios
- Clean up created data before closing session

## Instructions

FOR EACH incomplete scenario ([ ]) in [USER_CATEGORY_FILE]:

1. **START** session: `playwright-cli -s=<test-case-name> open <application-url>`
2. **SET UP** preconditions (create data, navigate to starting page)
3. **EXECUTE** scenario steps using playwright-cli commands; take `snapshot` after key interactions
4. **DETERMINE** pass or fail based on expected outcome
5. **CLOSE** session: clean up test data, then `playwright-cli -s=<test-case-name> close` and `delete-data`

## On Failure — Capture:

- **Expected vs Actual**: What was expected vs what the page showed
- INCLUDE all collected evidence in the failure annotation in [USER_CATEGORY_FILE]

# playwright-cli Command Reference

## Session Management

```bash
playwright-cli -s=<session-name> open <url>   # create session & navigate
playwright-cli -s=<session-name> close         # close session
playwright-cli -s=<session-name> delete-data   # delete session data
playwright-cli list                            # list active sessions
playwright-cli close-all                       # close all sessions
playwright-cli kill-all                        # force kill all browsers
```

> Only `open` uses `-s=<session-name>` to create. All other commands inherit the active session.

## Core Interactions

```bash
playwright-cli click e3
playwright-cli dblclick e7
playwright-cli fill e5 "text"
playwright-cli type "search query"
playwright-cli select e9 "option-value"
playwright-cli check e12
playwright-cli uncheck e12
playwright-cli hover e4
playwright-cli drag e2 e8
playwright-cli upload ./file.pdf
playwright-cli resize 1920 1080
```

## Navigation

```bash
playwright-cli goto https://example.com
playwright-cli go-back
playwright-cli go-forward
playwright-cli reload
```

## Observation

```bash
playwright-cli snapshot
```

## Dialogs

```bash
playwright-cli dialog-accept
playwright-cli dialog-accept "confirmation text"
playwright-cli dialog-dismiss
```

## Keyboard & Mouse

```bash
playwright-cli press Enter
playwright-cli press ArrowDown
playwright-cli keydown Shift
playwright-cli keyup Shift
playwright-cli mousemove 150 300
playwright-cli mousedown
playwright-cli mousedown right
playwright-cli mouseup
playwright-cli mouseup right
playwright-cli mousewheel 0 100
```

## Tabs

```bash
playwright-cli tab-list
playwright-cli tab-new
playwright-cli tab-new https://example.com/page
playwright-cli tab-close
playwright-cli tab-close 2
playwright-cli tab-select 0
```

## Storage

```bash
playwright-cli state-save
playwright-cli state-save auth.json
playwright-cli state-load auth.json
playwright-cli cookie-list
playwright-cli cookie-get session_id
playwright-cli cookie-set session_id abc123 --domain=example.com --httpOnly --secure
playwright-cli cookie-delete session_id
playwright-cli cookie-clear
playwright-cli localstorage-list
playwright-cli localstorage-get key
playwright-cli localstorage-set key value
playwright-cli localstorage-delete key
playwright-cli localstorage-clear
playwright-cli sessionstorage-list
playwright-cli sessionstorage-get key
playwright-cli sessionstorage-set key value
playwright-cli sessionstorage-delete key
playwright-cli sessionstorage-clear
```

## Network

```bash
playwright-cli route "**/*.jpg" --status=404
playwright-cli route "https://api.example.com/**" --body='{"mock": true}'
playwright-cli route-list
playwright-cli unroute "**/*.jpg"
playwright-cli unroute
```

## DevTools & Error Capture

```bash
playwright-cli console              # capture console logs/errors
playwright-cli console warning      # filter by level
playwright-cli network              # capture network requests/failures
playwright-cli run-code "async page => await page.context().grantPermissions(['geolocation'])"
playwright-cli tracing-start
playwright-cli tracing-stop
playwright-cli video-start
playwright-cli video-stop video.webm
```

## Snapshots

After each command, playwright-cli provides a snapshot of the current browser state. Use `snapshot` to inspect element refs before interacting.
