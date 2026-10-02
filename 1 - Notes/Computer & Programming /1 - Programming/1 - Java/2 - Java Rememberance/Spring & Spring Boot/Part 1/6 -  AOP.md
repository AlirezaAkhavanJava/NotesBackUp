


## What is AOP?

**AOP (Aspect-Oriented Programming)** is a programming paradigm for handling **cross-cutting concerns** — logic that's needed across many parts of your application but isn't related to the core business logic of any single class.

Classic examples of cross-cutting concerns:

- Logging ("log every method call in the service layer")
- Security checks ("verify the user is authorized before this method runs")
- Transactions ("wrap this method in a database transaction")
- Performance monitoring ("measure how long this method takes")

Without AOP, you'd have to manually sprinkle logging/security/transaction code inside every single method — messy, repetitive, and it clutters your actual business logic.

**AOP lets you define that logic once, separately, and have it automatically "woven" into the methods you choose** — without touching the target class's code at all.

## Core vocabulary

|Term|Meaning|
|---|---|
|**Aspect**|The class containing the cross-cutting logic (e.g., `LoggingAspect`)|
|**Advice**|The actual code that runs (e.g., "log before the method executes")|
|**Join point**|A point during execution where advice _can_ run (in Spring, essentially always a method call)|
|**Pointcut**|An expression that says _which_ join points (methods) the advice applies to|
|**Weaving**|The process of linking aspects into the target objects — in Spring, this happens via **proxies**, at runtime|

## How it connects to what we discussed earlier

Remember when I mentioned Spring sometimes hands you a **CGLIB or JDK dynamic proxy** instead of the raw bean? **This is AOP in action.** When a class has an aspect applied to it (like `@Transactional`), Spring doesn't modify your class's bytecode. Instead:

1. It creates a **proxy object** that wraps your real bean
2. The proxy sits in front of your object in the container
3. When you call a method, you're actually calling the **proxy**, which runs the aspect's logic, then delegates to your real method, then maybe runs more aspect logic after

This is why the object is "just a heap object" as we said before — the proxy is _also_ just an ordinary heap object, generated dynamically, that implements the same interface (or subclasses your class) and intercepts calls.

## How to do it — step by step

### 1. Add the dependency

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

### 2. Define an Aspect

```java
@Aspect
@Component
public class LoggingAspect {

    @Before("execution(* com.example.service.*.*(..))")
    public void logBefore(JoinPoint joinPoint) {
        System.out.println("Calling method: " + joinPoint.getSignature().getName());
    }
}
```

- `@Aspect` — marks this class as an aspect
- `@Component` — it also needs to be a Spring bean so the container picks it up
- `@Before(...)` — the **advice type**: run this _before_ the matched method executes
- `"execution(* com.example.service.*.*(..))"` — the **pointcut expression**: matches any method (`*` return type), in any class in `com.example.service`, any method name, any parameters

### 3. Pointcut expression syntax (breakdown)

```
execution(modifiers-pattern? return-type-pattern declaring-type-pattern? method-name-pattern(param-pattern) throws-pattern?)
```

Example:

```java
execution(public String com.example.service.UserService.getUser(Long))
```

Matches: public method, returns `String`, in exactly that class, named `getUser`, taking one `Long` parameter.

More commonly you use wildcards:

```java
execution(* com.example.service.*.*(..))
```

= any return type, any class in that package, any method name, any parameters.

### 4. The different advice types

```java
@Aspect
@Component
public class DemoAspect {

    @Before("execution(* com.example.service.*.*(..))")
    public void before(JoinPoint jp) {
        System.out.println("Before: " + jp.getSignature());
    }

    @After("execution(* com.example.service.*.*(..))")
    public void after(JoinPoint jp) {
        System.out.println("After: " + jp.getSignature());
    }

    @AfterReturning(pointcut = "execution(* com.example.service.*.*(..))", returning = "result")
    public void afterReturning(JoinPoint jp, Object result) {
        System.out.println("Returned: " + result);
    }

    @AfterThrowing(pointcut = "execution(* com.example.service.*.*(..))", throwing = "ex")
    public void afterThrowing(JoinPoint jp, Exception ex) {
        System.out.println("Exception: " + ex.getMessage());
    }

    @Around("execution(* com.example.service.*.*(..))")
    public Object around(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.currentTimeMillis();
        Object result = pjp.proceed(); // actually calls the real method
        long time = System.currentTimeMillis() - start;
        System.out.println("Execution time: " + time + "ms");
        return result;
    }
}
```

- `@Before` — runs before the method
- `@After` — runs after (regardless of outcome, like `finally`)
- `@AfterReturning` — runs after successful return, gives you the result
- `@AfterThrowing` — runs if an exception is thrown
- `@Around` — the most powerful: wraps the whole method call; **you** control whether/when the real method (`pjp.proceed()`) actually runs — used for things like timing, retrying, or short-circuiting

### 5. A reusable named pointcut (cleaner style)

```java
@Aspect
@Component
public class ServiceLoggingAspect {

    @Pointcut("execution(* com.example.service.*.*(..))")
    public void serviceMethods() {} // just a marker method, no body needed

    @Before("serviceMethods()")
    public void logBefore(JoinPoint jp) {
        System.out.println("Entering: " + jp.getSignature().getName());
    }

    @AfterReturning(pointcut = "serviceMethods()", returning = "result")
    public void logAfter(JoinPoint jp, Object result) {
        System.out.println("Exiting: " + jp.getSignature().getName() + " -> " + result);
    }
}
```

## What actually happens at runtime

1. Spring scans and finds `UserService` needs AOP applied (because a pointcut matches its methods)
2. Instead of registering the raw `UserService` object in the container, it registers a **proxy**
3. Anywhere `UserService` is injected via `@Autowired`, you actually receive the **proxy**, not the raw object
4. Calling `userService.getUser(1L)` really calls `proxy.getUser(1L)` → proxy runs `@Before` advice → proxy calls the real `getUser` on the wrapped object → proxy runs `@AfterReturning` advice → returns to caller

This is also _why_ `@Transactional` doesn't work if you call a method on `this` from within the same class — you're bypassing the proxy entirely and calling the real object directly, so no advice runs. That's a very common beginner gotcha.



[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]