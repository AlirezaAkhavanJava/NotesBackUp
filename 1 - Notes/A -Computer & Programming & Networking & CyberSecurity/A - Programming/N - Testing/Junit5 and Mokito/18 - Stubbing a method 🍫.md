In **Mockito**, a **stub** is a **fake method behavior** you define for a mock object — it tells the mock **what to return** when a certain method is called.

Think of it like this:

> “Hey mock, when someone calls this method with these arguments — return this fake value instead of doing real work.”

---

### 🔍 Example:

```java
MyService service = mock(MyService.class);

// Stubbing a method
when(service.getData()).thenReturn("Fake Data");

// Now calling it:
System.out.println(service.getData()); // prints "Fake Data"
```

---

### 🧠 Key idea:

- **Stubbing = setting fake behavior**
    
- It’s used when you don’t want to run real code (like database calls or APIs).
    
- Without stubbing, mocks return default values (e.g. `0`, `false`, or `null`).
    

---

So in short:  
👉 **A stub in Mockito = a predefined fake response for a mocked method.**

`doCallRealMethod()` in Mockito is used when you want a **mocked object** to actually **run the real method’s code** instead of the fake (stubbed) one.

---

### 🧠 When to use it:

Use `doCallRealMethod()` when:

- You mocked a class but want **some specific methods** to behave normally.
    
- You’re testing a **partial mock** (e.g. spy) or **abstract class**.
    

---

### 🧩 Example:

```java
MyService service = mock(MyService.class);

// Normally mocks do nothing and return default values
when(service.getData()).thenReturn("Fake Data");

// But we can tell Mockito to call the real method:
doCallRealMethod().when(service).calculate();

// This will execute the real `calculate()` code of MyService
service.calculate();
```

---

### 🧨 Difference:

|Command|Behavior|
|---|---|
|`when(...).thenReturn(...)`|Return fake value|
|`doNothing().when(...)`|Skip method|
|`doCallRealMethod().when(...)`|Run real method|



👉 So, use `doCallRealMethod()` when you want a **mock** to act real for a specific method — while still being fake for the others.

---

`doThrow()` in Mockito is used when you want a **mocked method to throw an exception** instead of returning a value.



### 🧩 Example:

```java
MyService service = mock(MyService.class);

// Make the mock throw an exception when doSomething() is called
doThrow(new RuntimeException("Boom!")).when(service).doSomething();

// Now this will throw the exception:
service.doSomething(); // ❌ throws RuntimeException: Boom!
```

---

### 🧠 When to use it:

- To **simulate errors** (e.g. network failure, database crash).
    
- To **test exception handling logic** in your code.
    

---

### 🧨 Works only for void methods:


>A mock can only throw a CHECKED exception if the real method declares it.

If the method returns something, use:

```java
when(service.getData()).thenThrow(new RuntimeException("Boom!"));
```

If it’s a `void` method, use:

```java
doThrow(new RuntimeException("Boom!")).when(service).clearCache();
```

---

👉 **Summary:**  
`doThrow()` = “When this void method is called, pretend something went wrong and throw this exception.”


#### Tags : [[1 - Junit 5 🥭]]