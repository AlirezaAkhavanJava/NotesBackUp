

## 🧩 What is `MockSettings`

`MockSettings` is a **configuration object** you use to customize how a mock behaves in Mockito.  
It’s built using the static method `withSettings()`.

Example:

```java
Animal animal = mock(Animal.class, withSettings().defaultAnswer(RETURNS_SMART_NULLS));
```

So:

- `mock()` creates the mock.
    
- `withSettings()` lets you configure it.
    
- `.defaultAnswer(...)` defines how the mock responds when a method isn’t stubbed.
    

---

## 🧠 The idea

When you call a method on a mock and you haven’t told Mockito what to do (`when(...).thenReturn(...)`), Mockito uses the **default answer** to decide what to return.

You can customize that default with `MockSettings.defaultAnswer()`.

---

## 🧱 Built-in default answers

|Answer|Description|Example result|
|:--|:--|:--|
|`RETURNS_DEFAULTS`|Returns Java default values (`0`, `false`, `null`)|`animal.speak()` → `null`|
|`RETURNS_SMART_NULLS`|Returns “smart nulls” that fail early and tell you what call caused the `null`|helpful for debugging|
|`RETURNS_MOCKS`|Returns a mock instead of `null` for non-primitive return types|`animal.getOwner().getName()` won’t throw NPE|
|`CALLS_REAL_METHODS`|Calls the real implementation (for partial mocks)|calls the method body|
|`RETURNS_DEEP_STUBS`|Automatically mocks chained calls|`when(a.getB().getC().getName()).thenReturn("hi")` works|

---

## 🧪 Example: using `MockSettings`

```java
import static org.mockito.Mockito.*;
import org.mockito.MockSettings;

public class Example {
    public static void main(String[] args) {
        MockSettings settings = withSettings().defaultAnswer(RETURNS_SMART_NULLS);
        Animal animal = mock(Animal.class, settings);

        System.out.println(animal.speak()); // SmartNull (debug-friendly)
    }
}
```

---

## 🧠 Custom default answer

You can even define your own behavior:

```java
import org.mockito.stubbing.Answer;
import org.mockito.invocation.InvocationOnMock;

Answer<Object> printCalls = invocation -> {
    System.out.println("Called method: " + invocation.getMethod().getName());
    return null;
};

Animal animal = mock(Animal.class, withSettings().defaultAnswer(printCalls));

animal.speak(); // prints: Called method: speak
```

---

## 🧾 Summary

|Concept|Explanation|
|---|---|
|**MockSettings**|Configures how a mock behaves|
|**defaultAnswer()**|Sets what happens when unstubbed methods are called|
|**RETURNS_DEFAULTS**|Default behavior (null, 0, false)|
|**Custom Answer**|Lets you define your own return logic|


##### Tags : [[1 - Junit 5 🥭]]