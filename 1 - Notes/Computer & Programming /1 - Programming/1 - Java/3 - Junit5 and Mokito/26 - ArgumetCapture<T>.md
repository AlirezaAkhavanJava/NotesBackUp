
## 🧱 Class: `org.mockito.ArgumentCaptor<T>`

### ✅ Purpose

`ArgumentCaptor` is a **helper class** that lets you _capture the arguments_ passed to a mock’s method, so you can **inspect or assert their values later**.

---

### ✅ Declaration

```java
public class ArgumentCaptor<T> {
    public static <T> ArgumentCaptor<T> forClass(Class<T> clazz)
}
```

You create it like this:

```java
ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
```

---

### ✅ Usage Pattern

Usually combined with `verify()` (or BDD `then().should()`):

```java
// Arrange
ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);

// Act
service.registerUser("Ethan", "pass123");

// Assert
verify(userRepository).save(captor.capture());

User captured = captor.getValue();
assertEquals("Ethan", captured.getName());
```

---

### ✅ Core Methods

|Method|Description|
|---|---|
|`capture()`|Used inside `verify()` or `then().should()` to record the argument|
|`getValue()`|Returns the **last captured argument**|
|`getAllValues()`|Returns a **list** of all captured arguments (if method called multiple times)|
|`forClass(Class<T>)`|Factory method to create the captor|

---

### ✅ Multiple Captures Example

```java
ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);

verify(repo, times(2)).save(captor.capture());

List<User> all = captor.getAllValues();
assertEquals("Ethan", all.get(0).getName());
assertEquals("Alex", all.get(1).getName());
```

---

### ✅ Works with BDDMockito too

```java
then(repo).should().save(captor.capture());
User captured = captor.getValue();
```

---

### 🧠 Notes

- `ArgumentCaptor` only works with **mocks**, not real objects.
    
- Must be used **after the method call** — it doesn’t intercept calls in advance.
    
- Don’t mix real arguments with matchers (`any()`, `eq()`) in the same call — Mockito forbids that.
    

---

So in summary:

|Wrong Term|Correct Class|Package|
|---|---|---|
|`ArgumentCapture`|✅ `ArgumentCaptor<T>`|`org.mockito.ArgumentCaptor`|

---



##### Tags : [[1 - Junit 5 🥭]]