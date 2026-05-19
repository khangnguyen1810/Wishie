# Task Context

## Important Instructions for Implementation

- Follow Clean Architecture with CQRS pattern using MediatR
- Use repository pattern with interfaces in Application layer and implementations in Infrastructure layer
- Apply FluentValidation for all command input validation
- Use AutoMapper for entity-to-DTO mappings with mapping profiles
- Wrap all API responses in `ApiResponse<T>` envelope
- Use soft delete pattern (set `DeletedAt` timestamp, never hard delete)
- Map `ProjectTask.Status` enum to boolean `completed` field in DTOs: `Status == Done` = `completed: true`
- Toggle operation switches between `Todo` and `Done` states only
- Return 400 for validation errors, 404 for not found, 201 for creation, 204 for deletion, 200 for updates
- Use `ConfigureAwait(false)` for all async operations
- Order tasks by `CreatedAt` descending (newest first) in list queries
- Implement cascade delete of subtasks when deleting tasks using EF Core relationship configuration

## Reused Existing Functions/Utilities

- `SlugHelper.GenerateSlug()`: Generate URL-safe slugs from text (src/Taskflow.Application/Common/Helpers/)
- `ApiResponse<T>.Ok()`: Wrap successful responses (src/Taskflow.Application/Common/Models/ApiResponse.cs)
- `ApiResponse<T>.Fail()`: Wrap error responses (src/Taskflow.Application/Common/Models/ApiResponse.cs)
- `NotFoundException`: Custom exception for 404 scenarios (src/Taskflow.Application/Common/Exceptions/NotFoundException.cs)
- `BaseEntity`: Base class with Id, CreatedAt, UpdatedAt, DeletedAt (src/Taskflow.Domain/Common/BaseEntity.cs)
- `ValidationBehavior<TRequest, TResponse>`: MediatR pipeline behavior for FluentValidation (src/Taskflow.Application/Behaviors/ValidationBehavior.cs)

## Shared Contracts

### Entities _(include if feature involves data)_

- **ProjectTask**: Represents a task entity with properties:
  - `Id` (Guid, primary key)
  - `ProjectId` (Guid?, nullable foreign key to `Project`)
  - `ParentTaskId` (Guid?, nullable for future hierarchical tasks)
  - `Title` (string, required, task title)
  - `Description` (string?, optional, task description)
  - `Status` (TaskStatus enum: None=0, Todo=1, InProgress=2, Done=3, Cancelled=4)
  - `Priority` (TaskPriority enum: Low, Medium, High)
  - `DueDate` (DateTime?, optional)
  - `Project` (Project?, navigation property)
  - `ParentTask` (ProjectTask?, navigation property)
  - `SubTasks` (ICollection<ProjectTask>, navigation property)
  - `Subtasks` (ICollection<Subtask>, navigation property for subtask entities)
  - Inherits from `BaseEntity` (Id, CreatedAt, UpdatedAt, DeletedAt)

- **Subtask**: Represents a subtask entity with properties:
  - `Id` (Guid, primary key)
  - `ProjectTaskId` (Guid, foreign key to `ProjectTask`)
  - `Title` (string, required, subtask title/text)
  - `IsCompleted` (bool, completion status)
  - `ProjectTask` (ProjectTask, navigation property)
  - Inherits from `BaseEntity` (Id, CreatedAt, UpdatedAt, DeletedAt)

- **Project**: Represents a project entity with properties:
  - `Id` (Guid, primary key)
  - `Name` (string, required)
  - `Slug` (string, required, unique)
  - `Color` (string, hex color code)
  - `Description` (string?, optional)
  - `Status` (ProjectStatus enum: Active, Archived, Completed)
  - `Tasks` (ICollection<ProjectTask>, navigation property)
  - Inherits from `BaseEntity`

### Interfaces

