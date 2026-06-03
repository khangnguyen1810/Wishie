### src/Taskflow.Application/Features/Tasks/Queries/GetAllTasks/GetAllTasksQueryHandler.cs

[x] [NEW]: Constructor
  - Test Scenario: Constructor accepts and stores all dependencies
    - Given: Valid IProjectTaskRepository and IMapper instances
    - When: GetAllTasksQueryHandler constructor is called
    - Then: Constructor succeeds and stores dependencies

[x] [NEW]: Handle
  - Test Scenario: Successfully retrieves all tasks with subtask counts
    - Given: GetAllTasksQuery with ProjectSlug=null, Completed=null, and 5 tasks exist with various subtask counts
    - When: Handle is called
    - Then: Repository GetAllAsync is called with no filters, returns all tasks, each TaskDto includes totalSubtasks and completedSubtasks counts, tasks ordered by CreatedAt descending

[x] [NEW]: Handle
  - Test Scenario: Successfully filters tasks by project slug
    - Given: GetAllTasksQuery with ProjectSlug="project-alpha", tasks exist for multiple projects
    - When: Handle is called
    - Then: Repository GetAllAsync is called with projectSlug="project-alpha", returns only tasks for that project, TaskDto list returned

[x] [NEW]: Handle
  - Test Scenario: Successfully filters tasks by completion status true
    - Given: GetAllTasksQuery with Completed=true, tasks with Status=Done and Status=Todo exist
    - When: Handle is called
    - Then: Repository GetAllAsync is called with completed=true, returns only tasks with Status==Done, completed field in DTOs is true

[x] [NEW]: Handle
  - Test Scenario: Successfully filters tasks by completion status false
    - Given: GetAllTasksQuery with Completed=false, tasks with various statuses exist
    - When: Handle is called
    - Then: Repository GetAllAsync is called with completed=false, returns only tasks with Status!=Done, completed field in DTOs is false

[x] [NEW]: Handle
  - Test Scenario: Applies both projectSlug and completed filters simultaneously
    - Given: GetAllTasksQuery with ProjectSlug="project-beta" and Completed=true
    - When: Handle is called
    - Then: Repository GetAllAsync is called with both filters, returns only tasks matching both criteria

[x] [NEW]: Handle
  - Test Scenario: Returns empty list when no tasks exist
    - Given: GetAllTasksQuery with no filters, database has zero tasks
    - When: Handle is called
    - Then: Repository GetAllAsync returns empty collection, empty List<TaskDto> is returned

[x] [NEW]: Handle
  - Test Scenario: Maps Status enum to completed boolean correctly in DTOs
    - Given: Tasks with Status=Done and Status=Todo exist
    - When: Handle is called
    - Then: TaskDto for Status=Done has Completed=true, TaskDto for Status=Todo has Completed=false

