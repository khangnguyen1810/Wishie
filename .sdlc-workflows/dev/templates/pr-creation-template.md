# PR Creation Template

## Purpose

Provide a consistent, well-structured pull request with a clear title, summary of changes, and relevant context for reviewers.

## 1. PR Title

The title must follow the Conventional Commits specification.

## 2. PR Description (The Template)

Use this exact Markdown template in the body of your pull request, using "N/A" for sections that are not applicable.

```markdown
## Summary

<!--
What problem is this PR solving? Why is this change necessary?
Provide a brief, high-level overview.
-->

## Implementation Details

<!--
List the key changes made in this PR. Be specific.
Group related changes by component, module, or file.
-->

- `[Component/Module Name]`: Brief description of the change.
- `[Another Component]`: Brief description of the change.
- `[File: path/to/file.js]`: Brief description of the change.

## Self-testing Checklist

- [ ] Self-code review

<!--
Depend on the changed services/components/areas. Define self-testing checklist owner of this PR should take to make sure the features work as expected before sending the PR for peer-review. The self-testing checklist must be blank and fill by the PR owner.
-->

## Additional Notes (Optional)

<!--
Anything else reviewers should know?
e.g., new dependencies, environment variables, package, potential risks.
-->
```
