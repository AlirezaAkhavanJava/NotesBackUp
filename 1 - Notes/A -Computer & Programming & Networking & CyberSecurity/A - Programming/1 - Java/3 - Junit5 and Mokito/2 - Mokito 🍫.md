

## 1️⃣ What is Mockito?

- Mockito is a **mocking framework** for Java.
    
- Used to **simulate the behavior of real objects** in unit tests.
    
- Helps **isolate the class under test** by replacing dependencies with mocks.
    
- Works well with **JUnit 5**.
    

---

## 2️⃣ Core Concepts

|Concept|Description|
|---|---|
|Mock|A fake object with behavior defined by you.|
|Spy|Wraps a real object; you can stub some methods but keep real behavior.|
|Stub|Predefined behavior of a mock for certain inputs.|
|Verify|Check that a method was called on a mock.|

---

## 3️⃣ Basic Mockito Annotations

```java
@Mock      // Creates a mock instance
@InjectMocks // Injects mocks into the tested class
@Spy       // Wraps a real object
```

You need to initialize them with `MockitoAnnotations.openMocks(this)` or use `@ExtendWith(MockitoExtension.class)` for JUnit 5.

---

## 4️⃣ Simple Example

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository repo;  // dependency to mock

    @InjectMocks
    UserService service;  // class under test

    @Test
    void testGetUser() {
        User mockUser = new User("John");
        when(repo.findById(1)).thenReturn(mockUser);  // stub behavior

        User result = service.getUser(1);

        assertEquals("John", result.getName());
        verify(repo).findById(1);  // verify method was called
    }
}
```

---

## 5️⃣ Key Mockito Methods

|Method|Purpose|
|---|---|
|`mock(Class.class)`|Create a mock object manually.|
|`when(...).thenReturn(...)`|Stub a method call.|
|`verify(mock)`|Verify method calls.|
|`times(n)`|Verify how many times a method was called.|
|`doReturn(...).when(mock).method()`|Alternative stubbing for spies.|
|`any() / anyInt() / anyString()`|Argument matchers.|

---

## 6️⃣ Spy Example

```java
List<String> list = new ArrayList<>();
List<String> spyList = spy(list);

doReturn(100).when(spyList).size();  // stub size
spyList.add("Hello");

assertEquals(100, spyList.size());   // overridden
verify(spyList).add("Hello");        // real method still called
```

---

## 7️⃣ Best Practices

- Mock **dependencies**, not the class under test.
    
- Use **@ExtendWith(MockitoExtension.class)** for JUnit 5 integration.
    
- Prefer **`when().thenReturn()`** over `doReturn()` unless spying.
    
- Verify **important interactions only** to avoid brittle tests.
    

---



All-in-one reference for fast mocking and testing.

```java
// ======================
// 1️⃣ Setup Mockito with JUnit 5
// ======================
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class) // Integrates Mockito with JUnit 5
class UserServiceTest {

    // ======================
    // 2️⃣ Annotations
    // ======================
    @Mock           // Creates a mock object
    UserRepository repo;

    @InjectMocks    // Injects mocks into this class
    UserService service;

    @Spy            // Wraps a real object
    List<String> spyList = new ArrayList<>();

    // ======================
    // 3️⃣ Basic Mocking / Stubbing
    // ======================
    @Test
    void testGetUser() {
        User mockUser = new User("John");

        when(repo.findById(1)).thenReturn(mockUser);  // stub method

        User result = service.getUser(1);
        assertEquals("John", result.getName());

        verify(repo).findById(1);                     // verify method call
    }

    // ======================
    // 4️⃣ Verify Method Calls
    // ======================
    @Test
    void testVerifyCalls() {
        repo.findAll();
        repo.findAll();

        verify(repo, times(2)).findAll();  // method called twice
        verify(repo, never()).delete(any()); // method never called
    }

    // ======================
    // 5️⃣ Argument Matchers
    // ======================
    @Test
    void testMatchers() {
        when(repo.findByName(anyString())).thenReturn(new User("Alice"));

        User u = service.getByName("Bob");
        assertEquals("Alice", u.getName());

        verify(repo).findByName(anyString());
    }

    // ======================
    // 6️⃣ Spy Example
    // ======================
    @Test
    void testSpy() {
        spyList.add("Hello");
        doReturn(100).when(spyList).size(); // override size

        assertEquals(100, spyList.size());
        verify(spyList).add("Hello");       // real method still called
    }

    // ======================
    // 7️⃣ Do/When for void methods
    // ======================
    @Test
    void testDoNothing() {
        doNothing().when(repo).delete(any());
        repo.delete(1);
        verify(repo).delete(1);
    }

    // ======================
    // 8️⃣ Reset / Clear Mocks
    // ======================
    @Test
    void testResetMock() {
        when(repo.findAll()).thenReturn(List.of(new User("X")));
        reset(repo);  // clears stubbing & invocations
    }

    // ======================
    // 9️⃣ Exception Throwing
    // ======================
    @Test
    void testException() {
        when(repo.findById(99)).thenThrow(new RuntimeException("Not found"));
        assertThrows(RuntimeException.class, () -> service.getUser(99));
    }
}
```

✅ **Quick Notes:**

- `@Mock` → creates fake dependency.
    
- `@InjectMocks` → injects those fakes into the class under test.
    
- `@Spy` → wrap real object, override selectively.
    
- `verify()` → check method calls.
    
- `any()`, `anyString()`, `anyInt()` → argument matchers.
    
- `doReturn()/doNothing()` → stubbing for void methods or spies.
    
- Always prefer `@ExtendWith(MockitoExtension.class)` for JUnit 5 integration.
    



##### Tags : [[1 - Junit 5 🥭]]