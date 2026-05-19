# Unit Test Plan (TDD)

## Purpose

This document contains unit test specifications generated BEFORE implementation using TDD principles.
Each test scenario defines expected behavior that the implementation must fulfill.
Tests should be written first (Red), then implementation created to make them pass (Green).

## Task Status Legend

- `[ ]` - Test not yet implemented
- `[x]` - Test implemented and passing

## Function Status Legend

- NEW: Functions to be added (all functions in TDD approach)
- UPDATED: Existing functions with modified implementation
- DELETED: Functions to be removed from the codebase

## Traceability

All test scenarios map to requirements from:
- **Implementation Plan**: Functional and non-functional requirements
- **Acceptance Scenarios**: 15 Given-When-Then acceptance criteria
- **Edge Case Scenarios**: 11 boundary condition and error scenarios

## Test Framework & Conventions

- **Framework**: xUnit with FluentAssertions and Moq
- **Format**: Given-When-Then for all scenarios
- **Mocking**: All dependencies mocked using Mo q
- **Coverage Target**: 100% of public methods with happy path + error + edge cases

## Task List

### src/Taskflow.Infrastructure/Persistence/Repositories/ProjectTaskRepository.cs

[ ] [NEW]: AddAsync
  - Test Scenario: Successfully adds task to database and returns task with generated ID
    - Given: A valid ProjectTask entity with Title="Implement login", Description="Add OAuth", Status=Todo, ProjectId set
    - When: AddAsync is called with the task entity
    - Then: Task is added to DbContext.Tasks, SaveChangesAsync is called, and task with generated ID is returned

[ ] [NEW]: AddAsync
  - Test Scenario: Successfully adds task without project assignment
    - Given: A valid ProjectTask entity with Title="Research framework", Description=null, ProjectId=null, Status=Todo
    - When: AddAsync is called with the task entity
    - Then: Task is added to DbContext.Tasks with null ProjectId, SaveChangesAsync is called, and task is returned

[ ] [NEW]: AddAsync
  - Test Scenario: Throws exception when task parameter is null
    - Given: Task parameter is null
    - When: AddAsync is called
    - Then: ArgumentNullException is thrown with parameter name "task"

[ ] [NEW]: GetByIdAsync
  - Test Scenario: Successfully retrieves task by ID
    - Given: A task exists with ID "550e8400-e29b-41d4-a716-446655440000" and DeletedAt is null
    - When: GetByIdAsync is called with the task ID
    - Then: Returns the task entity with all properties populated, using ConfigureAwait(false)

[ ] [NEW]: GetByIdAsync
  - Test Scenario: Returns null when task with specified ID does not exist
    - Given: No task exists with ID "550e8400-e29b-41d4-a716-446655440999"
    - When: GetByIdAsync is called with the non-existent ID
    - Then: Returns null

[ ] [NEW]: GetByIdAsync
  - Test Scenario: Returns null when task with ID exists but is soft-deleted
    - Given: A task exists with ID "550e8400-e29b-41d4-a716-446655440000" and DeletedAt is not null
    - When: GetByIdAsync is called with the deleted task ID
    - Then: Returns null (soft-deleted tasks are excluded from query)

[ ] [NEW]: GetByIdWithSubtasksAsync
  - Test Scenario: Successfully retrieves task with all subtasks and project included
    - Given: Task ID "550e8400-e29b-41d4-a716-446655440042" exists with 3 subtasks and assigned project
    - When: GetByIdWithSubtasksAsync is called with the task ID
    - Then: Returns task with Subtasks collection populated (3 items) and Project navigation property loaded

[ ] [NEW]: GetByIdWithSubtasksAsync
  - Test Scenario: Successfully retrieves task with empty subtasks collection when no subtasks exist
    - Given: Task ID "550e8400-e29b-41d4-a716-446655440030" exists with zero subtasks
    - When: GetByIdWithSubtasksAsync is called with the task ID
    - Then: Returns task with empty Subtasks collection and Project property loaded

[ ] [NEW]: GetByIdWithSubtasksAsync
  - Test Scenario: Returns null when task does not exist
    - Given: No task exists with ID "550e8400-e29b-41d4-a716-446655440999"
    - When: GetByIdWithSubtasksAsync is called
    - Then: Returns null