- **IProjectTaskRepository**: Repository interface for task data operations with methods:
  - `AddAsync(ProjectTask task, CancellationToken)`: Returns Task<ProjectTask>
  - `GetByIdAsync(Guid id, CancellationToken)`: Returns Task<ProjectTask?>
  - `GetByIdWithSubtasksAsync(Guid id, CancellationToken)`: Returns Task<ProjectTask?> with subtasks included
  - `GetAllAsync(string? projectSlug, bool? completed, CancellationToken)`: Returns Task<IEnumerable<ProjectTask>> with filtering
  - `UpdateAsync(ProjectTask task, CancellationToken)`: Returns Task
  - `DeleteAsync(ProjectTask task, CancellationToken)`: Returns Task (soft delete)
  - `GetTaskWithSubtasksForDeleteAsync(Guid id, CancellationToken)`: Returns Task<ProjectTask?> with subtasks for cascade delete

- **IProjectRepository**: Existing repository interface for project data operations (referenced for validation)

### DTOs

- **TaskDto**: Response DTO for task with properties:
  - `Id` (Guid)
  - `Title` (string)
  - `Description` (string?)
  - `Completed` (bool, mapped from Status enum: Status == Done)
  - `Project` (ProjectInfoDto?, includes slug, name, color or null if unassigned)
  - `SubtaskCount` (int, total subtasks)
  - `CompletedSubtaskCount` (int, completed subtasks)

- **TaskDetailDto**: Response DTO for detailed task view with properties:
  - `Id` (Guid)
  - `Title` (string)
  - `Description` (string?)
  - `Completed` (bool, mapped from Status enum)
  - `Project` (ProjectInfoDto?, includes slug, name, color or null)
  - `Subtasks` (List<SubtaskDto>, array of subtasks)

- **SubtaskDto**: Response DTO for subtask with properties:
  - `Id` (Guid)
  - `Text` (string, mapped from Title)
  - `Completed` (bool, mapped from IsCompleted)

- **ProjectInfoDto**: Embedded DTO for project information with properties:
  - `Slug` (string)
  - `Name` (string)
  - `Color` (string)

## Task List

- [x] Task 1: Create Task Repository Interface and Implementation

- 1.1: In file [src/Taskflow.Application/Common/Persistence/IProjectTaskRepository.cs](src/Taskflow.Application/Common/Persistence/IProjectTaskRepository.cs) CREATE
  - Interface `IProjectTaskRepository` with namespace `Taskflow.Application.Common.Persistence`
  - Method `Task<ProjectTask> AddAsync(ProjectTask task, CancellationToken cancellationToken = default)`
  - Method `Task<ProjectTask?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)`
  - Method `Task<ProjectTask?> GetByIdWithSubtasksAsync(Guid id, CancellationToken cancellationToken = default)`
  - Method `Task<IEnumerable<ProjectTask>> GetAllAsync(string? projectSlug = null, bool? completed = null, CancellationToken cancellationToken = default)` with optional filtering parameters
  - Method `Task UpdateAsync(ProjectTask task, CancellationToken cancellationToken = default)`
  - Method `Task DeleteAsync(ProjectTask task, CancellationToken cancellationToken = default)`
  - Using directives: `Taskflow.Domain.Entities`

- 1.2: In file [src/Taskflow.Infrastructure/Persistence/Repositories/ProjectTaskRepository.cs](src/Taskflow.Infrastructure/Persistence/Repositories/ProjectTaskRepository.cs) CREATE
  - Class `ProjectTaskRepository` implementing `IProjectTaskRepository` with namespace `Taskflow.Infrastructure.Persistence.Repositories`
  - Constructor accepting `TaskflowDbContext` parameter named `_dbContext`
  - Implement `AddAsync` method: add task to `_dbContext.Tasks`, call `SaveChangesAsync`, return task
  - Implement `GetByIdAsync` method: use `FirstOrDefaultAsync` on `_dbContext.Tasks` where Id matches, with `ConfigureAwait(false)`
  - Implement `GetByIdWithSubtasksAsync` method: use `_dbContext.Tasks.Include(t => t.Subtasks).Include(t => t.Project).FirstOrDefaultAsync` where Id matches
  - Implement `GetAllAsync` method: query `_dbContext.Tasks.Include(t => t.Project).Include(t => t.Subtasks)`, apply `Where(t => t.ProjectId == project.Id)` if projectSlug provided (after looking up project by slug), apply `Where(t => (t.Status == TaskStatus.Done) == completed.Value)` if completed filter provided, order by `CreatedAt` descending, use `ToListAsync`
  - Implement `UpdateAsync` method: call `_dbContext.Tasks.Update(task)` and `SaveChangesAsync`
  - Implement `DeleteAsync` method: set `task.DeletedAt = DateTime.UtcNow`, call `Update` and `SaveChangesAsync` (soft delete), then manually soft delete all related subtasks by querying and updating them
  - Using directives: `Microsoft.EntityFrameworkCore`, `Taskflow.Application.Common.Persistence`, `Taskflow.Domain.Entities`, `Taskflow.Domain.Enums`

