


## 🧩 1️⃣ What Is a Custom Matcher?

- Sometimes, the built-in matchers (`any()`, `eq()`, `contains()`, etc.) are **not enough**.
    
- A **custom argument matcher** lets you **define your own logic** to determine if a method argument matches.
    
- Useful for **complex objects, nested fields, or conditions**.
    

---

## 🧩 2️⃣ Basic Syntax: `argThat`

Mockito provides the method `argThat()` for custom matching:

```java
verify(mock).method(argThat(argument -> {
    // return true if matches, false otherwise
}));
```

- `argThat()` accepts a **lambda or Predicate** returning `boolean`.
    
- The lambda is evaluated for the argument passed to the mock method.
    

---

## 🧩 3️⃣ Example: Simple Object Match

Suppose you have a `User` class:

```java
class User {
    String name;
    int age;
    // constructor, getters
}
```

You want to verify that a user with **age > 18** was saved:

```java
verify(repo).save(argThat(user -> user.getAge() > 18));
```

- The lambda returns `true` if `user.getAge() > 18`.
    
- If the condition is false, Mockito considers it a **mismatch** and the verification fails.
    

---

## 🧩 4️⃣ Using AssertJ Inside a Custom Matcher

You can combine **AssertJ assertions** with `argThat()` for complex checks:

```java
verify(repo).save(argThat(user -> {
    assertThat(user.getName()).startsWith("E");
    assertThat(user.getAge()).isBetween(18, 30);
    return true; // always return true because we use assertions to fail test if invalid
}));
```

- Assertions inside the lambda fail the test if conditions are not met.
    
- `return true` ensures Mockito sees the argument as “matched.”
    

---

## 🧩 5️⃣ Custom Matcher as a Class

For reusability, you can create a **dedicated class implementing `ArgumentMatcher<T>`**:

```java
import org.mockito.ArgumentMatcher;

class AdultUserMatcher implements ArgumentMatcher<User> {
    @Override
    public boolean matches(User user) {
        return user.getAge() >= 18;
    }

    @Override
    public String toString() {
        return "User with age >= 18";
    }
}
```

Then use it in tests:

```java
verify(repo).save(argThat(new AdultUserMatcher()));
```

- `toString()` is optional but improves error messages when verification fails.
    

---

## 🧩 6️⃣ Combining With `any()` and Other Matchers

Custom matchers can be combined with standard matchers:

```java
verify(service).process(anyString(), argThat(user -> user.getAge() > 18));
```

- First argument matches **any string**.
    
- Second argument matches **custom condition**.
    

---

## 🧩 7️⃣ Using `argThat` in Stubbing

Custom matchers are not only for verification — also for stubbing:

```java
when(repo.save(argThat(user -> user.getAge() > 18)))
        .thenReturn(true);
```

- This stub is triggered only if the argument **matches the lambda**.
    
- Otherwise, Mockito uses the default behavior (`false` or `null`).
    

---

## 🧩 8️⃣ Advanced: Matching Collections

You can also write custom matchers for **collections**:

```java
verify(service).process(argThat(list -> 
    list.size() == 3 && list.contains("Ethan")
));
```

- Lambda returns `true` if the collection meets your custom condition.
    

---

## 🧩 9️⃣ Common Pitfalls

|Problem|Cause|Fix|
|---|---|---|
|Verification fails unexpectedly|Lambda returns false|Ensure logic returns true for valid matches|
|NPE in lambda|Argument is null|Handle nulls in your matcher: `user != null && user.getAge() > 18`|
|Complex reusable logic|Inline lambda becomes messy|Use `ArgumentMatcher<T>` class|
|Confusing return value|Must return `true` if match succeeds|Lambda must return boolean|

---

## 🧩 🔟 Quick Reference Examples

### Inline Lambda Matcher

```java
verify(repo).save(argThat(user -> user.getAge() > 18));
```

### AssertJ Inside Lambda

```java
verify(repo).save(argThat(user -> {
    assertThat(user.getName()).startsWith("E");
    return true;
}));
```

### Custom Class Matcher

```java
verify(repo).save(argThat(new AdultUserMatcher()));
```

### Stubbing with Custom Matcher

```java
when(repo.save(argThat(user -> user.getAge() > 18)))
        .thenReturn(true);
```

### Collection Matcher

```java
verify(service).process(argThat(list -> list.size() == 3));
```

---

## 🧩 11️⃣ Summary

|Feature|Explanation|
|---|---|
|Purpose|Define custom rules for argument matching|
|Method|`argThat()` or `ArgumentMatcher<T>`|
|Inline Lambda|Quick one-off matchers|
|Class Matcher|Reusable matcher logic|
|Verification|Works with `verify()`|
|Stubbing|Works with `when()`|
|Tips|Handle nulls, return true for valid matches, use `toString()` for better error messages|

---

✅ Using **custom matchers**, you can now test **complex argument conditions** that built-in matchers can’t handle.



##### Tags : [[1 - Junit 5 🥭]]