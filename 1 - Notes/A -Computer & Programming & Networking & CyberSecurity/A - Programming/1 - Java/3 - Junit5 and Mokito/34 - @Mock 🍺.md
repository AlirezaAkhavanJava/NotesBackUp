


# 🧠 **Mockito `@Mock` — Complete Guide**

---

## 🧩 1️⃣ What is `@Mock`?

`@Mock` is a **Mockito annotation** that creates a **mock instance** of a class or interface.

- Mocks are **fake objects** that mimic real objects for testing.
    
- They **record interactions** (method calls, arguments, call count).
    
- They **return default values** for unstubbed methods (`null`, `0`, `false`, empty collections).
    

📦 Package:

```java
org.mockito.Mock
```

---

## 🧩 2️⃣ Why We Use `@Mock`

- To **isolate the class under test** from its dependencies.
    
- To **control behavior** of dependencies for predictable tests.
    
- To **verify interactions** (method calls, arguments, number of calls).
    

Without `@Mock`, you’d have to manually create fake objects or pass real implementations — more boilerplate, slower tests, and harder to isolate bugs.

---

## 🧩 3️⃣ How to Create a Mock

### Option 1 — Using `@Mock` annotation

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository repo;  // Mockito creates a mock instance automatically
}
```

### Option 2 — Using `Mockito.mock()` method

```java
UserRepository repo = Mockito.mock(UserRepository.class);
```

✅ Both are equivalent; `@Mock` is cleaner with JUnit 5 + MockitoExtension.

---

## 🧩 4️⃣ Mock Behavior — Default

Unstubbed methods return:

|Type|Default value|
|---|---|
|Object|`null`|
|int/long/short/byte|`0`|
|float/double|`0.0`|
|boolean|`false`|
|Collection|empty list/set/map|
|Optional|`Optional.empty()`|

📘 Example:

```java
@Mock UserRepository repo;

@Test
void defaultBehavior() {
    assertThat(repo.findById(1L)).isNull();
    assertThat(repo.count()).isZero();
}
```

---

## 🧩 5️⃣ Stubbing Methods

Use `when(...).thenReturn(...)` or `doReturn(...).when(...)`:

```java
when(repo.findById(1L)).thenReturn(new User("Ethan"));
when(repo.existsByName(anyString())).thenReturn(true);
```

- Use `doReturn()` for **spies** or **void methods**:
    

```java
doReturn(new User("Ethan")).when(spyRepo).findById(1L);
doNothing().when(repo).delete(any());
```

---

## 🧩 6️⃣ Verifying Interactions

Mocks let you verify **how your class under test interacts with dependencies**:

```java
verify(repo).save(any(User.class));          // method called once
verify(repo, times(2)).save(any(User.class));// called twice
verify(repo, never()).delete(any());        // never called
verify(repo, atLeastOnce()).findById(1L);  // called at least once
```

---

## 🧩 7️⃣ Using With `@InjectMocks`

`@Mock` is **commonly used with `@InjectMocks`** to provide dependencies for the class under test:

```java
@Mock UserRepository repo;
@Mock EmailService email;

@InjectMocks UserService service;
```

- `service` gets `repo` and `email` injected automatically.
    
- All interactions with `service` can be verified through the mocks.
    

---

## 🧩 8️⃣ Spying vs Mocking

|Concept|@Mock|@Spy|
|---|---|---|
|Object type|Fake object|Wraps real object|
|Calls|Nothing happens unless stubbed|Calls real method by default|
|Use case|Isolate class under test|Partially test real behavior|
|Example|`@Mock UserRepository repo;`|`@Spy ArrayList<String> list;`|

✅ You can inject both mocks and spies into `@InjectMocks`.

---

## 🧩 9️⃣ Common Pitfalls & Fixes

|Problem|Cause|Fix|
|---|---|---|
|NPE when calling mock|MockitoExtension not enabled|Add `@ExtendWith(MockitoExtension.class)`|
|Real method called accidentally|Using spy instead of mock|Use `doReturn()` for spies|
|Matcher error|Mixing raw values & matchers|Use matchers for all arguments in a call|
|Dependency not injected|@InjectMocks + @Mock type mismatch|Ensure mock type matches constructor/field|

---

## 🧩 🔟 Quick Reference Examples

### Stubbing

```java
when(repo.findById(1L)).thenReturn(new User("Ethan"));
when(repo.existsByName(anyString())).thenReturn(true);
doNothing().when(repo).delete(any());
```

### Verifying

```java
verify(repo).save(any(User.class));
verify(repo, never()).delete(any());
verify(repo, times(2)).save(any(User.class));
```

### ArgumentCaptor + Mock

```java
@Captor ArgumentCaptor<User> captor;
verify(repo).save(captor.capture());
assertThat(captor.getValue().getName()).isEqualTo("Ethan");
```

### InjectMocks + Mocks

```java
@Mock UserRepository repo;
@InjectMocks UserService service;
```

---

## 🧩 11️⃣ Summary Table

|Feature|@Mock|
|---|---|
|Purpose|Create mock objects for testing|
|Use with|@InjectMocks for dependencies|
|Default behavior|Returns default values|
|Stubbing|when(...).thenReturn(...)|
|Verifying|verify(mock).method(...)|
|Advanced|Spies, ArgumentCaptor, matchers|
|Rule|Always use MockitoExtension with `@Mock` in JUnit 5|



##### Tags : [[1 - Junit 5 🥭]]