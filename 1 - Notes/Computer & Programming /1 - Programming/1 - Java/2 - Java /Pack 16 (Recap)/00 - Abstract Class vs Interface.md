



## 1. The main difference

Think about these two statements:

- **Interface:** Every class implementing me must provide certain capabilities.
    
- **Abstract class:** Every class extending me can inherit shared state, behavior, and implementation, *while completing the missing parts*.
    

In simple terms:

**Interface = What a class can do.**

**Abstract class = What a group of related classes already has in common.**

## 2. The problem an abstract class solves

Imagine you're developing an application with three kinds of jobs:

- BackupJob
    
- EmailJob
    
- ReportJob
    

All three jobs need to:

1. Print a message when starting.
    
2. Execute their specific operation.
    
3. Print a message when finishing.
    

You could define an interface:

```java
public interface Job {
    void execute();
}
```

Now every class implements `execute()`.

But what about the shared logging behavior?

If every class writes the same logging code, you're duplicating logic.

**This is where an abstract class becomes useful.**

## 3. Using an abstract class

First, define the interface:

```java
public interface Job {
    void execute();
}
```

Now create an abstract class:

```java
public abstract class AbstractJob implements Job {

    private final String name;

    protected AbstractJob(String name) {
        this.name = name;
    }

    @Override
    public final void execute() {
        System.out.println("Starting: " + name);

        performJob();

        System.out.println("Finished: " + name);
    }

    protected abstract void performJob();
}
```

And finally, create a concrete class:

```java
public class BackupJob extends AbstractJob {

    public BackupJob() {
        super("Database Backup");
    }

    @Override
    protected void performJob() {
        System.out.println("Backing up database...");
    }
}
```

Usage:

```java
Job job = new BackupJob();

job.execute();
```

Output:

```java
Starting: Database Backup
Backing up database...
Finished: Database Backup
```

### What happened here?

The interface defines **what every job must be able to do**.

The abstract class provides **a common implementation** of that behavior.

The concrete class only implements the part that makes it unique.

Notice that our abstract class provides things an interface cannot provide in the same way:

- A constructor to initialize shared state.
    
- An instance field (`name`).
    
- A reusable implementation (`execute()`).
    
- A `final` method that subclasses cannot override.
    
- An abstract method (`performJob()`) for subclasses to implement.
    

This design is also known as the **Template Method pattern**.

## 4. But interfaces can have default methods!

Correct! Modern Java interfaces can contain implemented methods using `default`.

```
public interface Job {

    void execute();

    default void printInfo() {
        System.out.println("This is a job");
    }
}
```

So interfaces can share some behavior too.

However, they cannot declare ordinary instance fields or constructors, and they cannot enforce a fixed execution algorithm using a `final` default method.

That's why abstract classes remain useful.

## 5. Comparison

|Feature|Interface|Abstract class|
|---|---|---|
|Define abstract methods|Yes|Yes|
|Implement methods|Yes, using default methods|Yes|
|Instance fields|No|Yes|
|Constructors|No|Yes|
|Shared instance state|No|Yes|
|Multiple inheritance|Implement multiple interfaces|Extend only one class|
|Concrete methods marked final|No|Yes|
|Instantiate directly|No|No|

## 6. How should you choose?

**Choose an interface when:**

- You want to define a contract.
    
- Unrelated classes should support the same capabilities.
    
- You want flexibility and loose coupling.
    
- You want different implementations to be interchangeable.
    

**Choose an abstract class when:**

- Several closely related classes share code.
    
- They need common instance fields.
    
- They need shared constructor logic.
    
- You want to enforce part of an algorithm while allowing subclasses to customize the rest.
    

## 7. Real example from Spring Security

Consider `OncePerRequestFilter`.

```
public class JwtAuthenticationFilter
        extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        // Your authentication logic
    }
}
```

Why does Spring provide an abstract class here?

Because Spring already has reusable filtering logic that handles the once-per-request behavior.

You don't need to reimplement that infrastructure.

You only provide the application-specific logic through `doFilterInternal()`.

Meanwhile, the servlet `Filter` interface defines the filtering contract.

## 8. The whole picture

Think about it this way:

**An interface defines a common API. An abstract class provides a common foundation.**

They aren't competing features. You can use both together.

In fact, a common architecture is:

```
        Interface
           |
     Abstract Class
           |
     Concrete Class
```

And one important rule:

**Start with an interface when you need a contract. Introduce an abstract class when multiple implementations genuinely need shared implementation or state.**

Don't create an abstract class just because several classes implement the same interface.

[[Java]]