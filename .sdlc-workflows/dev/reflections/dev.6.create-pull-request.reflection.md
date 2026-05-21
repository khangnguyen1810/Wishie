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
<item>PR is created with current branch and target branch correctly</item>
<item>PR title follows Conventional Commits specification</item>
<item>PR description includes all template sections from [TEMPLATE_PR_CREATION]</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