[ ] [NEW]: GetAllAsync
  - Test Scenario: Successfully retrieves all non-deleted tasks ordered by CreatedAt descending
    - Given: Database contains 5 non-deleted tasks created at different times and 2 soft-deleted tasks
    - When: GetAllAsync is called with no filters (projectSlug=null, completed=null)
    - Then: Returns 5 tasks ordered by CreatedAt descending (newest first), each with Project and Subtasks included, soft-deleted tasks excluded

[ ] [NEW]: GetAllAsync
  - Test Scenario: Filters tasks by project slug successfully
    - Given: Tasks exist for "project-alpha" (3 tasks), "project-beta" (2 tasks), unassigned (1 task)
    - When: GetAllAsync is called with projectSlug="project-alpha"
    - Then: Returns exactly 3 tasks belonging to "project-alpha", ordered by CreatedAt descending

[ ] [NEW]: GetAllAsync
  - Test Scenario: Filters tasks by completion status (completed=true)
    - Given: 5 tasks exist: 2 with Status=Done, 3 with Status=Todo
    - When: GetAllAsync is called with completed=true
    - Then: Returns exactly 2 tasks where Status==Done, ordered by CreatedAt descending

[ ] [NEW]: GetAllAsync
  - Test Scenario: Filters tasks by completion status (completed=false)
    - Given: 5 tasks exist: 2 with Status=Done, 3 with Status=Todo (or InProgress/Cancelled)
    - When: GetAllAsync is called with completed=false
    - Then: Returns exactly 3 tasks where Status!=Done, ordered by CreatedAt descending

[ ] [NEW]: GetAllAsync
  - Test Scenario: Applies both project slug and completion status filters
    - Given: Database contains tasks across multiple projects with various completion states
    - When: GetAllAsync is called with projectSlug="project-alpha" and completed=true
    - Then: Returns only tasks matching both filters (project-alpha AND Status==Done), ordered by CreatedAt descending

[ ] [NEW]: GetAllAsync
  - Test Scenario: Returns empty collection when no tasks exist
    - Given: Database contains zero tasks
    - When: GetAllAsync is called with no filters
    - Then: Returns empty IEnumerable<ProjectTask> with count of 0

[ ] [NEW]: GetAllAsync
  - Test Scenario: Returns empty collection when project slug does not match any tasks
    - Given: Tasks exist for various projects but none with slug "nonexistent-project"
    - When: GetAllAsync is called with projectSlug="nonexistent-project"
    - Then: Returns empty IEnumerable<ProjectTask>

[ ] [NEW]: UpdateAsync
  - Test Scenario: Successfully updates task and saves changes
    - Given: A ProjectTask entity with modified Title="Updated title", Description="Updated description"
    - When: UpdateAsync is called with the modified task
    - Then: DbContext.Tasks.Update is called with the task, SaveChangesAsync is called

[ ] [NEW]: UpdateAsync
  - Test Scenario: Throws exception when task parameter is null
    - Given: Task parameter is null
    - When: UpdateAsync is called
    - Then: ArgumentNullException is thrown with parameter name "task"

[ ] [NEW]: DeleteAsync
  - Test Scenario: Successfully soft deletes task and all related subtasks
    - Given: Task exists with ID "550e8400-e29b-41d4-a716-446655440040" with 4 associated subtasks, all with DeletedAt=null
    - When: DeleteAsync is called with the task
    - Then: Task.DeletedAt is set to current UTC time, all 4 subtasks have DeletedAt set, DbContext.Update is called, SaveChangesAsync is called

[ ] [NEW]: DeleteAsync
  - Test Scenario: Successfully soft deletes task with zero subtasks
    - Given: Task exists with zero subtasks and DeletedAt=null
    - When: DeleteAsync is called with the task
    - Then: Task.DeletedAt is set to current UTC time, SaveChangesAsync is called, no errors occur

[ ] [NEW]: DeleteAsync
  - Test Scenario: Throws exception when task parameter is null
    - Given: Task parameter is null
    - When: DeleteAsync is called
    - Then: ArgumentNullException is thrown with parameter name "task"

### src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommandValidator.cs

[ ] [NEW]: Validate
  - Test Scenario: Validation succeeds for valid command with all fields
    - Given: CreateTaskCommand with Title="Implement login feature", Description="Add OAuth support", ProjectSlug="project-alpha"
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors

[ ] [NEW]: Validate
  - Test Scenario: Validation succeeds for command with only required Title field
    - Given: CreateTaskCommand with Title="Research framework", Description=null, ProjectSlug=null
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors

