
### **1️⃣ @Spy**

- Creates a **partial mock** — the real object is used, but you can **override some methods**.
    
- Useful when you want **real logic for most methods** but **stub or control some**.
    

```java
@Spy
RealOne realOne;

@Test
void testSpy() {
    doReturn("avaJ").when(realOne).reverser("Java"); // stub one method
    assertEquals("avaJ", realOne.reverser("Java"));
}
```

**Key:** Real methods run unless you `doReturn()` or `doThrow()`.

---

### **2️⃣ @InjectMocks**

- Creates an instance of the class and **injects all @Mock or @Spy fields** into it.
    
- Automatically wires dependencies (like Spring’s `@Autowired` but for testing).
    

```java
class Service {
    private Repository repo;
    public Service(Repository repo) { this.repo = repo; }
    public String getData() { return repo.fetch(); }
}

@Mock
Repository repo;

@InjectMocks
Service service; // repo is automatically injected

@Test
void testService() {
    when(repo.fetch()).thenReturn("mocked data");
    assertEquals("mocked data", service.getData());
}
```

**Key:** `@InjectMocks` is all about **dependency injection** for the class under test.

---

### ✅ Quick comparison

|Annotation|Purpose|Real object run?|
|---|---|---|
|`@Spy`|Partial mock of a real object|Yes, unless stubbed|
|`@InjectMocks`|Create object and inject mocks/spies|N/A (creates new instance)|

---

In practice:

- Use **`@Spy`** when you want **partial mocking**.
    
- Use **`@InjectMocks`** when you want to **test a class with mocked dependencies** automatically injected.
##### Tags : [[1 - Junit 5 🥭]]