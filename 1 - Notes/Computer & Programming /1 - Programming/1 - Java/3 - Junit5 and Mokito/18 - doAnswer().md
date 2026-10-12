
### 🔍 What it is

`doAnswer()` lets you **run custom code** when a mocked method is called — not just return a fixed value.  
It’s used when you want to **inspect the arguments** or **simulate logic** inside the mock.

---

### 🧠 Syntax

```java
doAnswer(invocation -> {
    Object arg = invocation.getArgument(0);
    System.out.println("Called with: " + arg);
    return "Hello " + arg;
}).when(mockedObject).someMethod(anyString());
```

---

### 🧩 Example

```java
List<String> list = mock(List.class);

doAnswer(invocation -> {
    String value = invocation.getArgument(0);
    System.out.println("Adding: " + value);
    return true; // must match the method's return type
}).when(list).add(anyString());

list.add("Ethan");
```

---

### ⚙️ Use it when:

- You need to **log or inspect** method calls.
    
- You want the **return value to depend on the input**.
    
- You’re mocking **void methods** or more dynamic behaviors.
    

👉 **`doAnswer()` = custom logic instead of fixed stubbing.**

---

You usually **don’t need `doAnswer()`** for normal mocking.  
You use it **only in special cases** when simple `when(...).thenReturn(...)` or `thenThrow(...)` isn’t enough.

### ⚙️ 1. When the method returns **different values based on arguments**

Example:

```java
doAnswer(invocation -> {
    int x = invocation.getArgument(0);
    return x * 2;
}).when(calculator).doubleIt(anyInt());
```

→ Dynamically computes return values.

### ⚙️ 2. When the method is **`void`** and you still want to react

Normal `when(...).thenReturn(...)` doesn’t work on `void` methods.  
Example:

```java
doAnswer(inv -> {
    System.out.println("Save called!");
    return null;
}).when(repo).save(any());
```

→ Useful for logging, side effects, or tracking calls.

### ⚙️ 3. When you need to **simulate side effects**

E.g. changing state, updating variables, etc.

```java
AtomicBoolean flag = new AtomicBoolean(false);
doAnswer(inv -> {
    flag.set(true);
    return null;
}).when(service).start();
```


### ⚙️ 4. When you want **custom verification** logic during testing

Sometimes you need to verify argument transformation or internal flow — `doAnswer` can peek inside calls.


---

✅ **In short:**  
You only need `doAnswer()` when the mock’s behavior can’t be described by simple “return this or throw that.”  
It’s for **dynamic, interactive, or void** cases — like a “custom reaction” mock.

##### Tags : [[1 - Junit 5 🥭]]