[ ] [NEW]: Validate
  - Test Scenario: Validation fails when Title is null
    - Given: CreateTaskCommand with Title=null
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title is required" is present

[ ] [NEW]: Validate
  - Test Scenario: Validation fails when Title is empty string
    - Given: CreateTaskCommand with Title=""
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title is required" is present

[ ] [NEW]: Validate
  - Test Scenario: Validation fails when Title contains only whitespace
    - Given: CreateTaskCommand with Title="   " (spaces only)
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title cannot be only whitespace" is present

[ ] [NEW]: Validate
  - Test Scenario: Validation fails when Title exceeds 500 characters
    - Given: CreateTaskCommand with Title of 501 characters
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title must not exceed 500 characters" is present

[ ] [NEW]: Validate
  - Test Scenario: Validation succeeds when Title is exactly 500 characters
    - Given: CreateTaskCommand with Title of exactly 500 characters
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors

### src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommandHandler.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository, IProjectRepository, and IMapper instances
    - When: CreateTaskCommandHandler constructor is called with dependencies
    - Then: Constructor succeeds and stores dependencies for later use

[ ] [NEW]: Handle
  - Test Scenario: Successfully creates task with valid data and project association
    - Given: CreateTaskCommand with Title="Implement login feature", Description="Add OAuth support", ProjectSlug="project-alpha", and project exists in repository
    - When: Handle is called
    - Then: Project is fetched via GetBySlugAsync, ProjectTask is created with Title trimmed, Description trimmed, ProjectId set, Status=Todo, AddAsync is called, task reloaded with GetByIdWithSubtasksAsync, TaskDto returned with all fields mapped

[ ] [NEW]: Handle
  - Test Scenario: Successfully creates task without project association
    - Given: CreateTaskCommand with Title="Research new framework", Description=null, ProjectSlug=null
    - When: Handle is called
    - Then: Project lookup is skipped, ProjectTask is created with Title trimmed, ProjectId=null, Status=Todo, AddAsync is called, TaskDto returned with null project

[ ] [NEW]: Handle
  - Test Scenario: Trims whitespace from title and description
    - Given: CreateTaskCommand with Title="  Task Title  ", Description="  Task Description  ", ProjectSlug=null
    - When: Handle is called
    - Then: ProjectTask is created with Title="Task Title" (trimmed) and Description="Task Description" (trimmed)

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when project slug does not exist
    - Given: CreateTaskCommand with ProjectSlug="nonexistent-project", and GetBySlugAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Project with slug 'nonexistent-project' not found"

[ ] [NEW]: Handle
  - Test Scenario: Throws ArgumentNullException when request is null
    - Given: Request parameter is null
    - When: Handle is called
    - Then: ArgumentNullException is thrown with parameter name "request"

[ ] [NEW]: Handle
  - Test Scenario: Sets Status to Todo for newly created task
    - Given: Valid CreateTaskCommand with any valid parameters
    - When: Handle is called
    - Then: Created ProjectTask has Status set to TaskStatus.Todo

[ ] [NEW]: Handle
  - Test Scenario: Reloads task with project navigation property when ProjectId is set
    - Given: CreateTaskCommand with ProjectSlug="project-alpha", project exists
    - When: Handle is called
    - Then: After AddAsync, GetByIdWithSubtasksAsync is called to reload task with Project navigation property populated for mapping

### src/Taskflow.Application/Features/Tasks/Queries/GetAllTasks/GetAllTasksQueryHandler.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository and IMapper instances
    - When: GetAllTasksQueryHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[ ] [NEW]: Handle
  - Test Scenario: Successfully retrieves all tasks with subtask counts
    - Given: GetAllTasksQuery with ProjectSlug=null, Completed=null, and 5 tasks exist with various subtask counts
    - When: Handle is called
    - Then: Repository GetAllAsync is called with no filters, returns all tasks, each TaskDto includes totalSubtasks and completedSubtasks counts, tasks ordered by CreatedAt descending

[ ] [NEW]: Handle
  - Test Scenario: Successfully filters tasks by project slug
    - Given: GetAllTasksQuery with ProjectSlug="project-alpha", tasks exist for multiple projects
    - When: Handle is called
    - Then: Repository GetAllAsync is called with projectSlug="project-alpha", returns only tasks for that project, TaskDto list returned

