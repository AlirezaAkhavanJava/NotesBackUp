
# `@Autowired` in Spring

`@Autowired` is a Spring annotation that tells the **Spring IoC Container**:

> "Find a matching bean and inject it here."

It is used for **Dependency Injection (DI)**.

---

## Without `@Autowired`

You manually create dependencies:

```java
public class UserService {

    private UserRepository repository;

    public UserService() {
        this.repository = new UserRepository();
    }
}
```

Problem:

`UserService` controls the creation of `UserRepository`.

```text
UserService
     |
     |
 creates
     |
     v
UserRepository
```

This creates **tight coupling**.

---

## With `@Autowired`

```java
@Service
public class UserService {

    private UserRepository repository;

    @Autowired
    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

Now Spring does:

```text
Spring Container

UserRepository Bean
        |
        |
        injects
        |
        v

UserService
```

`UserService` only declares what it needs.

---

# Where can `@Autowired` be used?

## 1. Constructor Injection (recommended)

```java
@Service
public class UserService {

    private final UserRepository repository;

    @Autowired
    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

However, since Spring 4.3, if there is **only one constructor**, `@Autowired` is optional:

```java
@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

Spring automatically injects it.

---

## 2. Field Injection

```java
@Service
public class UserService {

    @Autowired
    private UserRepository repository;

}
```

Spring uses reflection to set the field.

Avoid this in professional code because:

- dependencies are hidden
    
- harder to unit test
    
- prevents immutable fields (`final`)
    

---

## 3. Setter Injection

```java
@Service
public class UserService {

    private UserRepository repository;

    @Autowired
    public void setRepository(UserRepository repository) {
        this.repository = repository;
    }
}
```

Useful when a dependency is optional.

---

# How does Spring find the object?

Example:

```java
@Repository
public class UserRepository {

}
```

Spring creates:

```text
BeanFactory

UserRepository Bean
```

Then:

```java
@Service
public class UserService {

    public UserService(UserRepository repository) {

    }
}
```

Spring searches:

```text
Need: UserRepository

Search Beans:
    UserRepository ✅

Inject it
```

---

# What if multiple beans exist?

Example:

```java
@Repository
public class MySqlUserRepository implements UserRepository {
}


@Repository
public class MongoUserRepository implements UserRepository {
}
```

Now Spring sees:

```
UserRepository ?
       |
       +-- MySqlUserRepository
       |
       +-- MongoUserRepository
```

It cannot decide.

You get:

```
NoUniqueBeanDefinitionException
```

Solution: `@Qualifier`

```java
@Service
public class UserService {

    public UserService(
        @Qualifier("mySqlUserRepository")
        UserRepository repository
    ) {
        this.repository = repository;
    }
}
```

---

# `@Autowired` vs `@Bean` vs `@Component`

They solve different problems:

|Annotation|Purpose|
|---|---|
|`@Component`|Tell Spring "create this object as a bean"|
|`@Service`|Component for business logic|
|`@Repository`|Component for data access|
|`@Bean`|Manually create a bean in configuration|
|`@Autowired`|Inject an existing bean|

Example:

```java
@Repository
class UserRepository {
}
```

Creates the bean.

```java
@Service
class UserService {

    UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

Injects the bean.

---

## Modern Spring Boot practice

Most projects today use:

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository repository;

}
```

with Lombok generating the constructor.

Equivalent to:

```java
public UserService(UserRepository repository) {
    this.repository = repository;
}
```

So in modern Spring Boot:

- Prefer **constructor injection**
    
- Avoid `@Autowired` on fields
    
- Let Spring manage dependencies through the container


[[Spring Framework]]