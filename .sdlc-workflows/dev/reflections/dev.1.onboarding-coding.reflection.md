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
<item>Technical documentation focuses on architecture and design patterns</item>
<item>System structure and design choices clearly explained</item>
<item>Cross-cutting concerns and infrastructure integrations documented</item>
<item>Application-level design patterns and folder responsibilities documented</item>
<item>For project has Front-End: State Management and Component Patterns sections are defined</item>
<item>[OUTPUT_KNOWLEDGE_CODING] file exists and is populated (not just template copy)</item>
<item>High-level MermaidJS architecture diagram is included</item>
<item>No business-specific logic details included (constraint compliance)</item>
<item>No specific API endpoint enumeration (constraint compliance)</item>
<item>Objective, technical tone maintained throughout</item>
<item>Design patterns documented with WHY justification based on code structure</item>
<item>Shared code conventions (utilities, DTOs, constants, base classes) documented</item>
</checklist>

<responseViolation>
| CheckList | Violation |
|-----------|--------------|
| [CheckList Short Description] | [Violation short and concise reason] |
</responseViolation>
