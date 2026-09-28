

## 1. The Mental Model: A Restaurant Kitchen

Think of your Spring Boot application as a **restaurant kitchen**:

- **The Controller** is the **waiter**: takes the order (HTTP request), brings it to the kitchen, and delivers the finished dish (HTTP response). The waiter doesn't cook.
- **The Service** is the **head chef**: knows the recipes (business logic), decides what ingredients are needed, and coordinates the line cooks.
- **The Repository** is the **pantry manager**: knows where every ingredient is stored (database) and fetches it when the chef asks.
- **The Entity** is the **raw ingredient**: it has intrinsic properties (freshness, quantity) and must follow food safety rules (business invariants).
- **The DTO** is the **menu item**: what the customer actually sees and orders. It's a curated description of the dish, not the raw ingredient list.
- **The Mapper** is the **translator** between the menu and the kitchen: converts the customer's order (DTO) into something the kitchen understands (Entity), and vice versa.
- **The Enum** is the **standardized label** (e.g., "Rare", "Medium", "Well-Done"): it ensures everyone uses the same vocabulary for fixed sets of values.
- **The Exception Handler** is the **complaint department**: when something goes wrong, it produces a polite, standardized apology (error response) instead of letting the kitchen collapse in chaos.

This layered flow — Controller → Service → Repository → Database, with DTOs and Mappers at the boundaries — is the **default layered architecture** of Spring Boot. Each layer has a single responsibility, and dependencies flow in one direction: `entity ← repository ← service ← controller`, with `entity ← dto` as a parallel branch.

---

## 2. The DoItLater Project: What Each Layer Does

Let's trace a single HTTP request through your project structure to understand why every class exists.

### 2.1 The Request Flow

```
Client sends POST /api/tasks with JSON body
    ↓
TaskController.createTask(@RequestBody CreateTaskRequestDto request)
    ↓
TaskMapper.toEntity(request)  ← DTO → Entity
    ↓
TaskServiceImpl.createTask(task)
    ↓
TaskRepository.save(task)
    ↓
Database INSERT
    ↓
TaskMapper.toDto(savedTask)  ← Entity → DTO
    ↓
TaskController returns ResponseEntity<TaskDto>
    ↓
Client receives JSON response
```

### 2.2 Why Each Class Exists

