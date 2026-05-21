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
<item>Coding filter files updated with correct filters</item>
<item>Testing filter files updated with correct filters</item>
<item>Coding convention file filled with project-specific standards</item>
<item>Testing convention file filled with project-specific standards</item>
<item>All [PLACEHOLDER] placeholders replaced in convention files</item>
<item>Filters correctly distinguish logic-bearing files from declarative code</item>
<item>[CODING_CONVENTION_OUTPUT] file created from template and populated</item>
<item>[TESTING_CONVENTION_OUTPUT] file created from template and populated</item>
<item>Backend onboarding prompt revised if backend exists [ONBOARDING_CODING]</item>
<item>Testing onboarding prompt revised if tests exist [ONBOARDING_TESTING]</item>
<item>Logic-bearing files included (algorithms, control flow, state mutations)</item>
<item>Declarative files excluded (type definitions, DTOs without behavior)</item>
<item>Core system files NOT modified during analysis</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>