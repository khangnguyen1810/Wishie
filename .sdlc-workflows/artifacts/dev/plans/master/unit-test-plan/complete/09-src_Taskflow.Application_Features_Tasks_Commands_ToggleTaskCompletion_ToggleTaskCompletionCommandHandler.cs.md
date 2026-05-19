### src/Taskflow.Application/Features/Tasks/Commands/ToggleTaskCompletion/ToggleTaskCompletionCommandHandler.cs

[x] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository and IMapper instances
    - When: ToggleTaskCompletionCommandHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[x] [NEW]: Handle
  - Test Scenario: Successfully toggles task from incomplete (Todo) to complete (Done)
    - Given: ToggleTaskCompletionCommand with Id="550e8400-e29b-41d4-a716-446655440030", task has Status=Todo
    - When: Handle is called
    - Then: Task fetched via GetByIdAsync, Status changed to Done, UpdateAsync called, task reloaded, TaskDto returned with Completed=true

[x] [NEW]: Handle
  - Test Scenario: Successfully toggles task from complete (Done) to incomplete (Todo)
    - Given: ToggleTaskCompletionCommand with Id="550e8400-e29b-41d4-a716-446655440035", task has Status=Done
    - When: Handle is called
    - Then: Task fetched, Status changed to Todo, UpdateAsync called, task reloaded, TaskDto returned with Completed=false

[x] [NEW]: Handle
  - Test Scenario: Toggles task completion without affecting subtasks completion states
    - Given: ToggleTaskCompletionCommand for task with subtasks having mixed completion states
    - When: Handle is called
    - Then: Task Status toggled, subtasks IsCompleted fields remain unchanged

[x] [NEW]: Handle
  - Test Scenario: Toggles completion on task with zero subtasks
    - Given: ToggleTaskCompletionCommand for task with no subtasks
    - When: Handle is called
    - Then: Status toggled successfully, no errors due to missing subtasks

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task ID does not exist
    - Given: ToggleTaskCompletionCommand with Id="550e8400-e29b-41d4-a716-446655440999", GetByIdAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '...' not found"

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task is soft-deleted
    - Given: ToggleTaskCompletionCommand with Id for soft-deleted task, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown, no toggle operation performed

[x] [NEW]: Handle
  - Test Scenario: Reloads task after status toggle for mapping
    - Given: Valid ToggleTaskCompletionCommand
    - When: Handle is called
    - Then: After UpdateAsync, task is reloaded via GetByIdWithSubtasksAsync to ensure navigation properties are populated for DTO mapping

