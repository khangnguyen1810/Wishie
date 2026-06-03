# Verification Type: API Testing

Verify each scenario by executing actual HTTP requests against a running API server.

## Prerequisites

- EXTRACT the test server URL from [USER_TESTING_INFO] first (e.g., `http://localhost:3000`)
- If not found in [USER_TESTING_INFO], fall back to extracting from [USER_INPUT]
- If no server URL is found in either, STOP and REPORT that a server URL is required

## Test Isolation

- Each scenario's Given preconditions already contain unique, scenario-namespaced identifiers — USE these exact identifiers when creating test data via API calls. Do NOT substitute generic names.
- Clean up all created resources after verification
- No shared state or ordering assumptions between scenarios

## Instructions

FOR EACH incomplete scenario ([ ]) in [USER_CATEGORY_FILE]:

1. **SET UP** preconditions via API calls with scenario-specific identifiers
2. **EXECUTE** the HTTP request(s) implied by the scenario using `curl`
3. **VALIDATE** response against expected outcomes → mark pass or fail
4. **CLEAN UP** created resources (DELETE/revert)

## On Failure — Capture:

- **Request**: Full curl command used
- **Response**: Status code + body (or relevant excerpt)
- **Expected vs Actual**: What was expected vs what was returned
- INCLUDE all collected evidence in the failure annotation in [USER_CATEGORY_FILE]
