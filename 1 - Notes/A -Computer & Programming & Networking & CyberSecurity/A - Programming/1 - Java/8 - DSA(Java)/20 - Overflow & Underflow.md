
## Stack: **Overflow & Underflow** (DSA)

### 1️⃣ Stack Overflow

**Definition:**  
👉 **Overflow happens when you try to `push()` into a full stack.**

**Condition (Array Stack):**

```java
top == size - 1
```

**Example:**

```
Stack size = 3
push(10)
push(20)
push(30)
push(40) ❌  ← OVERFLOW
```

**Code check:**

```java
if (top == arr.length - 1) {
    System.out.println("Stack Overflow");
}
```

✔ Happens mainly in **array-based stacks**  
❌ Linked list stack → no overflow (until memory ends)

---

### 2️⃣ Stack Underflow

**Definition:**  
👉 **Underflow happens when you try to `pop()` from an empty stack.**

**Condition:**

```java
top == -1
```

**Example:**

```
pop() ❌  ← UNDERFLOW (stack empty)
```

**Code check:**

```java
if (top == -1) {
    System.out.println("Stack Underflow");
}
```

✔ Happens in **both array & linked list stacks**

---

### 3️⃣ Quick Comparison

|Error|Happens When|Operation|
|---|---|---|
|Overflow|Stack is full|`push()`|
|Underflow|Stack is empty|`pop()`|

---

### 4️⃣ Visual

```
Overflow:
[10][20][30]  ← full
push(40) ❌

Underflow:
(empty)
pop() ❌
```

---

### 5️⃣ Interview Tip (Important ⚠️)

> **Overflow → push on full stack**  
> **Underflow → pop from empty stack**

Say this line and you get marks.



###### Tags : [[1 - DSA 🥭]]