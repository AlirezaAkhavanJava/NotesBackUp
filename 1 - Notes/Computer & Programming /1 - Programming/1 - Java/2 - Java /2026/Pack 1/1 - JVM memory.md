


# 1. Your Java program starts on storage

Suppose you write:

```java
public class App {
    public static void main(String[] args) {
        int age = 20;
    }
}
```

The file:

```text
App.java
```

is stored on your **SSD/HDD**.

You compile it:

```bash
javac App.java
```

This creates:

```text
App.class
```

The `.class` file is still on your **SSD/HDD**.

---

# 2. When you run Java

You run:

```bash
java App
```

Now the **JVM (Java Virtual Machine)** starts.

The JVM is a program running on your computer, and it gets memory from the operating system.

Conceptually:

```text
SSD
│
├── App.class
│
└── JVM files

        │
        │ java App
        ▼

RAM
┌─────────────────────────────┐
│            JVM              │
│                             │
│  ┌───────────────────────┐  │
│  │        Stack          │  │
│  ├───────────────────────┤  │
│  │         Heap          │  │
│  ├───────────────────────┤  │
│  │   Other JVM memory    │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

So **Java's memory exists while the JVM is running**.

---

# 3. The Stack: method execution

Let's start with this:

```java
public class App {
    public static void main(String[] args) {
        int age = 20;
        System.out.println(age);
    }
}
```

When `main()` starts, Java creates a **stack frame** for it.

Think of a stack frame as a workspace for one method call:

```text
STACK

┌─────────────────────┐
│ main() stack frame  │
│                     │
│ age = 20            │
│ args = reference    │
└─────────────────────┘
```

When `main()` finishes, its stack frame disappears.

The stack follows **LIFO**:

> Last In, First Out.

For example:

```java
public static void main(String[] args) {
    methodA();
}

static void methodA() {
    methodB();
}

static void methodB() {

}
```

The calls look like:

```text
Stack

┌───────────────┐
│   methodB()   │ ← currently running
├───────────────┤
│   methodA()   │
├───────────────┤
│    main()     │
└───────────────┘
```

When `methodB()` finishes:

```text
┌───────────────┐
│   methodA()   │
├───────────────┤
│    main()     │
└───────────────┘
```

Then `methodA()` finishes:

```text
┌───────────────┐
│    main()     │
└───────────────┘
```

---

# 4. Primitive variables

Consider:

```java
int age = 20;
double height = 1.85;
boolean alive = true;
```

These are **primitive values**.

Conceptually, the current method's stack frame contains the values:

```text
STACK FRAME

age     → 20
height  → 1.85
alive   → true
```

---

# 5. Objects are different

Now:

```java
String name = new String("Ethan");
```

Here we have two things:

```text
name
```

and:

```text
new String("Ethan")
```

Conceptually:

```text
STACK                    HEAP

name ──────────────────► String object
                          ┌─────────────┐
                          │ "Ethan"     │
                          └─────────────┘
```

The variable `name` holds a **reference** that lets Java access the object.

The actual object lives on the **heap**.

---

# 6. A bigger example

```java
class Person {
    String name;
    int age;
}

public class App {
    public static void main(String[] args) {

        Person person = new Person();

        person.name = "Ethan";
        person.age = 20;
    }
}
```

Conceptually:

```text
STACK                         HEAP

main() frame

person ────────────────────► Person object
                              ┌────────────────┐
                              │ name ───────┐  │
                              │ age = 20    │  │
                              └─────────────│──┘
                                            │
                                            ▼
                                      String "Ethan"
```

So:

```java
Person person
```

is a **reference variable**, while:

```java
new Person()
```

creates an object on the **heap**.

---

# 7. Multiple variables can reference the same object

```java
Person a = new Person();
Person b = a;
```

This does **not** create two `Person` objects.

Instead:

```text
STACK

a ──────────┐
            │
b ──────────┘
            ▼

HEAP

      ┌──────────────┐
      │ Person object│
      └──────────────┘
```

Both variables point to the **same object**.

Therefore:

```java
b.age = 30;

System.out.println(a.age);
```

prints:

```text
30
```

because `a` and `b` refer to the same object.

---

# 8. What happens when an object is no longer used?

Consider:

```java
Person person = new Person();

person = null;
```

Initially:

```text
person ───────────► Person object
```

After:

```java
person = null;
```

we have:

```text
person = null


Person object
┌──────────────┐
│              │  ← no reachable reference
└──────────────┘
```

The object may now be eligible for **Garbage Collection**.

Java's **Garbage Collector (GC)** automatically reclaims memory from objects that are no longer reachable.

You usually don't manually free objects like you would in C:

```c
free(pointer);
```

In Java:

```java
Person person = new Person();
```

Later, when nothing reachable refers to that object anymore, the GC can reclaim its memory.

---

# 9. Important: every thread has its own stack

Suppose your program has:

```text
Thread 1
Thread 2
Thread 3
```

Each thread has its own stack:

```text
JVM

Thread 1 Stack        Thread 2 Stack

┌─────────────┐       ┌─────────────┐
│ methodB()   │       │ methodX()   │
├─────────────┤       ├─────────────┤
│ methodA()   │       │ methodY()   │
└─────────────┘       └─────────────┘


              Shared Heap

        ┌──────────────────┐
        │      Objects     │
        │                  │
        │   Person         │
        │   ArrayList      │
        │   String         │
        └──────────────────┘
```

So, simplified:

* **Each thread → its own stack**
* **All threads can access shared heap objects**, subject to normal Java visibility/synchronization rules.

---

# 10. The full simplified picture

When your Java program runs:

```text
                    RAM
┌──────────────────────────────────────────┐
│                   JVM                    │
│                                          │
│   Thread 1 Stack       Thread 2 Stack    │
│  ┌───────────────┐    ┌───────────────┐ │
│  │ method calls  │    │ method calls  │ │
│  │ local vars    │    │ local vars    │ │
│  │ references    │    │ references    │ │
│  └───────────────┘    └───────────────┘ │
│                                          │
│                  HEAP                    │
│         ┌────────────────────┐           │
│         │ Objects            │           │
│         │ Arrays             │           │
│         │ Class instances    │           │
│         └────────────────────┘           │
│                                          │
│       Other JVM memory areas             │
│       • class metadata                   │
│       • compiled code                    │
│       • JVM internal structures          │
└──────────────────────────────────────────┘
```

## The most important mental model

When learning Java, start with this:

```text
Method is called
       │
       ▼
A stack frame is created
       │
       ├── Primitive local values
       │
       └── References
              │
              ▼
             Heap
              │
              └── Objects / arrays
```

For example:

```java
int x = 10;
Person person = new Person();
```

Think:

```text
STACK                    HEAP

x = 10

person ───────────────► Person object
```

One subtle correction: this **stack vs heap picture is a learning model**, not a guarantee that every value or object is physically laid out exactly that way in every JVM implementation. The JVM and JIT compiler can optimize memory allocation significantly.




[[Java]]
