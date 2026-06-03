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
<item>Testing frameworks and structure patterns documented with absolute precision</item>
<item>Test organization patterns and type categorization clearly explained</item>
<item>Mocking strategies and test utilities comprehensively documented</item>
<item>Test data management and environment setup procedures clearly outlined</item>
<item>[OUTPUT_KNOWLEDGE_TESTING] file exists and is populated (not just template copy)</item>
<item>Fixture patterns and seed data strategies analyzed</item>
<item>No business-specific test case enumeration (constraint compliance)</item>
<item>Objective, technical tone maintained throughout</item>
<item>All template sections either filled or explicitly marked "N/A"</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