[ ] [NEW]: Handle
  - Test Scenario: Successfully filters tasks by completion status true
    - Given: GetAllTasksQuery with Completed=true, tasks with Status=Done and Status=Todo exist
    - When: Handle is called
    - Then: Repository GetAllAsync is called with completed=true, returns only tasks with Status==Done, completed field in DTOs is true

[ ] [NEW]: Handle
  - Test Scenario: Successfully filters tasks by completion status false
    - Given: GetAllTasksQuery with Completed=false, tasks with various statuses exist
    - When: Handle is called
    - Then: Repository GetAllAsync is called with completed=false, returns only tasks with Status!=Done, completed field in DTOs is false

[ ] [NEW]: Handle
  - Test Scenario: Applies both projectSlug and completed filters simultaneously
    - Given: GetAllTasksQuery with ProjectSlug="project-beta" and Completed=true
    - When: Handle is called
    - Then: Repository GetAllAsync is called with both filters, returns only tasks matching both criteria

[ ] [NEW]: Handle
  - Test Scenario: Returns empty list when no tasks exist
    - Given: GetAllTasksQuery with no filters, database has zero tasks
    - When: Handle is called
    - Then: Repository GetAllAsync returns empty collection, empty List<TaskDto> is returned

[ ] [NEW]: Handle
  - Test Scenario: Maps Status enum to completed boolean correctly in DTOs
    - Given: Tasks with Status=Done and Status=Todo exist
    - When: Handle is called
    - Then: TaskDto for Status=Done has Completed=true, TaskDto for Status=Todo has Completed=false

### src/Taskflow.Application/Features/Tasks/Queries/GetTaskById/GetTaskByIdQueryHandler.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository and IMapper instances
    - When: GetTaskByIdQueryHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[ ] [NEW]: Handle
  - Test Scenario: Successfully retrieves task by ID with all subtask details
    - Given: GetTaskByIdQuery with Id="550e8400-e29b-41d4-a716-446655440042", task exists with 3 subtasks (2 completed, 1 incomplete)
    - When: Handle is called
    - Then: Repository GetByIdWithSubtasksAsync is called, task returned with subtasks, TaskDetailDto returned with subtasks array populated, subtask completion states correct

[ ] [NEW]: Handle
  - Test Scenario: Successfully retrieves task with zero subtasks
    - Given: GetTaskByIdQuery with Id for task with no subtasks
    - When: Handle is called
    - Then: TaskDetailDto returned with empty Subtasks array

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task does not exist
    - Given: GetTaskByIdQuery with Id="550e8400-e29b-41d4-a716-446655440999", repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '550e8400-e29b-41d4-a716-446655440999' not found"

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task is soft-deleted
    - Given: GetTaskByIdQuery with Id for soft-deleted task, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown indicating task not found

[ ] [NEW]: Handle
  - Test Scenario: Maps ProjectTask Status to TaskDetailDto completed boolean
    - Given: Task with Status=Done exists
    - When: Handle is called
    - Then: TaskDetailDto has Completed=true

[ ] [NEW]: Handle
  - Test Scenario: Includes project information in response when task has project assigned
    - Given: Task exists with ProjectId set and Project navigation property loaded
    - When: Handle is called
    - Then: TaskDetailDto.Project is populated with ProjectInfoDto containing Slug, Name, Color

[ ] [NEW]: Handle
  - Test Scenario: Returns null project when task has no project assigned
    - Given: Task exists with ProjectId=null
    - When: Handle is called
    - Then: TaskDetailDto.Project is null

### src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommandValidator.cs

[ ] [NEW]: Validate
  - Test Scenario: Validation succeeds for valid update command with all fields
    - Given: UpdateTaskCommand with Id set, Title="Updated title", Description="Updated description", ProjectSlug="project-beta"
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors

[ ] [NEW]: Validate
  - Test Scenario: Validation succeeds when updating to null project (unassign)
    - Given: UpdateTaskCommand with Id set, Title="Task title", ProjectSlug=null
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors

[ ] [NEW]: Validate
  - Test Scenario: Validation fails when Title is null
    - Given: UpdateTaskCommand with Title=null
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title is required" is present

[ ] [NEW]: Validate
  - Test Scenario: Validation fails when Title is empty or whitespace only
    - Given: UpdateTaskCommand with Title="" or Title="   "
    - When: Validator.Validate is called
    - Then: IsValid is false, appropriate validation error is present

