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
<item>No vague adjectives (fast, scalable, secure, intuitive, robust) without measurable criteria. Must specify metrics (e.g., response time < 200ms, 99.9% uptime).</item>
<item>All Entities, Interfaces, and DTOs referenced in plan are linked to their respective tasks.</item>
<item>All html mockups if provided linked to their corresponding sub-tasks</item>
<item>Sub-Tasks contain NO documentation tasks except explicit ask by the user.</item>
<item>All cross-task dependencies mention specific objects/components with task numbers. E.g., `name` (from task 1.1).</item>
<item>All provided images converted to HTML files if provided</item>
<item>[OUTPUT_TASK_CONTEXT] exist and has empty checkbox [ ] status for all tasks</item>
<item>[OUTPUT_CLARIFICATION_QUESTIONS] exist and has all the clarification questions</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
