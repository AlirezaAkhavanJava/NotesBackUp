

# 🧠 **JUnit 5 `@ExtendWith` — Complete Guide**

---

## 🧩 1️⃣ What is `@ExtendWith`?

`@ExtendWith` is a **JUnit 5 annotation** that allows you to **register extensions** for a test class.

- Extensions can **modify test behavior**, **inject dependencies**, or **manage lifecycle callbacks**.
    
- Mockito provides the `MockitoExtension`, which integrates Mockito with JUnit 5.
    

📦 Package:

```java
org.junit.jupiter.api.extension.ExtendWith
```

---

## 🧩 2️⃣ Why We Use It With Mockito

Without `@ExtendWith(MockitoExtension.class)`, Mockito annotations like `@Mock`, `@InjectMocks`, and `@Spy` **won’t work automatically**.

✅ `@ExtendWith(MockitoExtension.class)` tells JUnit 5 to:

1. Initialize all `@Mock` annotated fields.
    
2. Initialize `@Spy` annotated fields.
    
3. Create and inject `@InjectMocks` objects.
    

---

## 🧩 3️⃣ How to Use `@ExtendWith`

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository repo;

    @InjectMocks
    UserService service;

    @Test
    void testRegister() {
        service.register("Ethan");
        verify(repo).save(any());
    }
}
```

- The `MockitoExtension` handles **mock creation and injection automatically**.
    
- No need to call `MockitoAnnotations.openMocks(this)` manually.
    

---

## 🧩 4️⃣ Without `@ExtendWith` (Old Way)

Before JUnit 5 or without the extension, you had to manually initialize mocks:

```java
@BeforeEach
void setUp() {
    MockitoAnnotations.openMocks(this);
}
```

✅ Using `@ExtendWith(MockitoExtension.class)` eliminates this boilerplate.

---

## 🧩 5️⃣ Multiple Extensions

You can register multiple extensions:

```java
@ExtendWith({MockitoExtension.class, SomeOtherExtension.class})
class MyTest {
    ...
}
```

- JUnit 5 will run **all registered extensions** in order.
    
- Useful if combining Mockito with other testing tools.
    

---

## 🧩 6️⃣ Key Benefits

|Benefit|Explanation|
|---|---|
|Automatic mock creation|`@Mock`, `@Spy` initialized automatically|
|Dependency injection|`@InjectMocks` objects get dependencies injected|
|Cleaner code|No need for `MockitoAnnotations.openMocks(this)`|
|JUnit 5 integration|Works seamlessly with JUnit 5 lifecycle|

---

## 🧩 7️⃣ Common Pitfalls

|Problem|Cause|Fix|
|---|---|---|
|NPE on mock fields|No `@ExtendWith(MockitoExtension.class)`|Add the annotation|
|Annotations not working|Using JUnit 4|Use JUnit 5 + MockitoExtension|
|Multiple extensions conflict|Order-sensitive|Register extensions carefully|

---

## 🧩 8️⃣ Quick Reference Example

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    OrderRepository repo;

    @Spy
    EmailService emailService;

    @InjectMocks
    OrderService service;

    @Captor
    ArgumentCaptor<Order> captor;

    @Test
    void placeOrder() {
        service.placeOrder("item1");

        verify(repo).save(captor.capture());
        assertThat(captor.getValue().getItem()).isEqualTo("item1");
    }
}
```

- Everything works **automatically**: mocks, spies, captors, and injections.
    

---

## 🧠 Final Recap

|Concept|Explanation|
|---|---|
|**@ExtendWith**|Register extensions in JUnit 5|
|**MockitoExtension**|Integrates Mockito with JUnit 5|
|**Purpose**|Auto-initialize `@Mock`, `@Spy`, `@InjectMocks`|
|**Old way**|`MockitoAnnotations.openMocks(this)`|
|**Multiple extensions**|Use array `{...}`|
|**Common pitfall**|Forgetting the annotation → mocks not injected|



##### Tags : [[1 - Junit 5 🥭]]