[ ] [NEW]: Validate
  - Test Scenario: Validation fails when Title exceeds 500 characters
    - Given: UpdateTaskCommand with Title of 501 characters
    - When: Validator.Validate is called
    - Then: IsValid is false, error message about max length is present

### src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommandHandler.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository, IProjectRepository, and IMapper instances
    - When: UpdateTaskCommandHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[ ] [NEW]: Handle
  - Test Scenario: Successfully updates task title and description
    - Given: UpdateTaskCommand with Id for existing task, Title="Updated title", Description="Updated description", ProjectSlug unchanged
    - When: Handle is called
    - Then: Task fetched via GetByIdAsync, task Title and Description updated with trimmed values, UpdateAsync called, TaskDto returned with updated values

[ ] [NEW]: Handle
  - Test Scenario: Successfully updates task project assignment
    - Given: UpdateTaskCommand with Id for task currently assigned to "project-alpha", ProjectSlug="project-beta", target project exists
    - When: Handle is called
    - Then: Task fetched, new project fetched via GetBySlugAsync, task.ProjectId updated to new project ID, UpdateAsync called, task reloaded with GetByIdWithSubtasksAsync, TaskDto returned with new project

[ ] [NEW]: Handle
  - Test Scenario: Successfully unassigns task from project
    - Given: UpdateTaskCommand with Id for task assigned to project, ProjectSlug=null
    - When: Handle is called
    - Then: Task fetched, task.ProjectId set to null, UpdateAsync called, TaskDto returned with null project

[ ] [NEW]: Handle
  - Test Scenario: Trims whitespace from title and description during update
    - Given: UpdateTaskCommand with Title="  New Title  ", Description="  New Description  "
    - When: Handle is called
    - Then: Task updated with Title="New Title", Description="New Description" (trimmed)

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task ID does not exist
    - Given: UpdateTaskCommand with Id="550e8400-e29b-41d4-a716-446655440999", GetByIdAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '...' not found"

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when target project slug does not exist
    - Given: UpdateTaskCommand with valid task Id, ProjectSlug="invalid-project", GetBySlugAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Project with slug 'invalid-project' not found", task remains unchanged

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when attempting to update soft-deleted task
    - Given: UpdateTaskCommand with Id for soft-deleted task, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown, no update operation performed

[ ] [NEW]: Handle
  - Test Scenario: Reloads task with project navigation when ProjectId changes
    - Given: UpdateTaskCommand that changes ProjectSlug to new value
    - When: Handle is called
    - Then: After UpdateAsync, GetByIdWithSubtasksAsync is called to reload task with updated Project navigation property

### src/Taskflow.Application/Features/Tasks/Commands/DeleteTask/DeleteTaskCommandHandler.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository instance
    - When: DeleteTaskCommandHandler constructor is called
    - Then: Constructor succeeds and stores repository dependency

[ ] [NEW]: Handle
  - Test Scenario: Successfully soft deletes task with cascade deletion of subtasks
    - Given: DeleteTaskCommand with Id="550e8400-e29b-41d4-a716-446655440040", task exists with 4 associated subtasks
    - When: Handle is called
    - Then: Task fetched via GetByIdAsync, DeleteAsync called which sets task.DeletedAt and all subtask DeletedAt timestamps, operation completes successfully

[ ] [NEW]: Handle
  - Test Scenario: Successfully deletes task with zero subtasks
    - Given: DeleteTaskCommand with Id for task with no subtasks
    - When: Handle is called
    - Then: Task fetched, DeleteAsync called, soft delete succeeds with no errors

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task ID does not exist
    - Given: DeleteTaskCommand with Id="550e8400-e29b-41d4-a716-446655440999", GetByIdAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '...' not found", no delete operation performed

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task is already soft-deleted
    - Given: DeleteTaskCommand with Id for task with DeletedAt already set, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown indicating task not found

[ ] [NEW]: Handle
  - Test Scenario: Cascade deletion is transactional
    - Given: DeleteTaskCommand with Id for task with multiple subtasks
    - When: Handle is called
    - Then: Repository DeleteAsync performs cascade delete atomically, all subtasks soft-deleted in same transaction with parent task

