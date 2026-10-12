


## 🧩 1️⃣ What is `ArgumentCaptor`?

`ArgumentCaptor` is a **utility class** in Mockito that allows you to **capture arguments** that were passed to a mock method, so you can **inspect and assert** them later.

📦 Package:

```java
org.mockito.ArgumentCaptor
```

It’s not for verifying _if_ a method was called — `verify()` does that.  
It’s for checking _what values_ were sent to that method.

---

## 🧩 2️⃣ Why It Exists

Without `ArgumentCaptor`, you can only verify _that_ a method was called:

```java
verify(repo).save(any(User.class));
```

But what if you want to verify **the contents** of that `User` object?

That’s where:

```java
ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
verify(repo).save(captor.capture());
User captured = captor.getValue();
assertThat(captured.getName()).isEqualTo("Ethan");
```

Now you can **assert** exactly what was saved.

---

## 🧩 3️⃣ Creating a Captor

You can create it in two ways:

### Option 1 — Using `forClass()`

```java
ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
```

### Option 2 — Using `@Captor` annotation (cleaner)

```java
@Captor
private ArgumentCaptor<User> captor;
```

✅ Works automatically if you use:

```java
@ExtendWith(MockitoExtension.class)
```

---

## 🧩 4️⃣ How It Works Internally

When Mockito records mock interactions, it stores argument values.  
When you call:

```java
verify(mock).method(captor.capture());
```

Mockito:

1. Matches this verification with the recorded call.
    
2. Hooks the captor into the matching process.
    
3. Stores the actual argument that was passed.
    
4. Later, `captor.getValue()` returns that stored object.
    

So `capture()` acts like a **hook** — not like a matcher.

---

## 🧩 5️⃣ Capturing a Single Argument

### Example

**Code under test:**

```java
class UserService {
    private final UserRepository repo;

    UserService(UserRepository repo) {
        this.repo = repo;
    }

    void register(String name) {
        repo.save(new User(name));
    }
}
```

**Test:**

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository repo;

    @InjectMocks
    UserService service;

    @Captor
    ArgumentCaptor<User> captor;

    @Test
    void shouldCaptureSavedUser() {
        // Act
        service.register("Ethan");

        // Assert
        verify(repo).save(captor.capture());

        User captured = captor.getValue();
        assertThat(captured.getName()).isEqualTo("Ethan");
    }
}
```

✅ `captor.capture()` grabs the `User` argument from `repo.save()`  
✅ `captor.getValue()` retrieves it for inspection

---

## 🧩 6️⃣ Capturing Multiple Calls

If the method was called multiple times, use:

```java
verify(repo, times(3)).save(captor.capture());
List<User> all = captor.getAllValues();
```

Example:

```java
service.register("Ethan");
service.register("Alex");
service.register("John");

verify(repo, times(3)).save(captor.capture());
List<User> allUsers = captor.getAllValues();

assertThat(allUsers).extracting(User::getName)
    .containsExactly("Ethan", "Alex", "John");
```

🧠 `getAllValues()` returns all captured arguments _in order_ of invocation.

---

## 🧩 7️⃣ Capturing Multiple Parameters

If the mocked method takes multiple arguments:

```java
void save(User user, boolean active);
```

You can capture each separately:

```java
@Captor ArgumentCaptor<User> userCaptor;
@Captor ArgumentCaptor<Boolean> boolCaptor;

verify(repo).save(userCaptor.capture(), boolCaptor.capture());

User capturedUser = userCaptor.getValue();
Boolean capturedFlag = boolCaptor.getValue();

