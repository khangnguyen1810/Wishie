### src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommandValidator.cs

[x] [NEW]: Validate
  - Test Scenario: Validation succeeds for valid command with all fields
    - Given: CreateTaskCommand with Title="Implement login feature", Description="Add OAuth support", ProjectSlug="project-alpha"
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors

[x] [NEW]: Validate
  - Test Scenario: Validation succeeds for command with only required Title field
    - Given: CreateTaskCommand with Title="Research framework", Description=null, ProjectSlug=null
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors

[x] [NEW]: Validate
  - Test Scenario: Validation fails when Title is null
    - Given: CreateTaskCommand with Title=null
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title is required" is present

[x] [NEW]: Validate
  - Test Scenario: Validation fails when Title is empty string
    - Given: CreateTaskCommand with Title=""
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title is required" is present

[x] [NEW]: Validate
  - Test Scenario: Validation fails when Title contains only whitespace
    - Given: CreateTaskCommand with Title="   " (spaces only)
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title cannot be only whitespace" is present

[x] [NEW]: Validate
  - Test Scenario: Validation fails when Title exceeds 500 characters
    - Given: CreateTaskCommand with Title of 501 characters
    - When: Validator.Validate is called
    - Then: IsValid is false, error message "Task title must not exceed 500 characters" is present

[x] [NEW]: Validate
  - Test Scenario: Validation succeeds when Title is exactly 500 characters
    - Given: CreateTaskCommand with Title of exactly 500 characters
    - When: Validator.Validate is called
    - Then: IsValid is true, no validation errors