### src/Taskflow.Application/Features/Tasks/Commands/ToggleTaskCompletion/ToggleTaskCompletionCommandHandler.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository and IMapper instances
    - When: ToggleTaskCompletionCommandHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[ ] [NEW]: Handle
  - Test Scenario: Successfully toggles task from incomplete (Todo) to complete (Done)
    - Given: ToggleTaskCompletionCommand with Id="550e8400-e29b-41d4-a716-446655440030", task has Status=Todo
    - When: Handle is called
    - Then: Task fetched via GetByIdAsync, Status changed to Done, UpdateAsync called, task reloaded, TaskDto returned with Completed=true

[ ] [NEW]: Handle
  - Test Scenario: Successfully toggles task from complete (Done) to incomplete (Todo)
    - Given: ToggleTaskCompletionCommand with Id="550e8400-e29b-41d4-a716-446655440035", task has Status=Done
    - When: Handle is called
    - Then: Task fetched, Status changed to Todo, UpdateAsync called, task reloaded, TaskDto returned with Completed=false

[ ] [NEW]: Handle
  - Test Scenario: Toggles task completion without affecting subtasks completion states
    - Given: ToggleTaskCompletionCommand for task with subtasks having mixed completion states
    - When: Handle is called
    - Then: Task Status toggled, subtasks IsCompleted fields remain unchanged

[ ] [NEW]: Handle
  - Test Scenario: Toggles completion on task with zero subtasks
    - Given: ToggleTaskCompletionCommand for task with no subtasks
    - When: Handle is called
    - Then: Status toggled successfully, no errors due to missing subtasks

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task ID does not exist
    - Given: ToggleTaskCompletionCommand with Id="550e8400-e29b-41d4-a716-446655440999", GetByIdAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '...' not found"

[ ] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task is soft-deleted
    - Given: ToggleTaskCompletionCommand with Id for soft-deleted task, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown, no toggle operation performed

[ ] [NEW]: Handle
  - Test Scenario: Reloads task after status toggle for mapping
    - Given: Valid ToggleTaskCompletionCommand
    - When: Handle is called
    - Then: After UpdateAsync, task is reloaded via GetByIdWithSubtasksAsync to ensure navigation properties are populated for DTO mapping

### src/Taskflow.Api/Controllers/TasksController.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IMediator instance
    - When: TasksController constructor is called
    - Then: Constructor succeeds and stores IMediator for command/query dispatch

[ ] [NEW]: CreateTask
  - Test Scenario: Successfully creates task and returns 201 Created with location header
    - Given: CreateTaskRequest with Title="Implement login", Description="Add OAuth", ProjectSlug="project-alpha"
    - When: POST /api/tasks endpoint is called
    - Then: CreateTaskCommand is sent via mediator, returns 201 Created with TaskDto in ApiResponse envelope, Location header set to /api/tasks/{id}

[ ] [NEW]: CreateTask
  - Test Scenario: Returns 400 Bad Request when validation fails for empty title
    - Given: CreateTaskRequest with Title="" or null
    - When: POST /api/tasks endpoint is called
    - Then: ValidationBehavior throws ValidationException, returns 400 with error details in ApiResponse.Fail

[ ] [NEW]: CreateTask
  - Test Scenario: Returns 404 Not Found when project slug does not exist
    - Given: CreateTaskRequest with ProjectSlug="nonexistent-project"
    - When: POST /api/tasks endpoint is called
    - Then: Handler throws NotFoundException, returns 404 with error message in ApiResponse.Fail

[ ] [NEW]: GetAllTasks
  - Test Scenario: Successfully retrieves all tasks with 200 OK
    - Given: Query parameters projectSlug=null, completed=null
    - When: GET /api/tasks endpoint is called
    - Then: GetAllTasksQuery dispatched, returns 200 OK with List<TaskDto> in ApiResponse.Ok

[ ] [NEW]: GetAllTasks
  - Test Scenario: Successfully filters tasks by projectSlug query parameter
    - Given: Query parameter projectSlug="project-alpha"
    - When: GET /api/tasks?projectSlug=project-alpha is called
    - Then: GetAllTasksQuery with ProjectSlug="project-alpha" dispatched, returns 200 with filtered tasks

[ ] [NEW]: GetAllTasks
  - Test Scenario: Successfully filters tasks by completed query parameter
    - Given: Query parameter completed=true
    - When: GET /api/tasks?completed=true is called
    - Then: GetAllTasksQuery with Completed=true dispatched, returns 200 with only completed tasks

[ ] [NEW]: GetAllTasks
  - Test Scenario: Returns empty array when no tasks exist
    - Given: Database has no tasks
    - When: GET /api/tasks is called
    - Then: Returns 200 OK with empty array in ApiResponse.Ok data

