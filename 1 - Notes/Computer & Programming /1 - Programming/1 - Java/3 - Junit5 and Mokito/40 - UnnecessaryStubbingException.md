
### **`UnnecessaryStubbingException` explained**

Mockito is telling you:

> “Hey, you told me to stub something (`when(...).thenReturn(...)`) but none of your tests actually **used** it. I don’t like dead code—clean it up.”

---

### **Why it happens**

Example:

```java
@BeforeEach
void setUp() {
    when(user.getName()).thenReturn("Alex");
    when(user.getEmail()).thenReturn("alex@example.com"); // <- never called
}

@Test
void testName() {
    assertEquals("Alex", user.getName());
}
```

- `getEmail()` is **never called** → strict mode sees it as unnecessary → throws `UnnecessaryStubbingException`.
    

---

### **How to fix it**

**Option 1: Only stub what you actually use in the test**

```java
@BeforeEach
void setUp() {
    when(user.getName()).thenReturn("Alex");
    // remove getEmail() stub if not used
}
```

**Option 2: Make the stub lenient**

```java
@BeforeEach
void setUp() {
    lenient().when(user.getName()).thenReturn("Alex");
    lenient().when(user.getEmail()).thenReturn("alex@example.com");
}
```

- `lenient()` tells Mockito: “I know it might not be used, don’t complain.”
    

**Option 3: Stub inside each test instead of `@BeforeEach`**

```java
@Test
void testName() {
    when(user.getName()).thenReturn("Alex");
    assertEquals("Alex", user.getName());
}
```

- This is the **cleanest approach** if stubs vary per test.
    

---

### **Rule of thumb**

- **Strict mode is good**: it catches “dead stubs” and keeps your tests clean.
    
- Only use `lenient()` if you genuinely need stubs that some tests won’t use.
    
- Don’t put stubs in `@BeforeEach` unless **every test uses them**.
    


#### Tags : [[1 - Junit 5 🥭]]