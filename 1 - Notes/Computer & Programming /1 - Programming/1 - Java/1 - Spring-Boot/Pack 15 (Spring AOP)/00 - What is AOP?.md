

**AOP (Aspect-Oriented Programming)** lets you write logic that many classes need, such as logging, security checks, transactions and timing, in **one place**, and have Spring run it around the methods you choose. Your business classes stay clean, and they never mention the extra logic.

Without it, you would paste the same logging or timing lines into every service method. That is repetitive, and it buries the real business code. This is the idea behind `@Transactional`, `@Cacheable`, `@Async` and `@PreAuthorize`: they are all AOP. It also builds directly on the proxies you met earlier, in your `@Configuration` note (the CGLIB subclass) and your bean lifecycle note (a `BeanPostProcessor` can swap a bean for a wrapper).

---

## The vocabulary

|Term|Meaning|
|---|---|
|**Aspect**|A class holding the cross-cutting logic (`LoggingAspect`)|
|**Advice**|The code that runs (for example, "log before the method")|
|**Join point**|A moment where advice _could_ run. In Spring AOP, this is a method call on a Spring bean|
|**Pointcut**|An expression that picks _which_ methods get the advice|
|**Weaving**|Connecting the aspect to the target. Spring does it at runtime, with **proxies**|

---

## How it works: a proxy stands in front of your bean

Spring doesn't change your class. After it creates a bean, a post-processor checks whether any pointcut matches it. If one does, Spring puts a **proxy** in the container instead of the real object:

```text
caller ──► proxy ──► runs advice ──► your real method ──► runs advice ──► back to caller
```

Everything that injects `UserService` receives the proxy, so calls go through it automatically. The proxy is either:

- a **JDK proxy**, which implements the same interface, or
- a **CGLIB proxy**, which is a subclass of your class. Spring Boot uses CGLIB by default.

---

## Set it up

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

Boot then turns AOP on for you. (In plain Spring with no Boot, add `@EnableAspectJAutoProxy` to a configuration class. Newer Boot versions may rename this starter, so check yours.)

### Your first aspect

```java
@Aspect
@Component
public class LoggingAspect {

    @Before("execution(* com.example.service.*.*(..))")
    public void logBefore(JoinPoint joinPoint) {
        log.info("Calling {}", joinPoint.getSignature().getName());
    }
}
```

Line by line:

- `@Aspect` marks the class as an aspect.
- `@Component` makes it a bean, so Spring finds it. Without this, nothing happens.
- `@Before` is the advice type: run before the matched method.
- The string is the **pointcut**: which methods to match.
- `JoinPoint` gives you details: `getSignature()` (the method), `getArgs()` (the arguments), `getTarget()` (the real object).

---

## Reading a pointcut expression

```text
execution( return-type  package.Class.method(params) )
```

|Pattern|Matches|
|---|---|
|`execution(* com.example.service.*.*(..))`|Any method of any class directly in `service`|
|`execution(* com.example.service..*.*(..))`|The same, **including sub-packages** (note the `..`)|
|`execution(public String com.example.service.UserService.getUser(Long))`|Exactly that one method|
|`@annotation(com.example.LogExecutionTime)`|Any method carrying that annotation|

The first form is a common trap: `service.*` does **not** include `service.impl`. Use `service..*` for sub-packages. The `*` means "anything" and `(..)` means "any parameters".

---

## The five advice types

|Annotation|Runs|Notes|
|---|---|---|
|`@Before`|Before the method|Can't stop the call, except by throwing|
|`@AfterReturning`|After a normal return|Gives you the result (`returning = "result"`)|
|`@AfterThrowing`|After an exception|Gives you the exception (`throwing = "ex"`)|
|`@After`|Always, like `finally`|Runs after success _or_ failure|
|`@Around`|Wraps the whole call|The most powerful. **You** decide whether the real method runs|

### `@Around` in detail

```java
@Around("execution(* com.example.service..*.*(..))")
public Object timeIt(ProceedingJoinPoint pjp) throws Throwable {
    long start = System.nanoTime();
    try {
        return pjp.proceed();                    // runs the real method
    } finally {
        long ms = (System.nanoTime() - start) / 1_000_000;
        log.info("{} took {} ms", pjp.getSignature().getName(), ms);
    }
}
```

Three rules for `@Around`:

- You **must call `pjp.proceed()`**, or the real method never runs.
- You **must return its result**, or the caller gets `null`.
- Use `try/finally` so the timing still happens when the method throws.

Use it for timing, retrying, caching, or blocking a call.

---

## Cleaner style: named pointcuts and your own annotation

Write a pointcut once and reuse it by name:

```java
@Aspect
@Component
public class ServiceLoggingAspect {

    @Pointcut("execution(* com.example.service..*.*(..))")
    public void serviceMethods() {}              // an empty marker method

    @Before("serviceMethods()")
    public void logBefore(JoinPoint jp) { ... }

    @AfterReturning(pointcut = "serviceMethods()", returning = "result")
    public void logAfter(JoinPoint jp, Object result) { ... }
}
```

For anything you apply only to _some_ methods, the best approach is to **target your own annotation** instead of a package pattern. It is explicit, because you can see it on the method:

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface LogExecutionTime {}

@Around("@annotation(LogExecutionTime)")
public Object timeIt(ProceedingJoinPoint pjp) throws Throwable { ... }
```

```java
@LogExecutionTime
public Task findTask(Long id) { ... }
```

This is how Spring's own annotations work, and how you'd build a custom `@Audited` or `@RateLimited`.

---

## The proxy gotchas (this is where beginners get stuck)

**1. Calling a method on `this` skips the advice.**

```java
@Service
public class OrderService {
    public void placeOrder() {
        save();                 // calls this.save(), NOT the proxy → no @Transactional
    }

    @Transactional
    public void save() { ... }
}
```

The call goes from the real object to itself, so it never passes through the proxy. Fixes:

- **Move `save()` into another bean** and inject it (the usual, best fix).
- Inject the bean into itself with `ObjectProvider`.
- Use AspectJ weaving (see below).

**2. Only Spring beans are advised.** An object you create with `new` has no proxy. (This is the same reason the IoC note told you to let Spring create objects.)

**3. Visibility and `final` matter.** Put advice on **public** methods. A `private` method is never intercepted. CGLIB can't subclass a `final` class or override a `final` method, so advice on those is skipped. (This is the same rule you saw for `@Configuration` classes.)

**4. Advice order.** `@Around` wraps everything, and the others run inside it. When several aspects match the same method, control the order with `@Order(1)` on the aspect, because the default order is undefined.

---

## Where Spring already uses AOP for you

|Annotation|What the aspect does|
|---|---|
|`@Transactional`|Opens a transaction before the method and commits or rolls back after|
|`@Cacheable`|Returns a stored result instead of running the method|
|`@Async`|Runs the method on another thread|
|`@PreAuthorize`|Checks the user's permissions (your Spring Security notes) before the method|

All of them are bound by the proxy rules above, so the `this`-call trap applies to each one.

---

## Related concept in short

**Spring AOP vs AspectJ.** Spring AOP is proxy-based: it only intercepts method calls on Spring beans, and it's simple and enough for almost everything. **AspectJ** is a full AOP language that changes the bytecode itself, at compile time or load time. It can intercept constructors, field access and calls on `this`, but it needs extra build setup. Reach for it only when proxies aren't enough.



[[Spring Framework]]