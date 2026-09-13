


# 🧠 **Mockito `@Spy` — Complete Guide**

---

## 🧩 1️⃣ What is `@Spy`?

`@Spy` is a Mockito annotation that creates a **partial mock**:

- It wraps a **real instance** of a class.
    
- **Real methods** are called by default.
    
- You can **stub specific methods** to override behavior.
    
- Often used when you want to **verify interactions** but still use actual implementation.
    

📦 Package:

```java
org.mockito.Spy
```

---

## 🧩 2️⃣ Difference Between `@Mock` and `@Spy`

|Feature|@Mock|@Spy|
|---|---|---|
|Behavior|All methods do nothing by default (return default values)|Real methods are called by default|
|Stubbing|Needed for every behavior|Only stub what you want to override|
|Use case|Isolate class under test|Partially test real object behavior|
|Verification|Works same as mock|Works same as mock|

✅ Rule of thumb:

- Use **mock** to isolate.
    
- Use **spy** to partially use real logic but still verify interactions.
    

---

## 🧩 3️⃣ Creating a Spy

### Option 1 — Annotation

```java
@Spy
ArrayList<String> list = new ArrayList<>();
```

### Option 2 — Mockito.spy()

```java
List<String> list = Mockito.spy(new ArrayList<>());
```

---

## 🧩 4️⃣ Default Behavior

- Calls **real method** if not stubbed:
    

```java
@Spy
ArrayList<String> list = new ArrayList<>();

list.add("Ethan"); // real method executed
assertThat(list).hasSize(1);
```

- Stub specific methods if needed:
    

```java
doReturn(100).when(list).size();
assertThat(list.size()).isEqualTo(100);
```

---

## 🧩 5️⃣ Stubbing `@Spy` Methods

⚠️ Use `doReturn()`, `doThrow()`, `doAnswer()` instead of `when(...).thenReturn(...)` for spies:

```java
doReturn("mocked").when(spy).get(0); // correct
// when(spy.get(0)).thenReturn("mocked"); // may throw exception if method already called
```

- `doReturn()` avoids calling the real method when stubbing.
    

---

## 🧩 6️⃣ Verifying Interactions

Spies can be verified **like mocks**:

```java
verify(spy).add("Ethan");
verify(spy, times(2)).add(anyString());
```

You can mix **real execution** and verification in the same test.

---

## 🧩 7️⃣ Using With `@InjectMocks`

Spies can also be **injected into `@InjectMocks`**:

```java
@Spy EmailService emailService;
@Mock UserRepository repo;
@InjectMocks UserService service;
```

- `service` will get `emailService` injected as a spy, so its real methods run unless stubbed.
    

---

## 🧩 8️⃣ Partial Mocks — Real Logic + Stubbing

```java
class Calculator {
    int add(int a, int b) { return a + b; }
    int multiply(int a, int b) { return a * b; }
}

@Spy
Calculator calculator = new Calculator();

doReturn(100).when(calculator).multiply(anyInt(), anyInt());

assertThat(calculator.add(2, 3)).isEqualTo(5); // real method called
assertThat(calculator.multiply(2, 3)).isEqualTo(100); // stubbed
```

✅ Perfect for **complex objects** where you want to override some behavior but keep most logic.

---

## 🧩 9️⃣ Common Pitfalls & Fixes

|Problem|Cause|Fix|
|---|---|---|
|Real method called during stubbing|Using `when(spy.method())` instead of `doReturn()`|Use `doReturn().when(spy)`|
|NPE on spy|No real instance provided|Initialize spy (`new Class()`) or use field assignment|
|Multiple spies injection|Type mismatch in `@InjectMocks`|Ensure field types match spy type|
|Confusing real + stubbed behavior|Mixed stubs and real calls|Clearly define which methods are stubbed|

---

## 🧩 🔟 Quick Reference Examples

### Basic Spy

```java
@Spy
ArrayList<String> spyList = new ArrayList<>();

spyList.add("Ethan"); // real method
verify(spyList).add("Ethan");
```

### Stub Method

```java
doReturn(10).when(spyList).size();
assertThat(spyList.size()).isEqualTo(10);
```

### Partial Mock

```java
Calculator spyCalc = spy(new Calculator());
doReturn(100).when(spyCalc).multiply(anyInt(), anyInt());
assertThat(spyCalc.add(2, 3)).isEqualTo(5);
```

### Inject Spy

```java
@Spy EmailService emailService;
@Mock UserRepository repo;
@InjectMocks UserService service;
```

---

## 🧩 11️⃣ Summary Table

|Feature|@Spy|
|---|---|
|Purpose|Partial mock, real methods + optional stubbing|
|Default behavior|Calls real methods|
|Stubbing|`doReturn()`, `doThrow()`, `doAnswer()`|
|Verification|Works same as `@Mock`|
|Use with `@InjectMocks`|Yes|
|Common pitfall|Using `when(spy.method()).thenReturn()` can call real method|

---

With `@Spy` you now have:

- **Full real+mock control**,
    
- **Partial mocks**,
    
- **Integration with `@InjectMocks`**.
    


##### Tags : [[1 - Junit 5 🥭]]