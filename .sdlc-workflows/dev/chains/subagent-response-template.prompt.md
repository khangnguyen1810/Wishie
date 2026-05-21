<objectives>
Validate work against the checklist criteria. Respond to the caller using <sub-agent-response-template> — set Status to FAIL and list violations if any items fail, or PASS with a summary if all items pass.
Keep the response SHORT and CONCISE to save tokens — only include essential information.
</objectives>

<checklist>
SUCCESS CRITERIA: This workflow is COMPLETE when ALL items are verified:
<item>Session activities reviewed and analyzed for deviations</item>
<item>All issues, errors, and deviations identified</item>
</checklist>

<sub-agent-response-template>
Status: PASS | FAIL
Violations: (if FAIL — list each violation in bullet points, otherwise omit)
Summary of Completed Work:
<!-- Short and concise each completion work in bullet points — focus on WHAT was done, not HOW -->
Issues while executing workflow:
<!-- What happened that caused long execution time, tool call issues, or went wrong. -->
Improvements for next execution:
<!-- Suggestions for improving the workflow execution in the future. -->
</sub-agent-response-template>
