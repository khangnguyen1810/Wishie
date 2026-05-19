### src/Taskflow.Application/Features/Tasks/Queries/GetTaskById/GetTaskByIdQueryHandler.cs

[x] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository and IMapper instances
    - When: GetTaskByIdQueryHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[x] [NEW]: Handle
  - Test Scenario: Successfully retrieves task by ID with all subtask details
    - Given: GetTaskByIdQuery with Id="550e8400-e29b-41d4-a716-446655440042", task exists with 3 subtasks (2 completed, 1 incomplete)
    - When: Handle is called
    - Then: Repository GetByIdWithSubtasksAsync is called, task returned with subtasks, TaskDetailDto returned with subtasks array populated, subtask completion states correct

[x] [NEW]: Handle
  - Test Scenario: Successfully retrieves task with zero subtasks
    - Given: GetTaskByIdQuery with Id for task with no subtasks
    - When: Handle is called
    - Then: TaskDetailDto returned with empty Subtasks array

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task does not exist
    - Given: GetTaskByIdQuery with Id="550e8400-e29b-41d4-a716-446655440999", repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown with message "Task with ID '550e8400-e29b-41d4-a716-446655440999' not found"

[x] [NEW]: Handle
  - Test Scenario: Throws NotFoundException when task is soft-deleted
    - Given: GetTaskByIdQuery with Id for soft-deleted task, repository returns null
    - When: Handle is called
    - Then: NotFoundException is thrown indicating task not found

[x] [NEW]: Handle
  - Test Scenario: Maps ProjectTask Status to TaskDetailDto completed boolean
    - Given: Task with Status=Done exists
    - When: Handle is called
    - Then: TaskDetailDto has Completed=true

[x] [NEW]: Handle
  - Test Scenario: Includes project information in response when task has project assigned
    - Given: Task exists with ProjectId set and Project navigation property loaded
    - When: Handle is called
    - Then: TaskDetailDto.Project is populated with ProjectInfoDto containing Slug, Name, Color

[x] [NEW]: Handle
  - Test Scenario: Returns null project when task has no project assigned
    - Given: Task exists with ProjectId=null
    - When: Handle is called
    - Then: TaskDetailDto.Project is null