- 1.3: In file [src/Taskflow.Infrastructure/DependencyInjection.cs](src/Taskflow.Infrastructure/DependencyInjection.cs) ADD
  - Service registration: `services.AddScoped<IProjectTaskRepository, ProjectTaskRepository>()` in the existing `AddInfrastructure` method after the `IProjectRepository` registration

- [x] Task 2: Create Task DTOs and AutoMapper Profile

- 2.1: In file [src/Taskflow.Application/Features/Tasks/DTOs/ProjectInfoDto.cs](src/Taskflow.Application/Features/Tasks/DTOs/ProjectInfoDto.cs) CREATE directory `Features/Tasks/DTOs/` and file
  - DTO class `ProjectInfoDto` with namespace `Taskflow.Application.Features.Tasks.DTOs`
  - Properties: `Slug` (string), `Name` (string), `Color` (string)

- 2.2: In file [src/Taskflow.Application/Features/Tasks/DTOs/SubtaskDto.cs](src/Taskflow.Application/Features/Tasks/DTOs/SubtaskDto.cs) CREATE
  - DTO class `SubtaskDto` with namespace `Taskflow.Application.Features.Tasks.DTOs`
  - Properties: `Id` (Guid), `Text` (string), `Completed` (bool)

- 2.3: In file [src/Taskflow.Application/Features/Tasks/DTOs/TaskDto.cs](src/Taskflow.Application/Features/Tasks/DTOs/TaskDto.cs) CREATE
  - DTO class `TaskDto` with namespace `Taskflow.Application.Features.Tasks.DTOs`
  - Properties: `Id` (Guid), `Title` (string), `Description` (string?), `Completed` (bool), `Project` (ProjectInfoDto?), `SubtaskCount` (int), `CompletedSubtaskCount` (int)

- 2.4: In file [src/Taskflow.Application/Features/Tasks/DTOs/TaskDetailDto.cs](src/Taskflow.Application/Features/Tasks/DTOs/TaskDetailDto.cs) CREATE
  - DTO class `TaskDetailDto` with namespace `Taskflow.Application.Features.Tasks.DTOs`
  - Properties: `Id` (Guid), `Title` (string), `Description` (string?), `Completed` (bool), `Project` (ProjectInfoDto?), `Subtasks` (List<SubtaskDto>)

- 2.5: In file [src/Taskflow.Application/Features/Tasks/Mappings/TaskMappingProfile.cs](src/Taskflow.Application/Features/Tasks/Mappings/TaskMappingProfile.cs) CREATE directory `Features/Tasks/Mappings/` and file
  - Class `TaskMappingProfile` inheriting from `Profile` (AutoMapper) with namespace `Taskflow.Application.Features.Tasks.Mappings`
  - Constructor configuring mappings:
    - `CreateMap<ProjectTask, TaskDto>()` with `.ForMember(dest => dest.Completed, opt => opt.MapFrom(src => src.Status == TaskStatus.Done))`, `.ForMember(dest => dest.SubtaskCount, opt => opt.MapFrom(src => src.Subtasks.Count))`, `.ForMember(dest => dest.CompletedSubtaskCount, opt => opt.MapFrom(src => src.Subtasks.Count(s => s.IsCompleted)))`, `.ForMember(dest => dest.Project, opt => opt.MapFrom(src => src.Project))`
    - `CreateMap<ProjectTask, TaskDetailDto>()` with `.ForMember(dest => dest.Completed, opt => opt.MapFrom(src => src.Status == TaskStatus.Done))`, `.ForMember(dest => dest.Subtasks, opt => opt.MapFrom(src => src.Subtasks))`, `.ForMember(dest => dest.Project, opt => opt.MapFrom(src => src.Project))`
    - `CreateMap<Subtask, SubtaskDto>()` with `.ForMember(dest => dest.Text, opt => opt.MapFrom(src => src.Title))`, `.ForMember(dest => dest.Completed, opt => opt.MapFrom(src => src.IsCompleted))`
    - `CreateMap<Project, ProjectInfoDto>()`
  - Using directives: `AutoMapper`, `Taskflow.Domain.Entities`, `Taskflow.Domain.Enums`, `Taskflow.Application.Features.Tasks.DTOs`

