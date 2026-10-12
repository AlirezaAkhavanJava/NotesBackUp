
`verify()` in **Mockito** is used to **check that a mocked method was called** — and optionally **how many times**, **with what arguments**, and **in what order**.

Let’s go through it step-by-step 👇

---

### 🧩 Basic Syntax

```java
verify(mockObject).methodName();
```

✅ Checks that `methodName()` was called **once** on the mock.  
If it wasn’t, the test **fails**.

---

### 🧠 Example

```java
List<String> mockList = mock(List.class);

// Act
mockList.add("Ethan");

// Assert
verify(mockList).add("Ethan"); // ✅ passes
verify(mockList).clear();      // ❌ fails — never called
```

---

### 🔁 Times Verification

You can specify **how many times** a method should be called:

```java
verify(mockList, times(2)).add("Ethan");
verify(mockList, never()).clear();
verify(mockList, atLeastOnce()).add("Ethan");
verify(mockList, atMost(3)).add("Ethan");
```

---

### 🎯 Argument Verification

You can verify calls with **specific arguments** or use **matchers**:

```java
verify(mockList).add(anyString());
verify(mockList).add(eq("Ethan"));
```

Or capture what was passed:

```java
ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
verify(mockList).add(captor.capture());
assertEquals("Ethan", captor.getValue());
```

---

### ⏱️ Order Verification

Check if methods were called **in a specific order**:

```java
InOrder inOrder = inOrder(mockList);
inOrder.verify(mockList).add("First");
inOrder.verify(mockList).add("Second");
```

---

### 🚫 No Interaction Check

To ensure **no other calls** happened:

```java
verifyNoMoreInteractions(mockList);
verifyNoInteractions(anotherMock);
```

---

### 🧩 Summary Table

|Verification Type|Example|Meaning|
|---|---|---|
|Basic|`verify(mock).method()`|Called once|
|Count|`verify(mock, times(3)).method()`|Called 3 times|
|Never|`verify(mock, never()).method()`|Not called|
|Argument|`verify(mock).method(eq("x"))`|Called with “x”|
|Order|`inOrder(...).verify(...)`|Enforces call order|
|No interactions|`verifyNoMoreInteractions(mock)`|No extra calls|



##### Tags : [[1 - Junit 5 🥭]]