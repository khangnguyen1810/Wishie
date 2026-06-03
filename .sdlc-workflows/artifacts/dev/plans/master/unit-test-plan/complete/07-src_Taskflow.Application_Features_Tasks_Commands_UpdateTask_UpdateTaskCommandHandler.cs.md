### src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommandHandler.cs

[x] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository, IProjectRepository, and IMapper instances
    - When: UpdateTaskCommandHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[x] [NEW]: Handle
  - Test Scenario: Successfully updates task title and description
    - Given: UpdateTaskCommand with Id for existing task, Title="Updated title", Description="Updated description", ProjectSlug unchanged
    - When: Handle is called
    - Then: Task fetched via GetByIdAsync, task Title and Description updated with trimmed values, UpdateAsync called, TaskDto returned with updated values

[x] [NEW]: Handle
  - Test Scenario: Successfully updates task project assignment
    - Given: UpdateTaskCommand with Id for task currently assigned to "project-alpha", ProjectSlug="project-beta", target project exists
    - When: Handle is called
    - Then: Task fetched, new project fetched via GetBySlugAsync, task.ProjectId updated to new project ID, UpdateAsync called, task reloaded with GetByIdWithSubtasksAsync, TaskDto returned with new project

[x] [NEW]: Handle
  - Test Scenario: Successfully unassigns task from project
    - Given: UpdateTaskCommand with Id for task assigned to project, ProjectSlug=null
    - When: Handle is called
    - Then: Task fetched, task.ProjectId set to null, UpdateAsync called, TaskDto returned with null project

[x] [NEW]: Handle
  - Test Scenario: Trims whitespace from title and description during update
    - Given: UpdateTaskCommand with Title="  New Title  ", Description="  New Description  "
    - When: Handle is called
    - Then: Task updated with Title="New Title", Description="New Description" (trimmed)

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task ID does not exist
    - Given: UpdateTaskCommand with Id="550e8400-e29b-41d4-a716-446655440999", GetByIdAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '...' not found"

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when target project slug does not exist
    - Given: UpdateTaskCommand with valid task Id, ProjectSlug="invalid-project", GetBySlugAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Project with slug 'invalid-project' not found", task remains unchanged

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when attempting to update soft-deleted task
    - Given: UpdateTaskCommand with Id for soft-deleted task, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown, no update operation performed

[x] [NEW]: Handle
  - Test Scenario: Reloads task with project navigation when ProjectId changes
    - Given: UpdateTaskCommand that changes ProjectSlug to new value
    - When: Handle is called
    - Then: After UpdateAsync, GetByIdWithSubtasksAsync is called to reload task with updated Project navigation property
