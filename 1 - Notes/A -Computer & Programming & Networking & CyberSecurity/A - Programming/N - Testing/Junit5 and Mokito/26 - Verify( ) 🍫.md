
## 🧩 1. `verify()`

Used to **check interactions** with your mock — i.e., whether a method was called, and how many times.

> `verify()` **doesn’t run the real code**—it only checks that the mocked method was **called (or not called) as expected**.


```java
verify(mock).someMethod();
```

✔️ Checks that `someMethod()` was called **exactly once**.

If you expect multiple or zero calls:

```java
verify(mock, times(2)).save(any());
verify(mock, never()).delete(any());
verify(mock, atLeastOnce()).findAll();
verify(mock, atMost(3)).update(any());
```

---

## 🧩 2. `verifyNoMoreInteractions()` and `verifyNoInteractions()`

Check **interaction count**:

```java
verifyNoMoreInteractions(mock);
```

✔️ Ensures no **extra** calls happened beyond verified ones.

```java
verifyNoInteractions(mock);
```

✔️ Ensures mock was **never used** at all.

---

## 🧩 3. `ArgumentCaptor<T>`

Used when you want to **inspect the actual argument** passed to a mocked method.

Example:

```java
@Mock
UserRepository repo;

@Test
void testSaveUser() {
    ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
    
    service.register("Ethan", "1234"); // service calls repo.save(user)
    
    verify(repo).save(captor.capture());
    User captured = captor.getValue();
    
    assertEquals("Ethan", captured.getName());
}
```

🧠 Notes:

- `.getValue()` → returns single captured arg
    
- `.getAllValues()` → returns list (for multiple calls)
    

---

## 🧩 4. `capture()` + BDD-style `then()`

If you’re using **BDDMockito** (`import static org.mockito.BDDMockito.*;`),  
you can write the same logic more behavior-driven:

```java
then(repo).should().save(captor.capture());
```

Same effect as `verify(repo).save(captor.capture());`

---

## 🧩 5. Combining with Matchers

You can mix `ArgumentCaptor` with `Matchers`:

❌ WRONG:

```java
verify(repo).save(any(), captor.capture()); // can't mix like this
```

✔️ FIX:  
Use `ArgumentCaptor` for all arguments you want to capture:

```java
verify(repo).save(any(), captor.capture());
```

OR just one argument if method has multiple parameters and you only care about one.

---

## 🧩 6. Chaining Verifications

Mockito lets you verify call **order**:

```java
InOrder inOrder = inOrder(repo1, repo2);
inOrder.verify(repo1).save(any());
inOrder.verify(repo2).flush();
```

Ensures repo1.save() happened before repo2.flush().

---

## 🧩 7. Advanced Example

```java
@Test
void testProcessOrder() {
    ArgumentCaptor<Order> captor = ArgumentCaptor.forClass(Order.class);

    service.processOrder(123L);

    verify(orderRepo, times(1)).save(captor.capture());
    Order savedOrder = captor.getValue();

    assertEquals(OrderStatus.PROCESSED, savedOrder.getStatus());
    assertTrue(savedOrder.getTimestamp().isBefore(LocalDateTime.now()));
}
```

---

## 🧩 8. Common Gotchas 🧠

|Problem|Fix|
|---|---|
|Captor returns null|Ensure `.capture()` is used inside `verify()` or `then().should()`|
|Mixed `any()` and real objects|Mockito won’t match — use all matchers or all real values|
|Wrong verify order|Use `InOrder`|
|Method not called|Verify fails — check actual call paths|

---

## 🧠 Summary Cheat Sheet

|Purpose|Method|Example|
|---|---|---|
|Verify method called|`verify(mock).method()`|`verify(repo).save(user)`|
|Verify call count|`times(n)`|`verify(repo, times(2)).findAll()`|
|Verify never called|`never()`|`verify(repo, never()).delete()`|
|Verify at least|`atLeastOnce()`|`verify(repo, atLeastOnce()).save(any())`|
|Capture argument|`ArgumentCaptor<T>`|`verify(repo).save(captor.capture())`|
|Get captured value|`.getValue()`|`captor.getValue()`|
|BDD verify|`then(mock).should()`|`then(repo).should().save(any())`|
|Verify order|`InOrder`|`inOrder(repo1, repo2)`|
|No more interactions|`verifyNoMoreInteractions()`|`verifyNoMoreInteractions(repo)`|

---

##### Tags : [[1 - Junit 5 🥭]]