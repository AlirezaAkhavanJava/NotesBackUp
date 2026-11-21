

**Bean Instantiation** is the stage where Spring uses a registered **Bean Definition** to create an actual Java object in memory, this is where **the constructor gets called**! Until now, Spring only had metadata describing the bean. During instantiation, Spring determines which constructor to use, resolves any required constructor arguments, and invokes that constructor to create the bean instance.

## 1. How Does Instantiation Work?

Imagine we have this service:

```java
@Service
public class UserService {

    public UserService() {
        System.out.println("UserService constructor called!");
    }
}
```

During application startup, Spring:

1. Finds the Bean Definition for `userService`.
    
2. Checks which constructor should be used.
    
3. Invokes the constructor.
    
4. Creates the actual `UserService` instance in memory.
    

Because `UserService` is a singleton by default, Spring normally creates only one instance of it per container.

## 2. What If the Constructor Has Dependencies?

```java
@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
        System.out.println("UserService created!");
    }
}
```

Here, Spring realizes that `UserService` requires a `UserRepository` object.

Before invoking the `UserService` constructor, Spring must resolve its dependency.

```
Spring wants to instantiate UserService
              |
              v
Checks its constructor
              |
              v
Needs UserRepository
              |
              v
Obtains or creates UserRepository bean
              |
              v
Calls UserService(repository)
              |
              v
UserService instance created!
```

This is called **Constructor Injection**, a form of Dependency Injection (DI).

Notice that constructor injection happens **during instantiation**, not afterward.

## 3. Does Spring Instantiate Every Bean Immediately?

Not necessarily! It depends on the bean's scope and configuration.

|Bean configuration|When instantiated|
|---|---|
|Singleton (default)|Normally during container initialization|
|Lazy singleton|When first needed|
|Prototype|Whenever the container is asked for an instance|

## 4. What Happens Next?

After a bean is instantiated, Spring can perform additional operations, such as injecting dependencies through fields or setters, and running initialization callbacks.

Remember the difference:

- **Instantiation:** Creating the actual object, including calling its constructor.
    
- **Initialization:** Preparing the already-created object for use through lifecycle callbacks.
    

### The Lifecycle So Far

```
1. IoC Container Created
          |
          v
2. Bean Definitions Registered
          |
          v
   BeanFactoryPostProcessor
          |
          v
3. Bean Instantiation  <-- WE ARE HERE
   Constructor executed
   Object created
          |
          v
4. Dependency Population
   (Fields and setters)
          |
          v
5. Bean Initialization
```

**Key takeaway:** Instantiation is the moment when a Bean Definition becomes an actual Java object. Spring uses the metadata to determine how to construct it and invokes its constructor, including supplying constructor dependencies when necessary.




[[Spring Framework]]