| Class | Package | Role | Why It Exists |
|---|---|---|---|
| `DoItLaterApplication` | root | `@SpringBootApplication` | Entry point. Defines the component-scan base package. Must be in the root package so Spring scans everything below it. |
| `CrossConfig` | `configuration` | `@Configuration` | Cross-cutting configuration: CORS, Jackson customization, auditing, etc. Keeps infrastructure concerns out of domain packages. |
| `Task` | `taskTracker/domain/entity` | JPA `@Entity` | Maps to the `tasks` table. Holds the persistent state and enforces business invariants. |
| `TaskStatus` | `taskTracker/domain/entity` | Enum | Fixed set of task states (`TODO`, `IN_PROGRESS`, `DONE`). `@Enumerated(EnumType.STRING)` stores it as a string, safe against ordinal reordering. |
| `TaskPriority` | `taskTracker/domain/entity` | Enum | Fixed set of priorities (`LOW`, `MEDIUM`, `HIGH`). Same rationale. |
| `CreateTaskRequestDto` | `taskTracker/domain/dto` | Java Record | Validates and carries data from the client to the service. Contains only fields the client is allowed to set. |
| `UpdateTaskRequestDto` | `taskTracker/domain/dto` | Java Record | Same as above but for updates. Separate from create because update rules may differ (e.g., `id` is required, `status` may be settable). |
| `TaskDto` | `taskTracker/domain/dto` | Java Record | The response contract. Contains only fields the client should see (no internal audit columns, no lazy associations). |
| `ErrorDto` | `taskTracker/domain/dto` | Java Record | Standardized error response shape. Used by `GlobalExceptionHandler`. |
| `CreateTaskRequest` | `taskTracker/domain` | Class/Record | **Redundant with `CreateTaskRequestDto`**. This appears to be a leftover or an alternative representation. In a clean design, there should be exactly one request DTO per operation. |
| `UpdateTaskRequest` | `taskTracker/domain` | Class/Record | Same issue — redundant with `UpdateTaskRequestDto`. |
| `TaskRepository` | `taskTracker/Repository` | Interface extending `JpaRepository` | Spring Data generates the implementation. Provides CRUD + query methods. No manual implementation needed. |
| `TaskService` | `taskTracker/service` | Interface | Defines the business operations contract. Allows swapping implementations and mocking in tests. |
| `TaskServiceImpl` | `taskTracker/service/Impl` | `@Service` class | Implements `TaskService`. Contains `@Transactional` business logic. Calls `TaskRepository` and `TaskMapper`. |
| `TaskMapper` | `taskTracker/mapper` | Interface | Defines the conversion contract between entities and DTOs. |
| `TaskMapperImpl` | `taskTracker/mapper/Impl` | `@Component` | Manual implementation of `TaskMapper`. (If using MapStruct, this would be generated.) |
| `TaskController` | `taskTracker/controller` | `@RestController` | Handles HTTP concerns: routing, validation (`@Valid`), status codes. Delegates all business logic to `TaskService`. |
| `TaskNotFoundException` | `taskTracker/exception` | `RuntimeException` | Domain-specific exception. Thrown by the service when a task ID doesn't exist. |
| `GlobalExceptionHandler` | `taskTracker/exception` | `@RestControllerAdvice` | Catches `TaskNotFoundException` (and other exceptions), converts them to `ErrorDto` with appropriate HTTP status. Centralizes error handling so controllers stay clean. |

### 2.3 Why Enums Instead of Strings

Using `TaskStatus.TODO` instead of `"TODO"` gives you:

1. **Type safety**: The compiler rejects `TaskStatus.TYPO`. A string would silently accept it.
2. **IDE autocomplete**: You see all valid values.
3. **`@Enumerated(EnumType.STRING)`**: Stores the enum name (`"TODO"`) in the database. If you later reorder the enum constants, existing data remains correct. Using `EnumType.ORDINAL` (the default) would corrupt data if constants are reordered.

---

## 3. Step-by-Step: How This Project Was Built (TaskTracker Module)

The order below is **not arbitrary** — each step depends on the previous one.

### Step 1: Define the Domain Model (Entities + Enums)

**Create `Task` entity and `TaskStatus`/`TaskPriority` enums first.**

Why first: Everything else — DTOs, repositories, services — depends on the shape of the entity. If you build DTOs first, you'll rewrite them when the entity changes.

```java
@Entity
@Table(name = "tasks")
public class Task {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TaskStatus status = TaskStatus.TODO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TaskPriority priority = TaskPriority.MEDIUM;

    @Column(name = "due_date")
    private LocalDate dueDate;

    // constructors, getters, business methods
}
```

### Step 2: Create the Repository

**Create `TaskRepository` interface extending `JpaRepository<Task, Long>`.**

Why second: The repository is the persistence gateway. It's an interface — Spring Data generates the implementation at runtime. No code to write beyond the interface declaration and any custom query methods.

```java
public interface TaskRepository extends JpaRepository<Task, Long> {
    List<Task> findByStatus(TaskStatus status);
    List<Task> findByPriority(TaskPriority priority);
}
```

### Step 3: Create the DTOs (Records)

**Create `CreateTaskRequestDto`, `UpdateTaskRequestDto`, `TaskDto`, `ErrorDto`.**

Why third: DTOs are the API contract. They depend on the entity's fields but are **separate classes** because the client should not see internal fields (e.g., audit columns) and should not set fields it doesn't own (e.g., `id` on create).

```java
public record CreateTaskRequestDto(
    @NotBlank String title,
    String description,
    @NotNull TaskPriority priority,
    LocalDate dueDate
) {}

public record TaskDto(
    Long id,
    String title,
    String description,
    TaskStatus status,
    TaskPriority priority,
    LocalDate dueDate,
    LocalDateTime createdAt
) {}
```

