

## 1️⃣ What is `mock()`?

- `mock()` is a **static method from Mockito** that creates a **mock object** of a class or interface.
    
- A mock is a **fake object** whose behavior you can define for testing.
    
- It **does not execute real code** unless you specifically tell it to (with a spy or `doCallRealMethod()`).
    

---

### 2️⃣ Syntax

```java
import static org.mockito.Mockito.*;

MyService serviceMock = mock(MyService.class);
```

Now, `serviceMock` is a fake object of type `MyService`.

---

### 3️⃣ Example Usage

```java
import org.junit.jupiter.api.Test;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class UserServiceTest {

    @Test
    void testGetUser() {
        // Create a mock
        UserRepository repoMock = mock(UserRepository.class);

        // Stub behavior
        when(repoMock.findById(1)).thenReturn(new User("John"));

        // Use the mock in the class under test
        UserService service = new UserService(repoMock);
        User result = service.getUser(1);

        // Assert and verify
        assertEquals("John", result.getName());
        verify(repoMock).findById(1); // check interaction
    }
}
```

---

### 4️⃣ Key Points

- **Use `mock()` when:** You want to isolate a class from its dependencies.
    
- **Mocks do not call real methods** unless you use a spy or `doCallRealMethod()`.
    
- Can be combined with:
    
    - `when().thenReturn()` → stub method results
        
    - `verify()` → check method calls
        
    - `any()`, `anyString()`, `anyInt()` → argument matchers
        

---

### TL;DR 🐐

`mock()` → creates a **fake object** for testing, letting you **control its behavior** and **verify interactions**, without touching the real implementation.




##### Tags : [[1 - Junit 5 🥭]]