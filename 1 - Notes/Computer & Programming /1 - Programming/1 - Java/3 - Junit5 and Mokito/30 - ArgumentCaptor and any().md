


## 🧩 1️⃣ The Purpose Recap

👉 `verify(mock).method(captor.capture())`  
This line tells Mockito:

> “When this mock’s method was called, capture the **argument value** that was passed.”

Then you can inspect that value using:

```java
captor.getValue();
```

---

## 🧩 2️⃣ Basic Example

Let’s say you have a simple service:

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

Test:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository repo;

    @InjectMocks
    private UserService service;

    @Captor
    private ArgumentCaptor<User> captor;

    @Test
    void shouldCaptureSavedUser() {
        // act
        service.register("Ethan");

        // assert
        verify(repo).save(captor.capture());

        User captured = captor.getValue();
        assertThat(captured.getName()).isEqualTo("Ethan");
    }
}
```

✅ Works perfectly.

---

## 🧩 3️⃣ Mixing `any()` and `ArgumentCaptor`

Let’s say your mocked method takes **multiple parameters**:

```java
void save(User user, boolean active);
```

If you want to capture only one parameter, you might be tempted to write:

```java
verify(repo).save(any(), captor.capture()); // ❌ WRONG
```

This causes:

> “Invalid use of argument matchers” exception

because Mockito **doesn’t allow mixing real values and matchers** inconsistently.  
Both parameters must either use **matchers** or **real values**, but `capture()` is _not_ a matcher — it’s a special hook.

---

### ✅ Correct ways to fix it:

#### Option 1 — Capture first, use `any()` for the rest:

```java
verify(repo).save(captor.capture(), anyBoolean());
```

✔ Works — all arguments use either a matcher or capture.

#### Option 2 — Capture multiple arguments:

```java
@Captor ArgumentCaptor<User> userCaptor;
@Captor ArgumentCaptor<Boolean> activeCaptor;

verify(repo).save(userCaptor.capture(), activeCaptor.capture());
```

Then:

```java
User capturedUser = userCaptor.getValue();
Boolean capturedFlag = activeCaptor.getValue();
```

---

## 🧩 4️⃣ When You Need `.getValue()` vs `.getAllValues()`

|Method|Description|
|---|---|
|`captor.getValue()`|Returns the **last captured** value|
|`captor.getAllValues()`|Returns a **list** of all captured values (if method called multiple times)|

Example:

```java
verify(repo, times(3)).save(captor.capture());
List<User> all = captor.getAllValues();
assertThat(all).extracting(User::getName)
               .containsExactly("Ethan", "Alex", "John");
```

---

## 🧩 5️⃣ The Internal Flow (How Mockito Handles It)

Here’s what happens under the hood:

1. You call `service.register("Ethan")` → mock method runs (`repo.save(...)`).
    
2. Mockito **records** this invocation.
    
3. You call `verify(repo).save(captor.capture())`.
    
4. Mockito **replays** recorded calls and **matches** arguments.
    
5. The captor **hooks** into the matching process, **grabs** the argument value, and stores it internally.
    
6. When you call `captor.getValue()`, you get that stored argument.
    

---

## 🧩 6️⃣ Combining with `any()` in Complex Methods

Example:

```java
verify(service).processOrder(eq("123"), anyList(), captor.capture());
```

Here:

- `eq("123")` checks first argument is `"123"`.
    
- `anyList()` ignores the second argument.
    
- `captor.capture()` grabs the **third argument**.
    

---

## 🧩 7️⃣ Full Example — Multiple Captures + Any()

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    OrderRepository repo;

    @InjectMocks
    OrderService service;

    @Captor
    ArgumentCaptor<Order> orderCaptor;

    @Captor
    ArgumentCaptor<Boolean> boolCaptor;

    @Test
    void shouldCaptureMultipleArgs() {
        service.placeOrder("Ethan", true);

        verify(repo).save(orderCaptor.capture(), boolCaptor.capture());

        assertThat(orderCaptor.getValue().getCustomerName()).isEqualTo("Ethan");
        assertThat(boolCaptor.getValue()).isTrue();
    }
}
```

---

## 🧠 Pro Tips

|Tip|Explanation|
|---|---|
|✅ Always use `@Captor` instead of `forClass()` for cleaner code||
|🚫 Don’t mix matchers and real args unless all are matchers||
|✅ Use `eq()` for constants + `any()` for ignored args||
|✅ Use `.getAllValues()` if method is called multiple times||
|⚡ Use `then(mock).should().method(captor.capture())` for BDD style||

---

## 🧠 Quick Summary

|Task|Syntax|
|---|---|
|Capture single argument|`verify(mock).method(captor.capture())`|
|Capture one + ignore rest|`verify(mock).method(captor.capture(), any())`|
|Capture multiple|`verify(mock).method(captor1.capture(), captor2.capture())`|
|Get single arg|`captor.getValue()`|
|Get multiple calls|`captor.getAllValues()`|

---

##### Tags : [[1 - Junit 5 🥭]]