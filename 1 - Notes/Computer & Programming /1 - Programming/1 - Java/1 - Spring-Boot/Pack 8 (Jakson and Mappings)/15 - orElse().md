


We'll start with one question: **what is a service method supposed to promise?** Once that's clear, the code changes make sense.

## A method is a promise to its caller

Every method makes a promise with three parts: what it needs (inputs), what it gives back (outputs), and how it can fail. Callers rely on that promise and shouldn't have to read the body to use the method.

The original line is:

```java
public StudentDto findStudent(Integer id) {
    return repository.findById(id).orElse(null);
}
```

Read it as a promise:

- **Input:** an `Integer` id.
- **Output:** a `StudentDto`, which the caller will assume is a valid student.
- **Failure:** the signature says nothing. The body quietly returns `null`.

That last point is the core problem. The signature promises a `StudentDto`, but the body can return `null`, and nothing in the signature warns the caller. The caller finds out at runtime, usually as a `NullPointerException` somewhere unrelated.

There is also a type problem. `repository.findById` returns an entity, not a DTO, so the code doesn't compile as written. Fixing that requires a mapping step, which we'll cover later.

## Why the repository returns `Optional`

`findById` returns `Optional<Student>` because the database might have no row with that id. Java gives you a type for "a value that may be absent" so you can't ignore that case by accident. The compiler won't let you call `getName()` on an `Optional` directly. You have to say what happens when the value is missing.

The original code said "return `null` when missing." That is one valid choice, but it throws away the protection `Optional` gives you. The question becomes: what should happen in the service when the student is missing?

## Deciding what absence means

Absence means different things in different methods, and the right response depends on the meaning.

Sometimes the caller requires the object. Asking for a student profile by id is an example. If the student doesn't exist, the request can't be fulfilled, so that is an error. The method should throw:

```java
Student student = repository.findById(id)
        .orElseThrow(() -> new StudentNotFoundException(id));
```

Other times absence is a normal answer. Checking whether an email is already registered is one. The method should return the empty result and let the caller decide:

```java
public Optional<StudentDto> findByEmail(String email) {
    return repository.findByEmail(email).map(mapper::toDto);
}
```

A quick test you can apply: if the caller can't continue without the object, throw. If the caller can reasonably continue without it, return `Optional`. Returning `null` from a service is almost never the right answer, because the signature no longer tells the truth.

## Naming the failure

`orElseThrow` needs an exception, and the choice of exception is part of the promise. A generic `RuntimeException` or `IllegalArgumentException` tells the caller almost nothing. A named exception tells the caller exactly which failure happened:

```java
public class StudentNotFoundException extends RuntimeException {

    public StudentNotFoundException(Integer id) {
        super("Student not found: " + id);
    }
}
```

The class extends `RuntimeException`, which means the caller isn't forced to catch it. That's usually what you want for business failures that a global handler will translate, rather than handle at every call site. Checked exceptions, which extend `Exception` and must be declared or caught, suit failures the caller is expected to recover from locally. For "student doesn't exist," a global handler is the better place.

## Where the transaction starts and stops

```java
@Transactional(readOnly = true)
public StudentDto findStudent(Integer id) {
    Student student = repository.findById(id)
            .orElseThrow(() -> new StudentNotFoundException(id));
    return mapper.toDto(student);
}
```

`@Transactional` opens a database transaction when the method starts and closes it when the method ends. This matters for one reason in particular: the mapping happens inside the transaction. If `Student` has a lazy collection, like `courses`, the mapper may read it. Inside the transaction, that read works. Outside it, Hibernate throws `LazyInitializationException`.

`readOnly = true` tells Spring this method only reads. Hibernate can skip dirty-checking, which saves work, and some databases can use a cheaper read path. It's a statement of intent for anyone reading the code, and it also prevents accidental writes from being flushed. It doesn't stop code from calling a setter, so don't rely on it as a security guarantee.

## How the failure reaches the HTTP client

The service throws a business exception and knows nothing about HTTP. A separate class translates it:

```java
@RestControllerAdvice
class StudentExceptionHandler {

    @ExceptionHandler(StudentNotFoundException.class)
    ProblemDetail handleNotFound(StudentNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    }
}
```

`@RestControllerAdvice` applies this handler to every controller in the application. When any controller's call to the service throws `StudentNotFoundException`, Spring routes it here. The handler returns a `ProblemDetail`, which is Spring's implementation of the RFC 9457 standard for error responses. Clients receive a consistent JSON body with a status, a title, and a detail message.

The division is what matters. If the service decided the status code, it would need to know about HTTP, and it could no longer be reused by a scheduled job or a command-line tool. Keeping the translation in one place means the status code is decided once.

## Testing the promise

Each promise becomes a test. You can verify both branches without a database or a running server:

```java
@ExtendWith(MockitoExtension.class)
class StudentServiceTest {

    @Mock StudentRepository repository;
    @Mock StudentMapper mapper;
    @InjectMocks StudentService service;

    @Test
    void throwsWhenStudentDoesNotExist() {
        when(repository.findById(42)).thenReturn(Optional.empty());

        assertThrows(StudentNotFoundException.class,
                () -> service.findStudent(42));
    }

    @Test
    void returnsMappedDtoWhenStudentExists() {
        Student student = new Student();
        StudentDto dto = new StudentDto(1, "Ada");
        when(repository.findById(1)).thenReturn(Optional.of(student));
        when(mapper.toDto(student)).thenReturn(dto);

        assertSame(dto, service.findStudent(1));
    }
}
```

`@Mock` creates a fake collaborator, and `@InjectMocks` builds the service with those fakes through its constructor. Each test sets up one branch of the promise and checks its result. The first test proves the method refuses to return `null`. The second proves it returns what the mapper produced, rather than rebuilding the object itself.

## A related idea you haven't asked about yet

Why does `@Transactional` roll back the database changes when an exception is thrown, and why does that rule depend on the exception type? Spring rolls back on unchecked exceptions by default, which is why `StudentNotFoundException` extends `RuntimeException`. Checked exceptions don't trigger rollback unless you configure it. That behavior is the reason the exception choice above matters for data consistency, not only for style. When you're ready, we can take that apart with a concrete example of a write that fails halfway through.


[[Spring Framework]]