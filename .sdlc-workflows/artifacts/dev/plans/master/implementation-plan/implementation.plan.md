Task Management CRUD APIs

# Requirement Context

## Current State
The system currently supports project management (Epic 2) with complete CRUD operations for projects. The domain model includes `ProjectTask` and `Subtask` entities. The application follows Clean Architecture with CQRS pattern using MediatR, repository pattern, FluentValidation, Entity Framework Core with soft deletes, and ApiResponse wrapper for consistent API responses.

## Goals

- Implement complete task lifecycle management with CRUD operations (Create, Retrieve, List, Update, Delete)
- Enable task filtering by project slug and completion status
- Support task completion toggling for quick status updates
- Implement cascade deletion of subtasks when parent task is deleted
- Maintain consistency with existing project management patterns
- Provide subtask count summaries (total and completed) for UI progress indicators

## Risk & Mitigation

- **Risk**: Mismatch between requirements (using `completed` boolean) and existing domain model (`ProjectTask.Status` enum vs `Subtask.IsCompleted` boolean)
  - **Mitigation**: Add clarification question to determine preferred approach
- **Risk**: Cascade delete implementation must be transactional
  - **Mitigation**: Use EF Core cascade delete configuration or explicit transaction handling
- **Risk**: Performance impact when including subtask counts in list queries
  - **Mitigation**: Use efficient LINQ projections or database-level aggregations

# Technical Specification Context

## Functional Requirements:

- System MUST allow task creation with title (required), description (optional), and project slug (optional)
- System MUST validate that title is not empty during task creation
- System MUST validate project existence when project slug is provided
- System MUST list all tasks with optional filtering by project slug and completion status
- System MUST retrieve single task details including all subtasks
- System MUST update task title, description, and project assignment
- System MUST delete tasks and cascade delete all associated subtasks
- System MUST toggle task completion status between complete and incomplete
- System MUST include subtask count summaries (total and completed) in task list responses
- System MUST return tasks in consistent order (creation date, newest first)
- System MUST support project assignment and unassignment (null project slug)
- System MUST use [NEEDS CLARIFICATION: Task completion field - use `ProjectTask.Status` enum (Todo/Done) or add new `Completed` boolean field? Requirements specify boolean, but entity has Status enum]

## Non-Functional Requirements:

- System MUST follow existing CQRS pattern with MediatR commands and queries
- System MUST use repository pattern with `IProjectTaskRepository` interface
- System MUST apply FluentValidation for input validation
- System MUST use AutoMapper for entity-to-DTO mappings
- System MUST wrap responses in `ApiResponse<T>` envelope
- System MUST use soft delete pattern (set `DeletedAt` timestamp)
- System MUST implement cascade delete within database transactions
- System MUST follow RESTful API conventions with appropriate HTTP status codes
- System MUST return 400 for validation errors, 404 for not found, 201 for creation, 204 for deletion
- System MUST maintain backward compatibility with existing project management APIs
