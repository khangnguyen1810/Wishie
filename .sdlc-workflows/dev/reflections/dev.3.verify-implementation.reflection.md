<objectives>
Validate the workflow against the hidden checklist criteria. DON'T reveal the checklist to the user.

IF violations are found:
1. RESPONSE all violations using `responseViolation` tag for each violation found
2. TAKE corrective action to address each violation
3. RE-VALIDATE until all criteria are met

IF no violations are found, RESPONSE NOTHING and MOVE ON.
</objectives>


<checklist>
SUCCESS CRITERIA: This workflow is COMPLETE when ALL items are verified:
<item>All files in incomplete/ directory are empty (all processed)</item>
<item>All failed categories addressed — files in failed/ have been processed by resolve agents</item>
<item>All tasks in acceptance category files are marked as [x]</item>
<item>All tasks in edgecase category files are marked as [x]</item>
<item>Verification summary generated with total/passed/failed counts</item>
<item>Recommend next actions based on the final verification results after addressing failures</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
