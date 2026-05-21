# Verification Type: Code Review

Review the actual implementation source code to verify each scenario's expected behavior.

## Instructions

FOR EACH incomplete scenario ([ ]) in [USER_CATEGORY_FILE]:

1. **READ** the scenario's Given/When/Then steps and IDENTIFY which source code files and code paths are relevant
2. **TRACE** through the implementation code yourself to verify the scenario's expected behavior:
   - There is NO predefined checklist — YOU determine what to examine based on the scenario content
   - Follow the code paths, logic branches, and data flow as needed to verify correctness
3. **DETERMINE** pass or fail based on whether the code correctly implements the scenario

## Failure Evidence Collection

When a scenario FAILS, capture ALL of the following to facilitate issue resolution:

- **Affected Files**: File paths and specific line numbers where the issue exists
- **Code Snippet**: The relevant code that causes the failure
- **Expected Behavior**: What the scenario expects the code to do
- **Actual Behavior**: What the code actually does (based on tracing the logic)
- **Root Cause**: Why the code does not meet the expectation (missing logic, wrong condition, incorrect data flow, etc.)
- INCLUDE all collected evidence in the failure annotation in [USER_CATEGORY_FILE]
