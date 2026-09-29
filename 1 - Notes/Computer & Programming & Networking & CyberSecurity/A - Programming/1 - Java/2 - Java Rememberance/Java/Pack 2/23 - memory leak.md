
This is one of the best ways to understand **why Java has a Garbage Collector at all**.

The key idea is:

> A **memory leak** happens when memory is still considered reachable/usable by the program, but the program no longer actually needs it.

Java prevents a major class of memory leaks—**unreachable heap objects left allocated**—by automatically reclaiming them with the Garbage Collector. But Java **can still have memory leaks**.


[Garabse collector](https://www.youtube.com/watch?v=c32zXYAK7CI)

---

# 1. First: what is a memory leak?

A memory leak is when a program keeps consuming memory because memory that should no longer be needed is **not released/reclaimed**.

Imagine:

```text
RAM
┌─────────────────────────┐
│ Object A                │
│ Object B                │
│ Object C                │
│ Object D                │
│ ...                     │
└─────────────────────────┘
```

Your program creates objects.

Eventually:

```text
"I don't need Object B anymore."
```

If the memory occupied by B isn't reclaimed:

```text
┌─────────────────────────┐
│ Object A     USED       │
│ Object B     DEAD       │ ← memory wasted
│ Object C     USED       │
│ Object D     DEAD       │ ← memory wasted
└─────────────────────────┘
```

Do this thousands or millions of times and eventually:

```text
OutOfMemoryError
```

---

# 2. The classic C problem

C gives you direct control over memory.

You can allocate memory with:

```c
malloc()
```

and release it with:

```c
free()
```

Example:

```c
int *number = malloc(sizeof(int));

*number = 42;

free(number);
```

The lifecycle is essentially:

```text
malloc()
   ↓
memory allocated
   ↓
use memory
   ↓
free()
   ↓
memory available again
```

The programmer is responsible for `free()`.

---

# 3. The classic C memory leak

Now imagine:

```c
void doSomething() {

    int *number = malloc(sizeof(int));

    *number = 42;

}
```

When the function ends:

```text
number
  ↓
┌─────────────┐
│     42      │
└─────────────┘
```

The local variable `number` disappears.

But the allocated memory doesn't magically disappear.

You have:

```text
pointer ──X──> memory
```

The memory is now inaccessible.

But it is still allocated.

That's a **memory leak**.

You should have done:

```c
void doSomething() {

    int *number = malloc(sizeof(int));

    *number = 42;

    free(number);
}
```

---

# 4. A more dangerous C example

Imagine:

```c
void process() {

    char *buffer = malloc(1024);

    // do something

    return;
}
```

Every call allocates:

```text
1024 bytes
```

but never frees them.

Call it:

```text
process()
process()
process()
process()
...
```

You get:

```text
Call 1 → +1 KB
Call 2 → +1 KB
Call 3 → +1 KB
...
Call 1,000,000 → +1 GB
```

Eventually:

```text
malloc() → NULL
```

or the process gets killed because it exhausted available memory.

---

# 5. Why doesn't the OS just reclaim it?

This is an important distinction.

The OS knows:

> "This process owns these pages of memory."

But it generally doesn't know:

> "The programmer doesn't need this particular allocation anymore."

That's an application-level concept.

C's `malloc()` allocator gives memory to your program, and `free()` tells the allocator:

```text
"I am finished with this block."
```

The programmer has to maintain the ownership correctly.

---

# 6. Java changes the model

Java doesn't normally expose manual heap deallocation.

You write:

```java
User user = new User();
```

The JVM allocates the object on the heap.

Conceptually:

```text
Stack
┌──────────────┐
│ user ────────┼─────────────┐
└──────────────┘             │
                             ↓
                         Heap
                     ┌─────────────┐
                     │ User object │
                     └─────────────┘
```

Now:

```java
user = null;
```

The reference disappears:

```text
Stack

user ──X

                         Heap
                     ┌─────────────┐
                     │ User object │
                     └─────────────┘
```

The object is now **unreachable**.

And this is where the Garbage Collector enters.

---

# 7. Garbage Collector

The Garbage Collector's basic job is:

> Find heap objects that are no longer reachable by the application and reclaim their memory.

So:

```text
Application
     │
     │ creates objects
     ↓
    Heap
     │
     │
     ↓
Garbage Collector
     │
     │ finds unreachable objects
     ↓
reclaims memory
```

This means you don't normally write:

```java
free(user);
```

because Java doesn't have normal explicit object deallocation like C.

---

# 8. C vs Java

The fundamental difference:

### C

```text
Programmer
    ↓
malloc()
    ↓
use memory
    ↓
free()
```

You manage the lifetime.

### Java

```text
Programmer
    ↓
new
    ↓
use object
    ↓
object becomes unreachable
    ↓
GC detects it
    ↓
memory reclaimed
```

The JVM manages the reclamation.

---

# 9. But here's the important part

**Garbage Collection does NOT mean Java cannot have memory leaks.**

This is a common misconception.

Consider:

```java
static List<byte[]> cache = new ArrayList<>();
```

Then:

```java
while (true) {
    cache.add(new byte[1024 * 1024]);
}
```

Every iteration adds another 1 MB array.

The list contains references to all those arrays:

```text
cache
  │
  ├──→ byte[1 MB]
  ├──→ byte[1 MB]
  ├──→ byte[1 MB]
  ├──→ byte[1 MB]
  ├──→ byte[1 MB]
  └──→ ...
```

The GC sees:

```text
GC Root
  ↓
static cache
  ↓
List
  ↓
byte[]
```

Everything is reachable.

Therefore:

> **GC cannot collect them.**

Even if your application logically doesn't need the old objects anymore.

That's a Java memory leak.

---

# 10. This is the critical concept

Garbage Collector doesn't ask:

> "Does the programmer still want this object?"

It fundamentally works from **reachability**.

If an object is reachable:

```text
GC Root
   ↓
Object A
   ↓
Object B
   ↓
Object C
```

then B and C are reachable.

They are not garbage.

If:

```text
GC Root
   ↓
Object A

Object B
   ↓
Object C
```

B and C have no path from a GC root.

They are unreachable.

They can be reclaimed.

---

# 11. This connects directly to what we discussed earlier

You asked about **GC Roots**, and this is exactly why they're important.

The JVM starts from special roots such as:

```text
GC Roots
   │
   ├── Local variables / active stack references
   ├── Static fields
   ├── Active threads
   ├── JNI references
   └── other JVM/runtime roots
```

Then it traverses references.

For example:

```text
GC Root
   │
   ↓
UserService
   │
   ↓
User
   │
   ↓
Address
```

All three are reachable.

Therefore:

```text
UserService
User
Address
```

are considered live.

But:

```text
              GC Root
                 │
                 ↓
              Service

Heap:

              OldUser
                 │
                 ↓
              Address
```

There is no path from a root to `OldUser`.

Therefore:

```text
OldUser → unreachable
Address → unreachable
```

They become eligible for garbage collection.

---

# 12. How GC saves us from the C problem

Consider C:

```c
void foo() {
    User *user = malloc(sizeof(User));

    // use user

} // forgot free()
```

The allocation can leak.

Java:

```java
void foo() {
    User user = new User();

    // use user
}
```

After the method returns:

```text
Stack

user reference disappears
       │
       X

Heap

User object
```

Assuming nothing else references the object:

```text
GC Root
   │
   X

User object
```

It becomes unreachable.

Eventually GC can reclaim it.

So Java removes an entire category of bugs:

```text
forgot to free()
double free
use-after-free
dangling pointer
```

---

# 13. But Java trades one problem for another

C gives you:

```text
manual memory management
```

which creates problems like:

```text
memory leaks
double free
use-after-free
dangling pointers
```

Java gives you:

```text
automatic memory reclamation
```

which eliminates many of those problems.

But Java developers can create:

```text
unintentional references
```

which keep objects alive.

For example:

```java
class Service {

    private final List<User> users = new ArrayList<>();

    void add(User user) {
        users.add(user);
    }
}
```

Suppose you intended this to temporarily store users.

But you never remove them:

```text
Service
   │
   ↓
users
   │
   ├──→ User
   ├──→ User
   ├──→ User
   ├──→ User
   └──→ millions...
```

GC says:

```text
"These objects are reachable."

Therefore:

"Not my problem."
```

And that's a memory leak.

---

# 14. Common Java memory leaks

You'll encounter these a lot in backend development.

### Static collections

```java
static List<Object> objects = new ArrayList<>();
```

If you continuously add objects and never remove them:

```text
static field
    ↓
collection
    ↓
objects
```

Everything remains reachable.

---

### Unbounded caches

```java
Map<String, User> cache = new HashMap<>();
```

If the cache has no eviction policy:

```text
request
 ↓
cache.put(...)
 ↓
request
 ↓
cache.put(...)
 ↓
...
```

Memory continuously grows.

Real caching systems therefore often use policies such as:

```text
maximum size
TTL
LRU
expiration
```

---

### Listeners / callbacks

You can accidentally keep an object alive by registering it somewhere and never unregistering it.

```text
EventManager
    ↓
listener
    ↓
large object
```

The object may no longer be logically needed, but it's still reachable.

---

### ThreadLocal

Particularly important in server applications.

```java
private static final ThreadLocal<User> CURRENT_USER =
        new ThreadLocal<>();
```

If values aren't cleaned appropriately:

```java
CURRENT_USER.remove();
```

the long-lived thread can retain objects.

This matters because application-server threads are often reused.

---

# 15. Memory leak vs dangling pointer

These are related but different.

### Memory leak

Memory exists:

```text
allocated memory
      ↓
no useful reference
```

You can't use it anymore, but it remains allocated.

### Dangling pointer

The pointer still exists, but the memory it points to has already been freed.

```text
pointer
   │
   ↓
freed memory
```

Then:

```c
free(ptr);

*ptr = 42; // BAD
```

This is **use-after-free**.

Java's managed references largely prevent this class of problem because ordinary Java code doesn't manually free objects.

---

# 16. The deeper Java definition

A very useful definition for your notes:

> **A Java memory leak occurs when an application unintentionally retains references to objects that it no longer needs, making those objects reachable and therefore preventing the Garbage Collector from reclaiming them.**

Notice the key word:

**references**.

The GC isn't asking whether an object is "useful."

It's asking whether the object is **reachable** from the GC roots.

---

# 17. The mental model

Keep this model in your head:

```text
                JVM HEAP
┌───────────────────────────────────────┐
│                                       │
│   Object A ←── GC Root               │
│      │                                │
│      ↓                                │
│   Object B                            │
│      │                                │
│      ↓                                │
│   Object C                            │
│                                       │
│                                       │
│   Object X                            │
│      │                                │
│      ↓                                │
│   Object Y                            │
│                                       │
└───────────────────────────────────────┘
       ↑
       │
       GC starts here
       │
    GC Roots
```

GC follows references:

```text
Root
 ↓
A
 ↓
B
 ↓
C
```

These survive.

But:

```text
X → Y
```

with no connection to a root:

```text
X
↓
Y

(no root path)
```

can be reclaimed.

---

# 18. And this leads directly to Mark and Sweep

Which connects perfectly to what you were studying.

The classic conceptual GC algorithm:

```text
                HEAP
                  │
                  ↓
              Mark phase
                  │
        ┌─────────┴─────────┐
        ↓                   ↓
     reachable          unreachable
        │                   │
        │                   ↓
        │                 garbage
        │
        ↓
              Sweep phase
                  │
                  ↓
        reclaim garbage memory
```

So the chain we've built is:

```text
Java program
     ↓
new objects
     ↓
Heap
     ↓
objects reference other objects
     ↓
GC Roots
     ↓
reachability analysis
     ↓
Mark
     ↓
unreachable objects identified
     ↓
Sweep / reclaim
     ↓
heap space becomes available again
```

And **memory leaks in Java happen when your program accidentally keeps an object reachable**.

That's the crucial distinction:

```text
C:
    "I forgot to free it."

Java:
    "I accidentally kept a reference to it."
```

That's why understanding **references + GC Roots + reachability** is much more important for Java memory management than thinking of GC as simply "deleting unused objects."


[[Java]]