- [x] Task 3: Implement Create Task Command

- 3.1: In file [src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommand.cs](src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommand.cs) CREATE directory `Features/Tasks/Commands/CreateTask/` and file
  - Record `CreateTaskCommand` with namespace `Taskflow.Application.Features.Tasks.Commands.CreateTask`
  - Parameters: `Title` (string), `Description` (string?), `ProjectSlug` (string?)
  - Implements `IRequest<TaskDto>` from MediatR
  - Using directives: `MediatR`, `Taskflow.Application.Features.Tasks.DTOs`

- 3.2: In file [src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommandValidator.cs](src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommandValidator.cs) CREATE
  - Class `CreateTaskCommandValidator` inheriting from `AbstractValidator<CreateTaskCommand>` with namespace `Taskflow.Application.Features.Tasks.Commands.CreateTask`
  - Constructor with rules:
    - `RuleFor(x => x.Title).NotEmpty().WithMessage("Task title is required")`
    - `RuleFor(x => x.Title).Must(title => !string.IsNullOrWhiteSpace(title)).WithMessage("Task title cannot be only whitespace")`
    - `RuleFor(x => x.Title).MaximumLength(500).WithMessage("Task title must not exceed 500 characters")`
  - Using directives: `FluentValidation`

- 3.3: In file [src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommandHandler.cs](src/Taskflow.Application/Features/Tasks/Commands/CreateTask/CreateTaskCommandHandler.cs) CREATE
  - Class `CreateTaskCommandHandler` implementing `IRequestHandler<CreateTaskCommand, TaskDto>` with namespace `Taskflow.Application.Features.Tasks.Commands.CreateTask`
  - Constructor dependencies: `IProjectTaskRepository _taskRepository`, `IProjectRepository _projectRepository`, `IMapper _mapper`
  - `Handle` method implementation:
    - Validate `request` is not null with `ArgumentNullException.ThrowIfNull(request)`
    - If `request.ProjectSlug` is not null: lookup project using `_projectRepository.GetBySlugAsync(request.ProjectSlug)`, throw `NotFoundException` with message "Project with slug '{slug}' not found" if null
    - Create new `ProjectTask` instance with `Title = request.Title.Trim()`, `Description = request.Description?.Trim()`, `ProjectId = project?.Id`, `Status = TaskStatus.Todo`
    - Call `await _taskRepository.AddAsync(task, cancellationToken).ConfigureAwait(false)`
    - If task has ProjectId, reload task with project using `_taskRepository.GetByIdWithSubtasksAsync` to include navigation properties
    - Return `_mapper.Map<TaskDto>(task)`
  - Using directives: `AutoMapper`, `MediatR`, `Taskflow.Application.Common.Exceptions`, `Taskflow.Application.Common.Persistence`, `Taskflow.Application.Features.Tasks.DTOs`, `Taskflow.Domain.Entities`, `Taskflow.Domain.Enums`

- [x] Task 4: Implement List Tasks Query

