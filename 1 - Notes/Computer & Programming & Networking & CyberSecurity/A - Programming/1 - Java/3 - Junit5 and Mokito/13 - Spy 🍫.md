## 🧩 What is `spy()`?

- `spy()` creates a **partial mock** — it wraps a **real object**,  
    so real methods are called **unless** you stub (override) them.
    

👉 Think:

> A **mock** is _fake everything_.  
> A **spy** is _real object + optional overrides_.

---

## 🧠 Syntax

```java
List<String> list = new ArrayList<>();
List<String> spyList = spy(list);
```

Now `spyList` is a spy — it behaves like `list`,  
but you can verify and stub it.

---

## 💡 Example

```java
import org.junit.jupiter.api.Test;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class SpyExampleTest {

    @Test
    void testSpy() {
        // Real object
        List<String> realList = new ArrayList<>();

        // Spy wraps the real one
        List<String> spyList = spy(realList);

        // Real method call
        spyList.add("A");
        spyList.add("B");
        assertEquals(2, spyList.size());  // real behavior

        // Override (stub) one method
        doReturn(100).when(spyList).size();

        assertEquals(100, spyList.size()); // stubbed behavior

        // Verify interactions
        verify(spyList).add("A");
        verify(spyList).add("B");
    }
}
```

---

## ⚙️ Important Notes

|Behavior|`mock()`|`spy()`|
|---|---|---|
|Methods are real?|❌ No (all fake)|✅ Yes (unless stubbed)|
|Tracks method calls?|✅ Yes|✅ Yes|
|Needs real object?|❌ No|✅ Yes|
|Common use|When testing dependencies only|When you need real behavior but track calls|

---

## ⚠️ Common Trap

If you stub a spy using `when(spy.method())`, the real method runs first!  
That can cause side effects.

❌ Wrong:

```java
when(spyList.size()).thenReturn(100); // calls real size() first
```

✅ Correct:

```java
doReturn(100).when(spyList).size();
```

---

## 🐐 TL;DR

- `mock()` → fake object (nothing real).
    
- `spy()` → real object, but controllable.
    
- Use `doReturn()` instead of `when()` when stubbing spies.
    
- Great for **partial testing** or **verifying real method calls**.
---


### 🧩 Imagine this:

You have a real object:

```java
class Dog {
    void bark() { System.out.println("woof!"); }
    int getAge() { return 5; }
}
```

---

### 1. **Real Object**

```java
Dog dog = new Dog();
dog.bark();   // prints "woof!"
dog.getAge(); // returns 5
```

Everything is real. ✅

---

### 2. **Mock**

```java
Dog mockDog = mock(Dog.class);
mockDog.bark();   // does nothing ❌
when(mockDog.getAge()).thenReturn(10);
System.out.println(mockDog.getAge()); // prints 10
```

🧠 A **mock** is **fake** — none of the real methods run.  
You tell it exactly what to do.

---

### 3. **Spy**

```java
Dog spyDog = spy(new Dog());
spyDog.bark();   // prints "woof!" ✅ (real method)
System.out.println(spyDog.getAge()); // prints 5 ✅

when(spyDog.getAge()).thenReturn(100);
System.out.println(spyDog.getAge()); // prints 100 ✅ (fake now)
```

🧠 A **spy** starts as a **real object**,  
but you can **replace specific methods** with fake ones.

---

### 💬 So:

|Type|Real Methods Run?|Example|
|---|---|---|
|Real Object|Yes|`new Dog()`|
|Mock|No|`mock(Dog.class)`|
|Spy|Yes (unless you override)|`spy(new Dog())`|

---

Think of it like this:

> 🧍‍♂️Real Object → real person  
> 🎭 Mock → robot that fakes everything  
> 🕵️ Spy → real person wearing a mask — mostly real, but can fake some parts




##### Tags : [[1 - Junit 5 🥭]]