### Step 4: Create the Mapper

**Create `TaskMapper` interface and `TaskMapperImpl`.**

Why fourth: The mapper translates between the entity world and the DTO world. It sits between the controller and the service. Without it, mapping logic leaks into controllers or services, violating single responsibility.

```java
public interface TaskMapper {
    Task toEntity(CreateTaskRequestDto dto);
    TaskDto toDto(Task entity);
    void updateEntityFromDto(UpdateTaskRequestDto dto, @MappingTarget Task entity);
}
```

### Step 5: Create the Service Interface

**Create `TaskService` interface.**

Why fifth: The interface defines **what** the application can do with tasks, without specifying **how**. This allows the controller to depend on an abstraction, and tests to mock the service easily.

```java
public interface TaskService {
    TaskDto createTask(CreateTaskRequestDto request);
    TaskDto getTask(Long id);
    List<TaskDto> getAllTasks();
    TaskDto updateTask(Long id, UpdateTaskRequestDto request);
    void deleteTask(Long id);
}
```

### Step 6: Implement the Service

**Create `TaskServiceImpl` with `@Service` and `@Transactional`.**

Why sixth: Now you have everything the service needs: the repository (persistence), the mapper (translation), and the DTOs (contracts). The service orchestrates them.

```java
@Service
@Transactional
public class TaskServiceImpl implements TaskService {

    private final TaskRepository taskRepository;
    private final TaskMapper taskMapper;

    public TaskServiceImpl(TaskRepository taskRepository, TaskMapper taskMapper) {
        this.taskRepository = taskRepository;
        this.taskMapper = taskMapper;
    }

    @Override
    public TaskDto createTask(CreateTaskRequestDto request) {
        Task task = taskMapper.toEntity(request);
        Task saved = taskRepository.save(task);
        return taskMapper.toDto(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public TaskDto getTask(Long id) {
        Task task = taskRepository.findById(id)
            .orElseThrow(() -> new TaskNotFoundException(id));
        return taskMapper.toDto(task);
    }
    // ... other methods
}
```

### Step 7: Create the Exception Classes

**Create `TaskNotFoundException` and `GlobalExceptionHandler`.**

Why seventh: The service needs to signal "not found" without knowing about HTTP. The exception class is domain-level. The handler is web-level and converts the exception to an HTTP response.

