# Clarification Questions Template

## Purpose

Record questions raised during planning and their confirmed answers to resolve ambiguities in task requirements, ensuring the implementation plan reflects verified decisions.

# Guide:
- NEVER add question's options into this file, keep context small.
- ONLY add questions and it's answer following the template below.

# Template
```
- [the question]: 
[the answer and its brief reasoning]
```

# Clarification Questions: 

- How should task completion status be represented in the API responses?
**Answer**: Map `ProjectTask.Status` enum to a boolean `completed` field in DTOs: `Status == Done` maps to `completed: true`, all other states map to `completed: false`. Toggle operation will switch between `Todo` and `Done` states. This maintains backward compatibility with the existing domain model while satisfying API requirements for boolean completion status.

- Should toggling a task to complete also mark all its subtasks as complete?
**Answer**: No. Tasks and subtasks have independent completion states. This provides flexibility for users to complete a task even if not all subtasks are done, or vice versa.

- What order should tasks be returned in the list endpoint?
**Answer**: Tasks ordered by creation date descending (newest first) as per requirements and consistent with existing project listing pattern.
