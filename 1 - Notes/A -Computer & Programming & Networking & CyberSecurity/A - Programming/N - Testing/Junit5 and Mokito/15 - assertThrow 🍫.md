


## 🧩 What is `assertThrows()`

`assertThrows()` checks that **a specific exception** is thrown by a block of code.  
If the code **doesn’t throw** that exception, the test **fails**.

It comes from:

```java
import static org.junit.jupiter.api.Assertions.assertThrows;
```

---

## 🧠 Syntax

```java
assertThrows(ExceptionType.class, () -> {
    // code expected to throw the exception
});
```

Optionally, it **returns** the thrown exception object, so you can check its **message**, **cause**, etc.

---

## 🧪 Example 1 — Simple case

```java
@Test
void testDivideByZero() {
    assertThrows(ArithmeticException.class, () -> {
        int result = 10 / 0;
    });
}
```

✅ Passes because dividing by zero throws `ArithmeticException`.

---

## 🧪 Example 2 — Checking the exception message

```java
@Test
void testExceptionMessage() {
    Exception e = assertThrows(IllegalArgumentException.class, () -> {
        throw new IllegalArgumentException("Invalid input");
    });
    assertEquals("Invalid input", e.getMessage());
}
```

✅ You can now **assert** that the message is correct.

---

## 🧪 Example 3 — Testing a method

```java
class Calculator {
    int divide(int a, int b) {
        if (b == 0) throw new IllegalArgumentException("Cannot divide by zero");
        return a / b;
    }
}

@Test
void testCalculatorDivision() {
    Calculator calc = new Calculator();
    assertThrows(IllegalArgumentException.class, () -> calc.divide(10, 0));
}
```

---

## 🧪 Example 4 — Nested exception checks

You can even check cause chains:

```java
@Test
void testSQLExceptionCause() {
    SQLException ex = assertThrows(SQLException.class, () -> {
        throw new SQLException("Query failed", new RuntimeException("Timeout"));
    });

    assertEquals("Query failed", ex.getMessage());
    assertEquals("Timeout", ex.getCause().getMessage());
}
```

---

## 🧠 Summary

|Feature|`assertThrows()`|
|---|---|
|Works in|JUnit 5|
|Replaces|`@Test(expected = ...)`|
|Returns|The thrown exception|
|Benefits|Can check message, cause, and more|

---
## 🧱 Scenario

You have a **UserService** that fetches users from a repository.  
If the user doesn’t exist, it throws a **custom exception**: `UserNotFoundException`.

---

### 👇 Step 1 — Create the custom exception

```java
package com.arcade.exception;

public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}
```

---

### 👇 Step 2 — Create the service

```java
package com.arcade.service;

import com.arcade.exception.UserNotFoundException;
import com.arcade.model.User;
import com.arcade.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository repo;

    public UserService(UserRepository repo) {
        this.repo = repo;
    }

    public User findUserById(Long id) {
        return repo.findById(id)
                .orElseThrow(() -> new UserNotFoundException("User with id " + id + " not found"));
    }
}
```

---

### 👇 Step 3 — Mock the repository and test exception

```java
package com.arcade.service;

import com.arcade.exception.UserNotFoundException;
import com.arcade.model.User;
import com.arcade.repository.UserRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class UserServiceTest {

    @Test
    void testFindUserByIdThrowsException() {
        // mock repository
        UserRepository mockRepo = mock(UserRepository.class);
        when(mockRepo.findById(1L)).thenReturn(Optional.empty());

        UserService service = new UserService(mockRepo);

        // assert that our exception is thrown
        UserNotFoundException ex = assertThrows(UserNotFoundException.class, () -> {
            service.findUserById(1L);
        });

        // verify message
        assertEquals("User with id 1 not found", ex.getMessage());
    }
}
```

---

### 🧠 Key takeaways

|Concept|Explanation|
|---|---|
|`assertThrows(UserNotFoundException.class, …)`|Ensures the service throws the right type|
|`mock()` + `when()`|Used to simulate repository behavior|
|`assertEquals()`|Checks exception message|
|No `@Test(expected=...)`|JUnit 5 style|


##### Tags : [[1 - Junit 5 🥭]]