In **Mockito**, argument matchers (often called "arg matchers") are used when you need to **match method arguments flexibly** during verification or stubbing, especially when you don't care about the exact value or want to match based on type, condition, or pattern.

---
### Basic Syntax

```java
when(mock.someMethod(any(), eq("value"), anyInt())).thenReturn(result);
verify(mock).someMethod(anyString(), contains("test"), greaterThan(5));
```

---

### Common Argument Matchers

| Matcher | Description | Example |
|-------|-----------|--------|
| `any()` | Matches any object (including null) | `any()` |
| `any(Class<T>.class)` | Type-safe version | `any(String.class)` → `anyString()` |
| `anyString()` | Matches any non-null `String` | `anyString()` |
| `anyInt()`, `anyLong()`, etc. | Primitive-specific | `anyInt()` |
| `eq(T value)` | Exact match | `eq("hello")` |
| `isNull()` | Matches `null` | `isNull()` |
| `notNull()` | Matches non-null | `notNull()` |
| `contains(String substring)` | String contains substring | `contains("world")` |
| `startsWith(...)`, `endsWith(...)` | String prefix/suffix | `startsWith("Mr.")` |
| `matches(String regex)` | Regex match | `matches("\\d+")` |
| `greaterThan(...)`, `lessThan(...)`, etc. | For numbers (via `AdditionalMatchers`) | `greaterThan(10)` |
| `argThat(ArgumentMatcher<T> matcher)` | Custom lambda matcher | `argThat(s -> s.length() > 5)` |

---

### Key Rules

1. **All or nothing**: If you use **any matcher**, **all arguments** in that call must use matchers.
   ```java
   // WRONG
   verify(mock).method("fixed", anyString());

   // CORRECT
   verify(mock).method(eq("fixed"), anyString());
   ```

2. For primitives, use primitive-specific matchers:
   ```java
   verify(mock).method(anyInt(), anyBoolean());
   ```

3. Use `eq()` for exact values when mixing with matchers.

---

### Custom Matcher Example (Lambda)

```java
verify(mock).processUser(argThat(user -> 
    user.getAge() > 18 && user.getName().startsWith("A")
));
```

Or with a custom class:

```java
verify(service).save(argThat(new ArgumentMatcher<User>() {
    @Override
    public boolean matches(User user) {
        return user != null && user.isActive();
    }
}));
```

---

### Real-World Example

```java
// Stubbing
when(repository.save(any(User.class))).thenAnswer(invocation -> {
    User user = invocation.getArgument(0);
    user.setId(1L);
    return user;
});

// Verification
verify(emailService).sendEmail(
    eq("admin@example.com"),
    contains("Welcome"),
    argThat(list -> list.size() == 1 && list.get(0).contains("user"))
);
```

---

### Maven/Gradle Dependency

```xml
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>5.14.2</version>
    <scope>test</scope>
</dependency>
```

> For advanced matchers like `greaterThan`, `leq`, etc., use:
> ```xml:disable-run
> <dependency>
>     <groupId>org.mockito</groupId>
>     <artifactId>mockito-inline</artifactId>
>     <version>5.14.2</version>
> </dependency>
> ```

---

### Tips

- Prefer **type-safe matchers** like `anyString()` over `any()` when possible.
- Use `ArgumentCaptor` if you need to **capture and inspect** arguments later.
- Combine with `Mockito.lenient()` if strictness causes issues in setup.

---



# ✅ **What Are Argument Matchers in Mockito?**

**Argument Matchers** let you ignore specific values and match method parameters _flexibly_ when stubbing or verifying.

Instead of writing:

```java
when(service.getUserById(10)).thenReturn(user);
```

You can write:

```java
when(service.getUserById(anyInt())).thenReturn(user);
```

→ It matches **any integer**, not just 10.

---

# ✅ **Why Do Matchers Exist?**

Because sometimes **you don't care about the exact argument**, only that **the method is called**.

They let you:

- Ignore a certain parameter
    
- Match values by type (`anyInt()`, `anyString()`)
    
- Match values by conditions (`argThat()`)
    
- Avoid brittle tests
    

---

# ✅ **Common Argument Matchers**

### 🔹 **Type Matchers**

```java
anyInt()
anyString()
anyLong()
anyBoolean()
any()
```

### 🔹 **Equality Matchers**

```java
eq("hello")   // matches exactly "hello"
same(obj)     // matches if it's the same instance
```

### 🔹 **Custom Condition**

```java
argThat(x -> x.startsWith("ethan"))
```

---

# 🔥 **Important Rule**

You **cannot mix** raw values and matchers in the same method call.

❌ Illegal

```java
when(service.create("Ethan", anyInt())).thenReturn(...);
```

✔ Correct

```java
when(service.create(eq("Ethan"), anyInt())).thenReturn(...);
```

All arguments must **either** be matchers **or** all raw values.

---

# ✅ **Example**

```java
verify(repo).save(any(User.class));
```

→ Test only cares the method is called with _some_ user.

---

# ⚡ Summary (super short)

- Mockito **argument matchers** let you match parameters flexibly.
    
- Used in **stubbing** (`when()`) and **verification** (`verify()`).
    
- Most common: `any()`, `eq()`, `argThat()`.
    
- You can’t mix matchers with raw values.
    



##### Tags : [[1 - Junit 5 🥭]]