- 4.1: In file [src/Taskflow.Application/Features/Tasks/Queries/GetAllTasks/GetAllTasksQuery.cs](src/Taskflow.Application/Features/Tasks/Queries/GetAllTasks/GetAllTasksQuery.cs) CREATE directory `Features/Tasks/Queries/GetAllTasks/` and file
  - Record `GetAllTasksQuery` with namespace `Taskflow.Application.Features.Tasks.Queries.GetAllTasks`
  - Parameters: `ProjectSlug` (string?), `Completed` (bool?)
  - Implements `IRequest<IEnumerable<TaskDto>>` from MediatR
  - Using directives: `MediatR`, `Taskflow.Application.Features.Tasks.DTOs`

- 4.2: In file [src/Taskflow.Application/Features/Tasks/Queries/GetAllTasks/GetAllTasksQueryHandler.cs](src/Taskflow.Application/Features/Tasks/Queries/GetAllTasks/GetAllTasksQueryHandler.cs) CREATE
  - Class `GetAllTasksQueryHandler` implementing `IRequestHandler<GetAllTasksQuery, IEnumerable<TaskDto>>` with namespace `Taskflow.Application.Features.Tasks.Queries.GetAllTasks`
  - Constructor dependencies: `IProjectTaskRepository _taskRepository`, `IMapper _mapper`
  - `Handle` method implementation:
    - Call `var tasks = await _taskRepository.GetAllAsync(request.ProjectSlug, request.Completed, cancellationToken).ConfigureAwait(false)`
    - Return `_mapper.Map<IEnumerable<TaskDto>>(tasks)`
  - Using directives: `AutoMapper`, `MediatR`, `Taskflow.Application.Common.Persistence`, `Taskflow.Application.Features.Tasks.DTOs`

- [x] Task 5: Implement Get Task Detail Query

- 5.1: In file [src/Taskflow.Application/Features/Tasks/Queries/GetTaskById/GetTaskByIdQuery.cs](src/Taskflow.Application/Features/Tasks/Queries/GetTaskById/GetTaskByIdQuery.cs) CREATE directory `Features/Tasks/Queries/GetTaskById/` and file
  - Record `GetTaskByIdQuery` with namespace `Taskflow.Application.Features.Tasks.Queries.GetTaskById`
  - Parameter: `Id` (Guid)
  - Implements `IRequest<TaskDetailDto>` from MediatR
  - Using directives: `MediatR`, `Taskflow.Application.Features.Tasks.DTOs`

- 5.2: In file [src/Taskflow.Application/Features/Tasks/Queries/GetTaskById/GetTaskByIdQueryHandler.cs](src/Taskflow.Application/Features/Tasks/Queries/GetTaskById/GetTaskByIdQueryHandler.cs) CREATE
  - Class `GetTaskByIdQueryHandler` implementing `IRequestHandler<GetTaskByIdQuery, TaskDetailDto>` with namespace `Taskflow.Application.Features.Tasks.Queries.GetTaskById`
  - Constructor dependencies: `IProjectTaskRepository _taskRepository`, `IMapper _mapper`
  - `Handle` method implementation:
    - Call `var task = await _taskRepository.GetByIdWithSubtasksAsync(request.Id, cancellationToken).ConfigureAwait(false)`
    - If task is null, throw `NotFoundException` with message "Task not found"
    - Return `_mapper.Map<TaskDetailDto>(task)`
  - Using directives: `AutoMapper`, `MediatR`, `Taskflow.Application.Common.Exceptions`, `Taskflow.Application.Common.Persistence`, `Taskflow.Application.Features.Tasks.DTOs`

- [x] Task 6: Implement Update Task Command

- 6.1: In file [src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommand.cs](src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommand.cs) CREATE directory `Features/Tasks/Commands/UpdateTask/` and file
  - Record `UpdateTaskCommand` with namespace `Taskflow.Application.Features.Tasks.Commands.UpdateTask`
  - Parameters: `Id` (Guid), `Title` (string?), `Description` (string?), `ProjectSlug` (string?)
  - Implements `IRequest<TaskDto>` from MediatR
  - Using directives: `MediatR`, `Taskflow.Application.Features.Tasks.DTOs`

