
# Two things Spring does behind the scenes

This note explains two bits of "magic" you use constantly. The first is how a Spring Data repository **interface**, with no code behind it, becomes a working object you can inject. The second is how `@RestControllerAdvice` catches exceptions from every controller, and why it is _not_ the same mechanism as AOP.

Both follow on from your earlier notes: the repository half builds on your data access note and the proxy ideas from your AOP note, and the advice half builds on your MVC note (`DispatcherServlet`) and REST API note (`ProblemDetail`). Seeing how they work removes the mystery and helps you debug when they misbehave.

---

## Part 1: how a repository interface gets an implementation

You write only this:

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
```

There is no class implementing it, yet `userRepository.findByEmail("x@y.com")` works. Here is what happens.

### Step 1: Spring finds the interface

Spring Boot's JPA auto-configuration switches on repository scanning (the same job as `@EnableJpaRepositories`, from your `@EntityScan` note), starting at your main class's package. This is a **separate scan** from component scanning, because ordinary component scanning ignores interfaces. The repository scanner looks for interfaces that extend `Repository`, `CrudRepository`, `JpaRepository` and similar.

### Step 2: Spring builds a proxy and registers it as the bean

For each repository interface, Spring registers a **factory bean** (the `FactoryBean` idea from your bean-declaration note). When the container asks it for the bean, it creates a **JDK dynamic proxy** in memory, a class that implements `UserRepository` and exists only at runtime, with no `.java` or `.class` file. Spring Data builds it with Spring AOP's own `ProxyFactory`, so it is the same proxy machinery you saw in the AOP note.

That proxy is what gets injected into `UserService`. The service just sees an object that satisfies the interface.

### Step 3: Two kinds of method calls

The proxy sends each call to one of two places. This is a simplified view:

```text
userRepository.save(user)            ─►  SimpleJpaRepository
userRepository.findAll()                  (real, hand-written JPA code
userRepository.findById(1L)               that ships with Spring Data)

userRepository.findByEmail("x@y")    ─►  the query Spring prepared
                                          from the method name
```

- **Standard methods** (`save`, `findById`, `findAll`, `delete`) are handled by `SimpleJpaRepository`, a real class that uses the JPA `EntityManager`.
- **Your own methods** (`findByEmail`) are handled by a query that Spring prepared when it started up.

### Step 4: How a method name becomes a query

At startup, Spring **parses the method name**:

```text
findByEmail
 ├─ "findBy"   →  this is a query
 └─ "Email"    →  the "email" field on User
```

It turns that into a query roughly equal to `SELECT u FROM User u WHERE u.email = :email`, prepares it **once**, and just binds your argument on each call. More keywords build more conditions:

```java
List<User> findByNameAndEmail(String name, String email);
List<User> findByAgeGreaterThan(int age);
List<User> findByNameContainingIgnoreCase(String namePart);
```

Two consequences you should know:

- **Mistakes show up at startup.** If you write `findByEmial`, the app refuses to start with an error like "No property 'emial' found for type User". That's good: you find the typo immediately, not when a user hits the code.
- **Long names get unreadable.** For complex queries, write the query yourself with `@Query("SELECT u FROM User u WHERE ...")` (JPQL, or `nativeQuery = true` for SQL). Spring uses your query instead of deriving one.

### One more thing the proxy adds: transactions

`SimpleJpaRepository` is transactional. Its read methods run in read-only transactions, and its write methods (`save`, `delete`) run in their own transactions. That is another AOP-style proxy at work. When a service method needs several repository calls to succeed or fail together, put `@Transactional` on the **service** method, so they all share one transaction (the point from your data access note).

---

## Part 2: how `@RestControllerAdvice` works, and why it isn't AOP

`@RestControllerAdvice` is a class whose `@ExceptionHandler` methods catch exceptions from all your controllers. The cross-cutting idea is the same as AOP, but the **mechanism is different**. It uses no proxies and no pointcuts. It is part of Spring MVC's request handling:

```text
1. A request reaches DispatcherServlet (the front controller)
2. Your controller method (or argument binding or validation) throws an exception
3. DispatcherServlet doesn't crash. It asks its chain of HandlerExceptionResolvers:
      "can anyone handle this?"
4. ExceptionHandlerExceptionResolver checks the @ExceptionHandler methods
   (including those in your @RestControllerAdvice classes)
5. It picks the most specific match, calls it, and uses the return value
   as the response
```

Details that help in practice:

- **The most specific handler wins.** `UserNotFoundException` beats a general `Exception` handler. A handler inside the controller itself beats one in the advice class.
- **Other resolvers exist.** `ResponseStatusExceptionResolver` handles `@ResponseStatus`, and `DefaultHandlerExceptionResolver` turns standard Spring exceptions (like a wrong verb) into status codes. Your `ResponseEntityExceptionHandler` subclass from the REST API note builds on this chain.
- **If nothing handles it,** Boot falls back to its default `/error` page or JSON.
- **You can limit the scope:** `@RestControllerAdvice(basePackages = "com.example.api")` applies it to only some controllers.

### Same idea, different machinery

||AOP (`@Aspect`)|`@RestControllerAdvice`|
|---|---|---|
|Mechanism|Proxies wrapped around beans|`DispatcherServlet` and the resolver chain|
|Applies to|Any bean method matching a pointcut|Exceptions raised while handling a web request|
|Wired in by|Spring's auto-proxy creator|Spring MVC's request pipeline|
|Triggered by|A method call|An exception during request handling|

### The catch: filters run before it

`@RestControllerAdvice` only sees exceptions from inside `DispatcherServlet`. A **servlet filter** (like your `JwtAuthenticationFilter`) runs _before_ the request ever reaches it, so an exception thrown there never reaches your advice class. For security errors, handle them with Spring Security's `AuthenticationEntryPoint` (401) and `AccessDeniedHandler` (403) in your `SecurityFilterChain`.



[[Spring Framework]]