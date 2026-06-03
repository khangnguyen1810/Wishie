### src/Taskflow.Application/Features/Tasks/Commands/DeleteTask/DeleteTaskCommandHandler.cs

[x] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository instance
    - When: DeleteTaskCommandHandler constructor is called
    - Then: Constructor succeeds and stores repository dependency

[x] [NEW]: Handle
  - Test Scenario: Successfully soft deletes task with cascade deletion of subtasks
    - Given: DeleteTaskCommand with Id="550e8400-e29b-41d4-a716-446655440040", task exists with 4 associated subtasks
    - When: Handle is called
    - Then: Task fetched via GetByIdAsync, DeleteAsync called which sets task.DeletedAt and all subtask DeletedAt timestamps, operation completes successfully

[x] [NEW]: Handle
  - Test Scenario: Successfully deletes task with zero subtasks
    - Given: DeleteTaskCommand with Id for task with no subtasks
    - When: Handle is called
    - Then: Task fetched, DeleteAsync called, soft delete succeeds with no errors

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task ID does not exist
    - Given: DeleteTaskCommand with Id="550e8400-e29b-41d4-a716-446655440999", GetByIdAsync returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '...' not found", no delete operation performed

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task is already soft-deleted
    - Given: DeleteTaskCommand with Id for task with DeletedAt already set, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown indicating task not found

[x] [NEW]: Handle
  - Test Scenario: Cascade deletion is transactional
    - Given: DeleteTaskCommand with Id for task with multiple subtasks
    - When: Handle is called
    - Then: Repository DeleteAsync performs cascade delete atomically, all subtasks soft-deleted in same transaction with parent task