- 6.2: In file [src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommandValidator.cs](src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommandValidator.cs) CREATE
  - Class `UpdateTaskCommandValidator` inheriting from `AbstractValidator<UpdateTaskCommand>` with namespace `Taskflow.Application.Features.Tasks.Commands.UpdateTask`
  - Constructor with rules:
    - `RuleFor(x => x.Title).Must(title => string.IsNullOrEmpty(title) || !string.IsNullOrWhiteSpace(title)).WithMessage("Task title cannot be only whitespace").When(x => !string.IsNullOrEmpty(x.Title))`
    - `RuleFor(x => x.Title).MaximumLength(500).WithMessage("Task title must not exceed 500 characters").When(x => !string.IsNullOrEmpty(x.Title))`
  - Using directives: `FluentValidation`

- 6.3: In file [src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommandHandler.cs](src/Taskflow.Application/Features/Tasks/Commands/UpdateTask/UpdateTaskCommandHandler.cs) CREATE
  - Class `UpdateTaskCommandHandler` implementing `IRequestHandler<UpdateTaskCommand, TaskDto>` with namespace `Taskflow.Application.Features.Tasks.Commands.UpdateTask`
  - Constructor dependencies: `IProjectTaskRepository _taskRepository`, `IProjectRepository _projectRepository`, `IMapper _mapper`
  - `Handle` method implementation:
    - Validate `request` is not null with `ArgumentNullException.ThrowIfNull(request)`
    - Get existing task: `var task = await _taskRepository.GetByIdAsync(request.Id, cancellationToken).ConfigureAwait(false)`, throw `NotFoundException` with message "Task not found" if null
    - If `request.Title` is not null, update `task.Title = request.Title.Trim()`
    - If `request.Description` is provided (including empty string), update `task.Description = string.IsNullOrEmpty(request.Description) ? null : request.Description.Trim()`
    - If `request.ProjectSlug` is provided: if empty string or null, set `task.ProjectId = null`, otherwise lookup project using `_projectRepository.GetBySlugAsync(request.ProjectSlug)` and set `task.ProjectId = project.Id` (throw `NotFoundException` with message "Project with slug '{slug}' not found" if project not found)
    - Call `await _taskRepository.UpdateAsync(task, cancellationToken).ConfigureAwait(false)`
    - Reload task with subtasks and project: `task = await _taskRepository.GetByIdWithSubtasksAsync(task.Id, cancellationToken).ConfigureAwait(false)`
    - Return `_mapper.Map<TaskDto>(task!)`
  - Using directives: `AutoMapper`, `MediatR`, `Taskflow.Application.Common.Exceptions`, `Taskflow.Application.Common.Persistence`, `Taskflow.Application.Features.Tasks.DTOs`, `Taskflow.Domain.Entities`

- [x] Task 7: Implement Delete Task Command with Cascade

- 7.1: In file [src/Taskflow.Application/Features/Tasks/Commands/DeleteTask/DeleteTaskCommand.cs](src/Taskflow.Application/Features/Tasks/Commands/DeleteTask/DeleteTaskCommand.cs) CREATE directory `Features/Tasks/Commands/DeleteTask/` and file
  - Record `DeleteTaskCommand` with namespace `Taskflow.Application.Features.Tasks.Commands.DeleteTask`
  - Parameter: `Id` (Guid)
  - Implements `IRequest` from MediatR (returns void/Unit)
  - Using directives: `MediatR`

- 7.2: In file [src/Taskflow.Application/Features/Tasks/Commands/DeleteTask/DeleteTaskCommandHandler.cs](src/Taskflow.Application/Features/Tasks/Commands/DeleteTask/DeleteTaskCommandHandler.cs) CREATE
  - Class `DeleteTaskCommandHandler` implementing `IRequestHandler<DeleteTaskCommand>` with namespace `Taskflow.Application.Features.Tasks.Commands.DeleteTask`
  - Constructor dependency: `IProjectTaskRepository _taskRepository`
  - `Handle` method implementation:
    - Validate `request` is not null with `ArgumentNullException.ThrowIfNull(request)`
    - Get task: `var task = await _taskRepository.GetByIdAsync(request.Id, cancellationToken).ConfigureAwait(false)`, throw `NotFoundException` with message "Task not found" if null
    - Call `await _taskRepository.DeleteAsync(task, cancellationToken).ConfigureAwait(false)` (which handles cascade soft delete of subtasks)
    - Return `Unit.Value`
  - Using directives: `MediatR`, `Taskflow.Application.Common.Exceptions`, `Taskflow.Application.Common.Persistence`

