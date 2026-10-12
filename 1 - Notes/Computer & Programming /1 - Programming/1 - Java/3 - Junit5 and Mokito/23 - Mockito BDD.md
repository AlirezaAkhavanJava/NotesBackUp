
**Mockito BDD** (Behavior-Driven Development style) is just a _different syntax_ for writing Mockito tests — it’s meant to make tests read more like natural language, following the **Given–When–Then** pattern used in BDD.

Instead of this classic Mockito style:

```java
when(service.getData()).thenReturn("mocked data");
String result = service.getData();
verify(service).getData();
```

You write it in **BDD style** using `BDDMockito`:

```java
given(service.getData()).willReturn("mocked data");
String result = service.getData();
then(service).should().getData();
```

### 🔹 Differences:

|Traditional Mockito|BDDMockito|
|---|---|
|`when(...).thenReturn(...)`|`given(...).willReturn(...)`|
|`verify(mock)`|`then(mock).should()`|
|`verify(mock, times(2))`|`then(mock).should(times(2))`|

### 🔹 Why use it

- Makes test intent clearer (`given/when/then` reads more like a scenario)
    
- Encourages good structure in tests (setup → action → verification)
    
- Common in teams using BDD frameworks like **Cucumber** or **JBehave**
    

In short:  
**Mockito BDD = same Mockito behavior, just a more expressive BDD-style syntax.**


---
## 🧩 **Mockito BDD Cheatsheet**

### ✅ **1. Given (Stubbing Behavior)**

Used to define _what the mock should do_ when a method is called.

|Method|Description|Example|
|---|---|---|
|`given(mock.method()).willReturn(value)`|Return a specific value|`given(userService.getUserName()).willReturn("Ethan");`|
|`given(mock.method()).willThrow(Exception.class)`|Throw an exception|`given(service.fetch()).willThrow(RuntimeException.class);`|
|`given(mock.method()).willAnswer(answer)`|Custom logic for mock response|`given(calc.add(anyInt(), anyInt())).willAnswer(i -> (int)i.getArgument(0) + (int)i.getArgument(1));`|
|`willDoNothing().given(mock).method()`|Do nothing (for void methods)|`willDoNothing().given(logger).log(anyString());`|
|`willThrow(Exception).given(mock).method()`|Throw on void method|`willThrow(IOException.class).given(fileService).delete();`|

---

### 🚀 **2. When (The Action You Test)**

Represents the actual call under test (the “act” step).

```java
// Example scenario
String result = service.processData("input");
```

> 💡 In BDDMockito, “when” is usually implicit — you just call the real method after `given(...)`.

---

### 🧾 **3. Then (Verification)**

Used to **verify interactions** or **assert expected behavior**.

|Method|Description|Example|
|---|---|---|
|`then(mock).should().method()`|Verify method was called|`then(repo).should().save(user);`|
|`then(mock).should(times(n)).method()`|Verify called n times|`then(repo).should(times(2)).save(any());`|
|`then(mock).shouldHaveNoMoreInteractions()`|Verify no other calls happened|`then(repo).shouldHaveNoMoreInteractions();`|
|`then(mock).shouldHaveZeroInteractions()`|Verify no calls at all|`then(repo).shouldHaveZeroInteractions();`|
|`then(mock).should(timeout(ms)).method()`|Verify async call within time|`then(service).should(timeout(500)).notify();`|
|`then(mock).should(atLeast(n)).method()`|Verify called at least n times|`then(repo).should(atLeast(1)).findAll();`|

---

### ⚙️ **4. Argument Capturing**

Use when you want to inspect what arguments were passed to a mock.

```java
@Captor ArgumentCaptor<User> captor;

given(repo.save(any(User.class))).willReturn(savedUser);
service.createUser("Ethan");

// Verify and capture argument
then(repo).should().save(captor.capture());
assertEquals("Ethan", captor.getValue().getName());
```

---

### 🧠 **5. Typical BDD Mockito Test Structure**

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock UserRepository repo;
    @InjectMocks UserService service;

    @Test
    void shouldCreateUserSuccessfully() {
        // GIVEN
        given(repo.save(any(User.class))).willReturn(new User("Ethan"));

        // WHEN
        User user = service.createUser("Ethan");

        // THEN
        then(repo).should().save(any(User.class));
        assertEquals("Ethan", user.getName());
    }
}
```

---

### 🧩 **6. Common Scenarios**

|Scenario|Example|
|---|---|
|Return fixed data|`given(service.findById(1)).willReturn(user);`|
|Void method throwing error|`willThrow(IllegalStateException.class).given(service).deleteAll();`|
|Verifying interaction count|`then(repo).should(times(3)).findAll();`|
|No unwanted interactions|`then(repo).shouldHaveNoMoreInteractions();`|
|Custom logic for mock|`given(calc.add(anyInt(), anyInt())).willAnswer(i -> i.getArgument(0, Integer.class) + i.getArgument(1, Integer.class));`|

---



##### Tags : [[1 - Junit 5 🥭]]