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
<item>[UNIT_TEST_INCOMPLETE_DIR] is empty (no test items left)</item>
<item>All completed test items moved to [UNIT_TEST_COMPLETE_DIR]</item>
<item>No test item left with incomplete status([ ]) in [UNIT_TEST_COMPLETE_DIR]</item>
<item>All implemented tests pass execution</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