```java
public class TaskNotFoundException extends RuntimeException {
    public TaskNotFoundException(Long id) {
        super("Task not found with id: " + id);
    }
}
```

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(TaskNotFoundException.class)
    public ResponseEntity<ErrorDto> handleNotFound(TaskNotFoundException ex) {
        ErrorDto error = new ErrorDto(
            HttpStatus.NOT_FOUND.value(),
            ex.getMessage(),
            Instant.now()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorDto> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .collect(Collectors.joining(", "));
        return ResponseEntity.badRequest().body(new ErrorDto(400, message, Instant.now()));
    }
}
```

### Step 8: Create the Controller

**Create `TaskController` with `@RestController`.**

Why eighth: The controller is the **last** class to write because it depends on everything else: the service interface, the DTOs, and the exception handler (implicitly, via `@RestControllerAdvice`).

```java
@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @PostMapping
    public ResponseEntity<TaskDto> createTask(@Valid @RequestBody CreateTaskRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(taskService.createTask(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskDto> getTask(@PathVariable Long id) {
        return ResponseEntity.ok(taskService.getTask(id));
    }

    @GetMapping
    public ResponseEntity<List<TaskDto>> getAllTasks() {
        return ResponseEntity.ok(taskService.getAllTasks());
    }

    @PutMapping("/{id}")
    public ResponseEntity<TaskDto> updateTask(
        @PathVariable Long id,
        @Valid @RequestBody UpdateTaskRequestDto request
    ) {
        return ResponseEntity.ok(taskService.updateTask(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        taskService.deleteTask(id);
        return ResponseEntity.noContent().build();
    }
}
```

---

## 4. Completing the HabitTracker Module: Step-by-Step Roadmap

The HabitTracker module currently only has two files:

```
HabitTracker/
└── domain/
    └── entity/
        ├── Habit.java
        └── HabitStatusPerDay.java
```

To complete it, follow the **exact same sequence** as TaskTracker. Here's the full roadmap:

### Phase 1: Refine the Domain Model

**Step 1.1 — Review and finalize `Habit.java`**

Ensure the entity has:
- `@Id` with `@GeneratedValue`
- A `String name` (non-null)
- A `String description` (nullable)
- A `LocalDate startDate` (when the habit tracking began)
- A `boolean active` or `HabitStatus status` (to pause/archive habits)
- A `@OneToMany` relationship to `HabitStatusPerDay`

```java
@Entity
@Table(name = "habits")
public class Habit {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String description;

    @Column(nullable = false)
    private LocalDate startDate = LocalDate.now();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private HabitStatus status = HabitStatus.ACTIVE;

    @OneToMany(mappedBy = "habit", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<HabitStatusPerDay> dailyStatuses = new ArrayList<>();

    // constructors, getters, business methods
}
```

**Step 1.2 — Review and finalize `HabitStatusPerDay.java`**

This entity represents a single day's completion record for a habit.

```java
@Entity
@Table(name = "habit_status_per_day", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"habit_id", "date"})
})
public class HabitStatusPerDay {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "habit_id", nullable = false)
    private Habit habit;

    @Column(nullable = false)
    private LocalDate date;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CompletionStatus completionStatus = CompletionStatus.NOT_DONE;

    // constructors, getters, business methods
}
```

**Step 1.3 — Create missing enums**

You may need:
- `HabitStatus` (e.g., `ACTIVE`, `PAUSED`, `ARCHIVED`)
- `CompletionStatus` (e.g., `DONE`, `NOT_DONE`, `SKIPPED`)

```java
public enum HabitStatus {
    ACTIVE, PAUSED, ARCHIVED
}

public enum CompletionStatus {
    DONE, NOT_DONE, SKIPPED
}
```

### Phase 2: Persistence Layer

**Step 2.1 — Create `HabitRepository`**

```java
public interface HabitRepository extends JpaRepository<Habit, Long> {
    List<Habit> findByStatus(HabitStatus status);
}
```

**Step 2.2 — Create `HabitStatusPerDayRepository`**

```java
public interface HabitStatusPerDayRepository extends JpaRepository<HabitStatusPerDay, Long> {
    List<HabitStatusPerDay> findByHabitIdAndDateBetween(Long habitId, LocalDate start, LocalDate end);
    Optional<HabitStatusPerDay> findByHabitIdAndDate(Long habitId, LocalDate date);
}
```

### Phase 3: DTOs

**Step 3.1 — Create request DTOs**

```java
public record CreateHabitRequestDto(
    @NotBlank String name,
    String description,
    LocalDate startDate
) {}

public record UpdateHabitRequestDto(
    @NotBlank String name,
    String description,
    HabitStatus status
) {}

public record LogHabitRequestDto(
    @NotNull LocalDate date,
    @NotNull CompletionStatus completionStatus
) {}
```

**Step 3.2 — Create response DTOs**

```java
public record HabitDto(
    Long id,
    String name,
    String description,
    LocalDate startDate,
    HabitStatus status,
    int currentStreak,
    int longestStreak
) {}

public record HabitStatusPerDayDto(
    Long id,
    LocalDate date,
    CompletionStatus completionStatus
) {}
```

**Why streak fields in `HabitDto`**: These are **computed** fields, not stored columns. The service calculates them from `HabitStatusPerDay` records. This is a common DTO pattern — the DTO can contain derived data that isn't directly mapped to a single entity field.

### Phase 4: Mapper

**Step 4.1 — Create `HabitMapper`**

```java
@Component
public class HabitMapper {

    public Habit toEntity(CreateHabitRequestDto dto) {
        Habit habit = new Habit();
        habit.setName(dto.name());
        habit.setDescription(dto.description());
        habit.setStartDate(dto.startDate() != null ? dto.startDate() : LocalDate.now());
        return habit;
    }

    public HabitDto toDto(Habit habit) {
        return new HabitDto(
            habit.getId(),
            habit.getName(),
            habit.getDescription(),
            habit.getStartDate(),
            habit.getStatus(),
            calculateCurrentStreak(habit),
            calculateLongestStreak(habit)
        );
    }

    private int calculateCurrentStreak(Habit habit) {
        // iterate backwards through dailyStatuses, counting DONE until NOT_DONE
        // ...
    }

    private int calculateLongestStreak(Habit habit) {
        // iterate forward, tracking max consecutive DONE
        // ...
    }
}
```

### Phase 5: Service

**Step 5.1 — Create `HabitService` interface**

```java
public interface HabitService {
    HabitDto createHabit(CreateHabitRequestDto request);
    HabitDto getHabit(Long id);
    List<HabitDto> getAllHabits();
    HabitDto updateHabit(Long id, UpdateHabitRequestDto request);
    void deleteHabit(Long id);
    HabitStatusPerDayDto logHabitStatus(Long habitId, LogHabitRequestDto request);
    List<HabitStatusPerDayDto> getHabitHistory(Long habitId, LocalDate start, LocalDate end);
}
```

**Step 5.2 — Implement `HabitServiceImpl`**

```java
@Service
@Transactional
public class HabitServiceImpl implements HabitService {

    private final HabitRepository habitRepository;
    private final HabitStatusPerDayRepository statusRepository;
    private final HabitMapper habitMapper;

    // constructor injection

    @Override
    public HabitDto createHabit(CreateHabitRequestDto request) {
        Habit habit = habitMapper.toEntity(request);
        Habit saved = habitRepository.save(habit);
        return habitMapper.toDto(saved);
    }

    @Override
    public HabitStatusPerDayDto logHabitStatus(Long habitId, LogHabitRequestDto request) {
        Habit habit = habitRepository.findById(habitId)
            .orElseThrow(() -> new HabitNotFoundException(habitId));

        // Check if a record already exists for this date
        HabitStatusPerDay status = statusRepository
            .findByHabitIdAndDate(habitId, request.date())
            .orElseGet(() -> {
                HabitStatusPerDay newStatus = new HabitStatusPerDay();
                newStatus.setHabit(habit);
                newStatus.setDate(request.date());
                return newStatus;
            });

        status.setCompletionStatus(request.completionStatus());
        HabitStatusPerDay saved = statusRepository.save(status);
        return new HabitStatusPerDayDto(saved.getId(), saved.getDate(), saved.getCompletionStatus());
    }

    // ... other methods
}
```

### Phase 6: Exceptions

**Step 6.1 — Create `HabitNotFoundException`**

```java
public class HabitNotFoundException extends RuntimeException {
    public HabitNotFoundException(Long id) {
        super("Habit not found with id: " + id);
    }
}
```

**Step 6.2 — Extend `GlobalExceptionHandler`**

Add a handler method for `HabitNotFoundException` in the existing `GlobalExceptionHandler` (or create a separate `HabitExceptionHandler` if you prefer per-module handlers).

```java
@ExceptionHandler(HabitNotFoundException.class)
public ResponseEntity<ErrorDto> handleHabitNotFound(HabitNotFoundException ex) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ErrorDto(404, ex.getMessage(), Instant.now()));
}
```

### Phase 7: Controller

**Step 7.1 — Create `HabitController`**

```java
@RestController
@RequestMapping("/api/habits")
public class HabitController {

