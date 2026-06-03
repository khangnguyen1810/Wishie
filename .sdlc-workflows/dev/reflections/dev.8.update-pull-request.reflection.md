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
<item>Code changes pushed to remote branch successfully</item>
<item>PR comment created with comprehensive change summary following [TEMPLATE_PR_UPDATE]</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
