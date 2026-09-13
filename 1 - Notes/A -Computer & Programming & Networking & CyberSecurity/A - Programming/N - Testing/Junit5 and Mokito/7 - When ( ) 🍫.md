

## 1️⃣ What is `when()`?

- `when()` is used in Mockito to **define the behavior of a mock object**.
    
- You tell the mock: “When this method is called with these arguments, return this value (or throw an exception).”
    
- Syntax:
    

```java
when(mock.method(args)).thenReturn(value);
when(mock.method(args)).thenThrow(exception);
```

- Works **only on mocks or spies**, not on real objects (unless you use spies).
    

---

## 2️⃣ Example

```java
import org.junit.jupiter.api.Test;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class UserServiceTest {

    @Test
    void testGetUser() {
        // Create a mock
        UserRepository repoMock = mock(UserRepository.class);

        // Stub behavior: when findById(1) is called, return a User
        when(repoMock.findById(1)).thenReturn(new User("John"));

        // Use mock in service
        UserService service = new UserService(repoMock);
        User user = service.getUser(1);

        assertEquals("John", user.getName());
        verify(repoMock).findById(1); // verify interaction
    }
}
```

---

## 3️⃣ Throwing Exceptions

```java
when(repoMock.findById(99)).thenThrow(new RuntimeException("Not found"));

assertThrows(RuntimeException.class, () -> service.getUser(99));
```

---

## 4️⃣ Key Notes

- `when()` is **always followed by a method call on the mock**.
    
- Use `thenReturn()` to return a value, `thenThrow()` to throw an exception.
    
- You can also chain behaviors:
    

```java
when(mock.method()).thenReturn(1).thenReturn(2); // first call 1, next call 2
```

- For **void methods**, use `doNothing()`, `doThrow()`, `doAnswer()` instead.
    

---

### TL;DR 🐐

`when()` → tells a mock **what to do when a method is called**.  
It’s the core of **stubbing** in Mockito.

---



##### Tags : [[1 - Junit 5 🥭]]