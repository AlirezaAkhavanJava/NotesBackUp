


# 🧠 **Mockito `@InjectMocks` — Complete Guide**

---

## 🧩 1️⃣ What is `@InjectMocks`?

`@InjectMocks` is a **Mockito annotation** used to automatically inject **mock dependencies** into the class under test.

- It **creates an instance** of the class you want to test.
    
- It **injects mocks** annotated with `@Mock` or `@Spy` into that instance.
    
- Injection works via **constructor, setter, or field injection**, in that order.
    

---

## 🧩 2️⃣ Why We Use `@InjectMocks`

Instead of manually wiring the class under test:

```java
UserService service = new UserService(userRepo);
```

You can do:

```java
@Mock
UserRepository userRepo;

@InjectMocks
UserService service;
```

Mockito automatically injects `userRepo` into `service`.  
✅ Cleaner, less boilerplate, easier to maintain.

---

## 🧩 3️⃣ How It Works Internally

1. Mockito **creates an instance** of the class marked with `@InjectMocks`.
    
2. It **searches for fields, constructors, or setters** that match the type of your mocks.
    
3. Injects mocks **matching by type**, not by name.
    
4. Works with `@Mock` or `@Spy` annotated objects.
    

---

## 🧩 4️⃣ Injection Strategies

Mockito tries injection in this order:

1. **Constructor Injection** (preferred)
    
    - If class has a constructor that matches **mock types**, it will use it.
        

```java
class UserService {
    private final UserRepository repo;
    private final EmailService emailService;

    public UserService(UserRepository repo, EmailService emailService) {
        this.repo = repo;
        this.emailService = emailService;
    }
}
```

- If `repo` and `emailService` are mocks, they get injected automatically.
    

---

2. **Setter Injection**
    
    - Mockito calls public setters for dependencies if available.
        

```java
class UserService {
    private UserRepository repo;

    public void setRepo(UserRepository repo) {
        this.repo = repo;
    }
}
```

---

3. **Field Injection** (directly into fields)
    
    - If no constructor or setter matches, Mockito injects **private fields** via reflection.
        

```java
class UserService {
    @SuppressWarnings("unused")
    private UserRepository repo;
}
```

---

## 🧩 5️⃣ Basic Example

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository repo;

    @Mock
    EmailService emailService;

    @InjectMocks
    UserService service; // mocks injected automatically

    @Test
    void testRegister() {
        service.register("Ethan");
        verify(repo).save(any());
        verify(emailService).sendWelcomeEmail(any());
    }
}
```

✅ `repo` and `emailService` are automatically injected into `service`.

---

## 🧩 6️⃣ Rules and Tips

|Rule / Tip|Explanation|
|---|---|
|**Type-based injection**|Mockito injects mocks by type. Name doesn’t matter.|
|**Only inject mocks**|Only fields annotated with `@Mock` or `@Spy` are injected.|
|**Works with `@Spy` too**|You can inject spies into the class under test.|
|**Avoid final classes**|Mockito cannot inject mocks into final fields via reflection.|
|**One instance per test**|Each test gets a new `@InjectMocks` instance (JUnit 5 + MockitoExtension).|

---

## 🧩 7️⃣ Using With Multiple Mocks

```java
@Mock
UserRepository repo;

@Mock
EmailService emailService;

@Mock
NotificationService notification;

@InjectMocks
UserService service;
```

- Mockito will scan `UserService` for **fields matching the mock types**:
    
    - Inject `repo` → `UserRepository`
        
    - Inject `emailService` → `EmailService`
        
    - Inject `notification` → `NotificationService`
        

All automatically injected, no manual wiring needed.

---

## 🧩 8️⃣ Constructor Injection Example (Preferred)

```java
class UserService {
    private final UserRepository repo;
    private final EmailService email;

    public UserService(UserRepository repo, EmailService email) {
        this.repo = repo;
        this.email = email;
    }
}
```

Test:

```java
@Mock UserRepository repo;
@Mock EmailService email;
@InjectMocks UserService service; // Mockito uses constructor injection
```

---

## 🧩 9️⃣ Setter Injection Example

```java
class UserService {
    private UserRepository repo;

    public void setRepo(UserRepository repo) {
        this.repo = repo;
    }
}
```

Mockito detects `setRepo()` and injects the mock.

---

## 🧩 🔟 Field Injection Example

```java
class UserService {
    private UserRepository repo; // private field
}
```

Mockito will inject the mock via **reflection**, even if the field is private.

---

## 🧩 10️⃣ Combining With ArgumentCaptor and Matchers

You can fully combine `@InjectMocks` with `ArgumentCaptor`, `any()`, and AssertJ:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock UserRepository repo;
    @Mock EmailService email;

    @InjectMocks UserService service;

    @Captor ArgumentCaptor<User> captor;

    @Test
    void testRegister() {
        service.register("Ethan");

        verify(repo).save(captor.capture());
        assertThat(captor.getValue().getName()).isEqualTo("Ethan");

        verify(email).sendWelcomeEmail(any());
    }
}
```

✅ Shows **full integration**: `@InjectMocks` + mock dependencies + argument capturing + assertions.

---

## 🧩 11️⃣ Common Pitfalls

|Problem|Cause|Fix|
|---|---|---|
|`NullPointerException`|Mockito couldn’t inject a dependency|Ensure the field type matches a `@Mock`|
|`final field not injected`|Reflection cannot inject final fields|Avoid final fields or use constructor injection|
|`multiple constructors`|Mockito picks constructor with **most mocks matching types**|Ensure correct constructor order|
|`no mocks injected`|MockitoExtension not enabled|Add `@ExtendWith(MockitoExtension.class)`|

---

## 🧠 Final Recap

|Concept|Explanation|
|---|---|
|**@InjectMocks**|Automatically inject mocks into the class under test|
|**Injection types**|Constructor → Setter → Field|
|**Dependencies**|Only `@Mock` or `@Spy` objects are injected|
|**Rules**|Type-based, consistent, no final fields (unless constructor)|
|**Use case**|Reduces boilerplate, keeps test setup clean|
|**Works with**|`ArgumentCaptor`, `any()`, `verify()`, AssertJ|

---


##### Tags : [[1 - Junit 5 🥭]]