    private final HabitService habitService;

    public HabitController(HabitService habitService) {
        this.habitService = habitService;
    }

    @PostMapping
    public ResponseEntity<HabitDto> createHabit(@Valid @RequestBody CreateHabitRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(habitService.createHabit(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<HabitDto> getHabit(@PathVariable Long id) {
        return ResponseEntity.ok(habitService.getHabit(id));
    }

    @GetMapping
    public ResponseEntity<List<HabitDto>> getAllHabits() {
        return ResponseEntity.ok(habitService.getAllHabits());
    }

    @PutMapping("/{id}")
    public ResponseEntity<HabitDto> updateHabit(
        @PathVariable Long id,
        @Valid @RequestBody UpdateHabitRequestDto request
    ) {
        return ResponseEntity.ok(habitService.updateHabit(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteHabit(@PathVariable Long id) {
        habitService.deleteHabit(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/log")
    public ResponseEntity<HabitStatusPerDayDto> logHabit(
        @PathVariable Long id,
        @Valid @RequestBody LogHabitRequestDto request
    ) {
        return ResponseEntity.ok(habitService.logHabitStatus(id, request));
    }

    @GetMapping("/{id}/history")
    public ResponseEntity<List<HabitStatusPerDayDto>> getHistory(
        @PathVariable Long id,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end
    ) {
        return ResponseEntity.ok(habitService.getHabitHistory(id, start, end));
    }
}
```

### Phase 8: Cleanup

**Step 8.1 — Remove redundant classes**

Your TaskTracker module has both `CreateTaskRequest` (in `domain/`) and `CreateTaskRequestDto` (in `domain/dto/`). These are redundant. **Choose one approach and stick with it.** The cleaner approach is to have request DTOs in the `dto/` package only, and delete the duplicate classes in the `domain/` root. This also applies to `UpdateTaskRequest` vs. `UpdateTaskRequestDto`.

---

## 5. The HabitTracker Completion Checklist

| Phase | Files to Create/Modify | Depends On |
|---|---|---|
| **1. Domain** | `Habit.java` (refine), `HabitStatusPerDay.java` (refine), `HabitStatus.java`, `CompletionStatus.java` | Nothing |
| **2. Persistence** | `HabitRepository.java`, `HabitStatusPerDayRepository.java` | Phase 1 |
| **3. DTOs** | `CreateHabitRequestDto.java`, `UpdateHabitRequestDto.java`, `LogHabitRequestDto.java`, `HabitDto.java`, `HabitStatusPerDayDto.java` | Phase 1 (field shapes) |
| **4. Mapper** | `HabitMapper.java` | Phases 1 & 3 |
| **5. Service** | `HabitService.java`, `HabitServiceImpl.java` | Phases 2, 3, 4 |
| **6. Exceptions** | `HabitNotFoundException.java`, extend `GlobalExceptionHandler.java` | Phase 5 |
| **7. Controller** | `HabitController.java` | Phases 3, 5, 6 |
| **8. Cleanup** | Delete `CreateTaskRequest.java`, `UpdateTaskRequest.java` | — |

---

## 6. Key Design Principles Demonstrated

| Principle | How It Shows Up in This Project |
|---|---|
| **Single Responsibility** | Controller handles HTTP; Service handles business logic; Repository handles persistence; Mapper handles translation. |
| **Dependency Inversion** | Controller depends on `TaskService` (interface), not `TaskServiceImpl`. |
| **Separation of Contract and Implementation** | `TaskDto` is the API contract; `Task` is the persistence model. They evolve independently. |
| **Explicit Boundaries** | DTOs cross the HTTP boundary; entities stay inside the service/domain layer. |
| **Fail Fast** | `@Valid` on controller parameters rejects invalid input before it reaches the service. |
| **Centralized Error Handling** | `@RestControllerAdvice` catches exceptions from all controllers and produces consistent error responses. |
| **Type Safety** | Enums instead of strings; records for immutable DTOs; `@Enumerated(EnumType.STRING)` for database-safe enum storage. |

The order matters: **entity → repository → DTO → mapper → service → exception → controller**. Each step builds on the previous one, and by the time you write the controller, all the hard decisions about data shape, business rules, and error handling are already made.



[[Java]]