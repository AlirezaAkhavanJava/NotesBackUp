
# ✅ THE 10 RULES OF TESTING (THE TRUTHFUL VERSION)

## **Rule 1 — Only test ONE layer at a time**

This is the #1 rule you keep breaking.

|Test type|What to mock|What NOT to mock|
|---|---|---|
|**Controller test**|Service|Controller, Repository|
|**Service test**|Repository|Service, Controller|
|**Repository test**|NOTHING|Anything|

You NEVER test multiple layers together unless it's an integration test.

---

## **Rule 2 — NEVER mock the class you're testing**

You test _real logic_, not a mocked fake version of the same class.

❌ Wrong:

```java
when(userController.findByName("x")).thenReturn(...)
```

You're destroying your own test.

---

## **Rule 3 — Do not chain mocks**

Never do this:

```java
when(service.method()).thenReturn(repository.method());
```

Mocks return simple values.  
Not results of other mocks.

Correct:

```java
when(repository.method()).thenReturn("abc");
```

---

## **Rule 4 — Arrange → Act → Assert**

Every test should follow this order:

1. **Arrange** – create data, mock behavior
    
2. **Act** – call the method under test
    
3. **Assert** – verify result + interactions
    

Example:

```java
// Arrange
when(service.getUser(1L)).thenReturn(mockUser);

// Act
User result = controller.getUser(1L);

// Assert
assertEquals("John", result.getName());
verify(service).getUser(1L);
```

---

## **Rule 5 — Use `verify()` only to check behavior**

You use `verify()` **only** to check that your method called another method.

Correct:

```java
verify(service).save(user);
```

But do **not** abuse it.  
If asserting the return value is enough → skip verify.

---

## **Rule 6 — Don’t test trivial getters/setters**

JUnit is not for testing POJOs unless they contain logic.

❌ Useless:

```java
assertEquals("Ethan", user.getName());
```

---

## **Rule 7 — Mock only what you OWN**

If you don’t own the code (like `JdbcTemplate`, `RestTemplate`) → mock them.

If you own the code, you test the real version unless it connects to:

- database
    
- network
    
- file system
    
- external API
    

---

## **Rule 8 — Keep tests independent**

Tests should NEVER depend on:

- global state
    
- run order
    
- shared static variables
    

Every test must run alone.

---

## **Rule 9 — Name tests like stories**

Clear, readable, meaningful.

Good:

```java
getUserById_ShouldReturnUser_WhenUserExists()
```

Bad:

```java
test1()
```

---

## **Rule 10 — Test behavior, not implementation**

You test **what the method does**, not **how it does it**.

If implementation changes but result same → test should not break.

Example:  
You test:

- business rules
    
- validation
    
- returned data
    

NOT how many loops, variables, or internal steps exist.

---

# 📌 Bonus rule — Unit tests are NOT integration tests

Unit test:  
✔ fast  
✔ small  
✔ isolated  
✔ mocked dependencies

Integration test:  
✔ tests multiple layers  
✔ uses real DB (H2)  
✔ slow  
✔ no mocks

Don’t mix them.

---


##### Tags : [[1 - Junit 5 🥭]]