- [x] Task 8: Implement Toggle Task Completion Command

- 8.1: In file [src/Taskflow.Application/Features/Tasks/Commands/ToggleTaskCompletion/ToggleTaskCompletionCommand.cs](src/Taskflow.Application/Features/Tasks/Commands/ToggleTaskCompletion/ToggleTaskCompletionCommand.cs) CREATE directory `Features/Tasks/Commands/ToggleTaskCompletion/` and file
  - Record `ToggleTaskCompletionCommand` with namespace `Taskflow.Application.Features.Tasks.Commands.ToggleTaskCompletion`
  - Parameter: `Id` (Guid)
  - Implements `IRequest<TaskDto>` from MediatR
  - Using directives: `MediatR`, `Taskflow.Application.Features.Tasks.DTOs`

- 8.2: In file [src/Taskflow.Application/Features/Tasks/Commands/ToggleTaskCompletion/ToggleTaskCompletionCommandHandler.cs](src/Taskflow.Application/Features/Tasks/Commands/ToggleTaskCompletion/ToggleTaskCompletionCommandHandler.cs) CREATE
  - Class `ToggleTaskCompletionCommandHandler` implementing `IRequestHandler<ToggleTaskCompletionCommand, TaskDto>` with namespace `Taskflow.Application.Features.Tasks.Commands.ToggleTaskCompletion`
  - Constructor dependencies: `IProjectTaskRepository _taskRepository`, `IMapper _mapper`
  - `Handle` method implementation:
    - Validate `request` is not null with `ArgumentNullException.ThrowIfNull(request)`
    - Get task: `var task = await _taskRepository.GetByIdAsync(request.Id, cancellationToken).ConfigureAwait(false)`, throw `NotFoundException` with message "Task not found" if null
    - Toggle status: `task.Status = task.Status == TaskStatus.Done ? TaskStatus.Todo : TaskStatus.Done`
    - Call `await _taskRepository.UpdateAsync(task, cancellationToken).ConfigureAwait(false)`
    - Reload task with subtasks and project: `task = await _taskRepository.GetByIdWithSubtasksAsync(task.Id, cancellationToken).ConfigureAwait(false)`
    - Return `_mapper.Map<TaskDto>(task!)`
  - Using directives: `AutoMapper`, `MediatR`, `Taskflow.Application.Common.Exceptions`, `Taskflow.Application.Common.Persistence`, `Taskflow.Application.Features.Tasks.DTOs`, `Taskflow.Domain.Enums`

- [x] Task 9: Create Tasks Controller with API Endpoints

- 9.1: In file [src/Taskflow.Api/Controllers/CreateTaskRequest.cs](src/Taskflow.Api/Controllers/CreateTaskRequest.cs) CREATE
  - Record `CreateTaskRequest` with namespace `Taskflow.Api.Controllers`
  - Properties: `Title` (string), `Description` (string?), `ProjectSlug` (string?)

- 9.2: In file [src/Taskflow.Api/Controllers/UpdateTaskRequest.cs](src/Taskflow.Api/Controllers/UpdateTaskRequest.cs) CREATE
  - Record `UpdateTaskRequest` with namespace `Taskflow.Api.Controllers`
  - Properties: `Title` (string?), `Description` (string?), `ProjectSlug` (string?)