[ ] [NEW]: GetTaskById
  - Test Scenario: Successfully retrieves task by ID with 200 OK
    - Given: Path parameter id="550e8400-e29b-41d4-a716-446655440042"
    - When: GET /api/tasks/{id} endpoint is called
    - Then: GetTaskByIdQuery dispatched with Id, returns 200 OK with TaskDetailDto in ApiResponse.Ok

[ ] [NEW]: GetTaskById
  - Test Scenario: Returns 404 Not Found when task does not exist
    - Given: Path parameter id="550e8400-e29b-41d4-a716-446655440999", task does not exist
    - When: GET /api/tasks/{id} is called
    - Then: Handler throws NotFoundException, returns 404 with error message in ApiResponse.Fail

[ ] [NEW]: UpdateTask
  - Test Scenario: Successfully updates task and returns 200 OK
    - Given: Path parameter id="550e8400-e29b-41d4-a716-446655440015", UpdateTaskRequest with Title="Updated", Description="Updated desc"
    - When: PUT /api/tasks/{id} endpoint is called
    - Then: UpdateTaskCommand dispatched with Id and request data, returns 200 OK with updated TaskDto in ApiResponse.Ok

[ ] [NEW]: UpdateTask
  - Test Scenario: Returns 400 Bad Request when validation fails
    - Given: UpdateTaskRequest with Title="" (empty)
    - When: PUT /api/tasks/{id} is called
    - Then: ValidationBehavior throws ValidationException, returns 400 with validation errors

[ ] [NEW]: UpdateTask
  - Test Scenario: Returns 404 Not Found when task ID does not exist
    - Given: UpdateTaskRequest with Id="550e8400-e29b-41d4-a716-446655440999"
    - When: PUT /api/tasks/{id} is called
    - Then: Handler throws NotFoundException, returns 404 with error message

[ ] [NEW]: UpdateTask
  - Test Scenario: Returns 404 Not Found when target project slug does not exist
    - Given: UpdateTaskRequest with ProjectSlug="invalid-project"
    - When: PUT /api/tasks/{id} is called
    - Then: Handler throws NotFoundException for project, returns 404 with error message

[ ] [NEW]: DeleteTask
  - Test Scenario: Successfully deletes task and returns 204 No Content
    - Given: Path parameter id="550e8400-e29b-41d4-a716-446655440040"
    - When: DELETE /api/tasks/{id} endpoint is called
    - Then: DeleteTaskCommand dispatched with Id, returns 204 No Content with empty body

[ ] [NEW]: DeleteTask
  - Test Scenario: Returns 404 Not Found when task does not exist
    - Given: Path parameter id="550e8400-e29b-41d4-a716-446655440999"
    - When: DELETE /api/tasks/{id} is called
    - Then: Handler throws NotFoundException, returns 404 with error message in ApiResponse.Fail

[ ] [NEW]: ToggleTaskCompletion
  - Test Scenario: Successfully toggles task completion and returns 200 OK
    - Given: Path parameter id="550e8400-e29b-41d4-a716-446655440030"
    - When: PATCH /api/tasks/{id}/toggle-completion endpoint is called
    - Then: ToggleTaskCompletionCommand dispatched with Id, returns 200 OK with updated TaskDto showing toggled completion status

[ ] [NEW]: ToggleTaskCompletion
  - Test Scenario: Returns 404 Not Found when task does not exist
    - Given: Path parameter id="550e8400-e29b-41d4-a716-446655440999"
    - When: PATCH /api/tasks/{id}/toggle-completion is called
    - Then: Handler throws NotFoundException, returns 404 with error message

### src/Taskflow.Application/Features/Tasks/Mappings/TaskMappingProfile.cs

[ ] [NEW]: Constructor
  - Test Scenario: Constructor configures all required AutoMapper mappings
    - Given: TaskMappingProfile is instantiated by AutoMapper
    - When: Profile configuration is executed
    - Then: CreateMap for ProjectTask to TaskDto is configured with custom mappings for Completed (Status==Done), SubtaskCount (Subtasks.Count), CompletedSubtaskCount (Subtasks.Count(IsCompleted)), CreateMap for ProjectTask to TaskDetailDto is configured, CreateMap for Subtask to SubtaskDto with Text mapped from Title is configured, CreateMap for Project to ProjectInfoDto is configured