assertThat(capturedUser.getName()).isEqualTo("Ethan");
assertThat(capturedFlag).isTrue();
```

---

## 🧩 8️⃣ Using with `any()` and Matchers

### ⚠️ Rule:

You cannot mix **raw values** and **matchers** inconsistently.

❌ WRONG:

```java
verify(repo).save(any(), captor.capture()); // error
```

✅ FIX:  
Use matchers for **all** other arguments:

```java
verify(repo).save(any(User.class), captor.capture());
```

✅ or capture multiple arguments:

```java
verify(repo).save(userCaptor.capture(), flagCaptor.capture());
```

---

## 🧩 9️⃣ Using `ArgumentCaptor` with `then()` (BDDMockito)

Same functionality, just behavior-driven syntax:

```java
then(repo).should().save(captor.capture());
User captured = captor.getValue();
assertThat(captured.getName()).isEqualTo("Ethan");
```

This is preferred when using **BDD-style tests**.

---

## 🧩 🔟 Using `ArgumentCaptor` with AssertJ

Combines perfectly for fluent assertions:

```java
verify(repo).save(captor.capture());
User captured = captor.getValue();

assertThat(captured)
    .isNotNull()
    .extracting(User::getName)
    .isEqualTo("Ethan");
```

Or for complex objects:

```java
assertThat(captured)
    .usingRecursiveComparison()
    .isEqualTo(expectedUser);
```

---

## 🧩 11️⃣ Capturing Complex or Generic Types

If you capture something generic:

```java
@Captor ArgumentCaptor<List<User>> captor;
verify(repo).saveAll(captor.capture());
List<User> users = captor.getValue();
assertThat(users).hasSize(2);
```

Mockito automatically handles generics via type inference in `forClass()` or `@Captor`.

---

## 🧩 12️⃣ Advanced: Capturing Deeply Nested Calls

If you have a call like:

```java
verify(service).process(anyString(), captor.capture());
```

You can capture **only one argument** and ignore the rest with matchers (`any()`, `eq()`, etc.).

---

## 🧩 13️⃣ Common Mistakes & Fixes

|Problem|Cause|Fix|
|---|---|---|
|`Invalid use of argument matchers`|Mixing raw values with matchers|Use matchers (`any()`, `eq()`) consistently|
|`captor.getValue()` returns `null`|Capture not executed|Ensure `verify(mock).method(captor.capture())` runs **after** method invocation|
|`Wanted but not invoked`|Method never called|Check test logic / actual mock usage|
|Wrong captured value|Method called multiple times|Use `getAllValues()` instead of `getValue()`|

---

## 🧩 14️⃣ Common Patterns Summary

|Goal|Example|
|---|---|
|Capture 1 arg|`verify(mock).method(captor.capture())`|
|Capture 2 args|`verify(mock).method(captor1.capture(), captor2.capture())`|
|Capture + matcher|`verify(mock).method(any(), captor.capture())`|
|Get last value|`captor.getValue()`|
|Get all values|`captor.getAllValues()`|
|BDD style|`then(mock).should().method(captor.capture())`|
|Combine with AssertJ|`assertThat(captor.getValue()).isEqualTo(expected)`|

---

## 🧩 15️⃣ Quick Reference Code Snippet

```java
@ExtendWith(MockitoExtension.class)
class ExampleTest {

    @Mock
    MyRepository repo;

    @InjectMocks
    MyService service;

    @Captor
    ArgumentCaptor<MyEntity> captor;

    @Test
    void testCapture() {
        // When
        service.doSomething("Ethan");

        // Then
        verify(repo).save(captor.capture());

        MyEntity captured = captor.getValue();

        assertThat(captured)
            .isNotNull()
            .extracting(MyEntity::getName)
            .isEqualTo("Ethan");
    }
}
```

---

## 🧠 Final Recap

|Concept|Description|
|---|---|
|**Purpose**|Capture and inspect arguments passed to mock methods|
|**Creation**|`ArgumentCaptor.forClass()` or `@Captor`|
|**Integration**|Used with `verify()` or `then().should()`|
|**Retrieval**|`getValue()` (last) or `getAllValues()` (all calls)|
|**Matchers**|Must use matchers (`any()`, `eq()`) for other parameters|
|**Asserting**|Combine with AssertJ for fluent checks|
|**Common Pitfall**|Don’t mix matchers and raw args inconsistently|

---



##### Tags : [[1 - Junit 5 🥭]]