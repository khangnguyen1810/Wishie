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
<item>Each task includes precise line numbers and original comment text</item>
<item>Comments with identical line numbers and content are grouped together</item>
<item>File structure matches template exactly with all required sections populated</item>
<item>Git branch information accurately captured (base and head branches)</item>
<item>All PR comments represented as tasks in the plan</item>
<item>The plan files have solutions for unresolved comments</item>
<item>Plan sharded with heading level 3 into [SHARDING_INCOMPLETE_PATH]</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