- 9.3: In file [src/Taskflow.Api/Controllers/TasksController.cs](src/Taskflow.Api/Controllers/TasksController.cs) CREATE
  - Class `TasksController` inheriting from `ControllerBase` with namespace `Taskflow.Api.Controllers`
  - Attributes: `[ApiController]`, `[Route("api/tasks")]`
  - Constructor dependency: `IMediator _mediator`
  - POST endpoint `CreateTask`:
    - Attribute: `[HttpPost]`, `[ProducesResponseType(StatusCodes.Status201Created)]`, `[ProducesResponseType(StatusCodes.Status400BadRequest)]`
    - Parameters: `[FromBody] CreateTaskRequest request`, `CancellationToken cancellationToken`
    - Implementation: validate request not null, create `CreateTaskCommand` using `CreateTaskCommand` from Task 3.1, send via `_mediator.Send`, return `CreatedAtAction(nameof(GetTaskById), new { id = result.Id }, ApiResponse<TaskDto>.Ok(result))`
  - GET list endpoint `GetAllTasks`:
    - Attribute: `[HttpGet]`, `[ProducesResponseType(StatusCodes.Status200OK)]`
    - Parameters: `[FromQuery] string? projectSlug`, `[FromQuery] bool? completed`, `CancellationToken cancellationToken`
    - Implementation: create `GetAllTasksQuery` using `GetAllTasksQuery` from Task 4.1 with provided filters, send via `_mediator.Send`, return `Ok(ApiResponse<IEnumerable<TaskDto>>.Ok(result))`
  - GET by ID endpoint `GetTaskById`:
    - Attribute: `[HttpGet("{id:guid}")]`, `[ProducesResponseType(StatusCodes.Status200OK)]`, `[ProducesResponseType(StatusCodes.Status404NotFound)]`
    - Parameters: `Guid id`, `CancellationToken cancellationToken`
    - Implementation: create `GetTaskByIdQuery` using `GetTaskByIdQuery` from Task 5.1, send via `_mediator.Send`, return `Ok(ApiResponse<TaskDetailDto>.Ok(result))`
  - PUT endpoint `UpdateTask`:
    - Attribute: `[HttpPut("{id:guid}")]`, `[ProducesResponseType(StatusCodes.Status200OK)]`, `[ProducesResponseType(StatusCodes.Status400BadRequest)]`, `[ProducesResponseType(StatusCodes.Status404NotFound)]`
    - Parameters: `Guid id`, `[FromBody] UpdateTaskRequest request`, `CancellationToken cancellationToken`
    - Implementation: validate request not null, create `UpdateTaskCommand` using `UpdateTaskCommand` from Task 6.1, send via `_mediator.Send`, return `Ok(ApiResponse<TaskDto>.Ok(result))`
  - DELETE endpoint `DeleteTask`:
    - Attribute: `[HttpDelete("{id:guid}")]`, `[ProducesResponseType(StatusCodes.Status204NoContent)]`, `[ProducesResponseType(StatusCodes.Status404NotFound)]`
    - Parameters: `Guid id`, `CancellationToken cancellationToken`
    - Implementation: create `DeleteTaskCommand` using `DeleteTaskCommand` from Task 7.1, send via `_mediator.Send`, return `NoContent()`
  - PATCH toggle endpoint `ToggleTaskCompletion`:
    - Attribute: `[HttpPatch("{id:guid}/toggle")]`, `[ProducesResponseType(StatusCodes.Status200OK)]`, `[ProducesResponseType(StatusCodes.Status404NotFound)]`
    - Parameters: `Guid id`, `CancellationToken cancellationToken`
    - Implementation: create `ToggleTaskCompletionCommand` using `ToggleTaskCompletionCommand` from Task 8.1, send via `_mediator.Send`, return `Ok(ApiResponse<TaskDto>.Ok(result))`
  - Using directives: `MediatR`, `Microsoft.AspNetCore.Mvc`, `Taskflow.Application.Common.Models`, `Taskflow.Application.Features.Tasks.Commands.CreateTask`, `Taskflow.Application.Features.Tasks.Commands.UpdateTask`, `Taskflow.Application.Features.Tasks.Commands.DeleteTask`, `Taskflow.Application.Features.Tasks.Commands.ToggleTaskCompletion`, `Taskflow.Application.Features.Tasks.Queries.GetAllTasks`, `Taskflow.Application.Features.Tasks.Queries.GetTaskById`, `Taskflow.Application.Features.Tasks.DTOs`
