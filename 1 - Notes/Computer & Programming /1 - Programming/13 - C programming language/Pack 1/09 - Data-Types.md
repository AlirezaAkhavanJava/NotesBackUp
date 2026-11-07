

A **data type** tells the C compiler **what kind of value an object can store, how that value is represented, and what operations are valid for it**.

For example:

```c
int age = 25;
```

Here:

- `int` → data type
    
- `age` → identifier/object
    
- `25` → value
    

The compiler uses `int` to determine how `age` should be represented and how expressions involving `age` should behave.

---

## 1. The fundamental idea

At the machine level, memory is essentially a sequence of bytes:

```text
Memory
─────────────────────────────
...  01010101 11001010 ...
```

The CPU ultimately manipulates bits and bytes.

C gives those bytes **meaning** through types.

For example:

```c
int x = 65;
char c = 'A';
```

Both may involve the numeric value `65`, but their **types** are different:

```text
x → int
c → char
```

The type affects how the compiler interprets and operates on the object.

---

# 2. Main categories of C data types

C's types can be organized roughly like this:

```text
C Data Types
│
├── Fundamental / basic types
│   ├── char
│   ├── signed integer types
│   ├── unsigned integer types
│   ├── floating-point types
│   └── _Bool
│
├── void
│
├── Derived types
│   ├── pointer
│   ├── array
│   └── function
│
├── User-defined / compound types
│   ├── struct
│   ├── union
│   └── enum
│
└── Type aliases
    └── typedef
```

There are also newer standard types such as `_Complex` and `_Atomic`, but the above gives you the essential foundation.

---

# 3. `char`

`char` represents a character-sized integer type.

```c
char letter = 'A';
```

Important:

```c
'A'
```

is not fundamentally a string.

It is a **character constant** whose value is an integer representable by `char`.

For example, on an ASCII system:

```text
'A' → 65
```

So:

```c
char letter = 'A';
```

can be thought of as storing a numeric character code.

This is also why strings in C are based on `char` arrays:

```c
char name[] = "Alireza";
```

---

# 4. Integer types

The main integer types are:

```c
short
int
long
long long
```

Each can also have:

```c
signed
unsigned
```

variants.

For example:

```c
int age = 25;
unsigned int count = 100;
long population = 1000000L;
long long distance = 9000000000LL;
```

### Signed

A signed integer can represent negative and positive values:

```text
-10 ... -1  0  1 ... 10
```

### Unsigned

An unsigned integer represents only non-negative values:

```text
0 ... positive values
```

For example:

```c
unsigned int x = 42;
```

---

# 5. Integer size is not universally fixed

This is an important C concept.

You should **not** assume:

```text
int = 4 bytes
long = 8 bytes
```

on every C implementation.

The C standard specifies minimum ranges and relationships between types, while the actual sizes depend on the implementation and ABI.

On your typical Debian x86-64 Linux system, you will commonly see:

```text
char       1 byte
short      2 bytes
int        4 bytes
long       8 bytes
long long  8 bytes
```

You can inspect your system:

```c
#include <stdio.h>

int main(void)
{
    printf("char:      %zu\n", sizeof(char));
    printf("short:     %zu\n", sizeof(short));
    printf("int:       %zu\n", sizeof(int));
    printf("long:      %zu\n", sizeof(long));
    printf("long long: %zu\n", sizeof(long long));
}
```

`sizeof` returns the size in **bytes**.

---

# 6. Floating-point types

C provides:

```c
float
double
long double
```

Example:

```c
float temperature = 36.5f;
double pi = 3.141592653589793;
```

They represent values with fractional parts.

Conceptually:

```text
integer:
42

floating-point:
42.5
3.14159
0.001
```

`double` generally provides more precision than `float`.

---

# 7. `_Bool`

C has a boolean type:

```c
_Bool
```

Example:

```c
_Bool logged_in = 1;
```

You can also use:

```c
#include <stdbool.h>

bool logged_in = true;
```

where `bool`, `true`, and `false` are provided by `<stdbool.h>`.

Conceptually:

```text
true  → 1
false → 0
```

---

# 8. `void`

`void` means **no value / no type of value**.

One common use is a function that returns nothing:

```c
void hello(void)
{
    printf("Hello\n");
}
```

The first `void` means:

```text
function returns no value
```

The second `void` means:

```text
function accepts no arguments
```

`void` also appears with pointers:

```c
void *ptr;
```

A `void *` is a **generic object pointer** that can hold the address of an object of any object type, subject to the rules for converting and dereferencing it.

---

# 9. Arrays

An array is a derived type consisting of a fixed number of elements of another type.

```c
int numbers[5];
```

The type is:

```text
int[5]
```

Conceptually:

```text
numbers
   │
   ▼
┌────┬────┬────┬────┬────┐
│int │int │int │int │int │
└────┴────┴────┴────┴────┘
```

You can access elements:

```c
numbers[0]
numbers[1]
numbers[2]
```

A string is simply a particularly important use of an array:

```c
char name[] = "Alireza";
```

which is effectively:

```text
char[8]
```

---

# 10. Pointers

A pointer stores an address.

```c
int x = 42;
int *p = &x;
```

Here:

```text
x  → int
p  → pointer to int
```

Conceptually:

```text
x
┌───────┐
│  42   │
└───────┘
   ▲
   │
   │ address
   │
┌───────┐
│   p   │
└───────┘
```

`&` means:

> give me the address of this object

`*` when used as a unary operator means:

> access the object pointed to by this pointer

So:

```c
*p = 100;
```

changes `x`:

```text
x == 100
```

Pointers become extremely important for understanding C strings.

---

# 11. Structures

A `struct` groups multiple objects, potentially of different types.

```c
struct User {
    int id;
    char name[50];
    double balance;
};
```

Now:

```c
struct User user;
```

Conceptually:

```text
User
┌─────────────────┐
│ id              │ int
├─────────────────┤
│ name            │ char[50]
├─────────────────┤
│ balance         │ double
└─────────────────┘
```

This is similar to a class's data fields in Java, but C `struct` itself does not provide Java-style methods or encapsulation.

---

# 12. `union`

A `union` allows different members to occupy the **same storage**.

```c
union Data {
    int i;
    float f;
    char c;
};
```

Conceptually:

```text
union Data
┌────────────────────┐
│ shared memory      │
│                    │
│ int / float / char │
└────────────────────┘
```

Unlike a `struct`, the members overlap in storage.

This is useful for certain low-level programming techniques, protocols, hardware interfaces, and memory representations, but it has important rules and pitfalls.

---

# 13. `enum`

An enumeration defines named integer constants.

```c
enum State {
    OFF,
    ON
};
```

Then:

```c
enum State state = ON;
```

Conceptually:

```text
OFF → 0
ON  → 1
```

The exact underlying representation is implementation-defined, but enumeration constants have type `int`.

---

# 14. `typedef`

`typedef` creates an alias for a type.

```c
typedef unsigned long ulong;
```

Now:

```c
ulong size;
```

means the same underlying type as:

```c
unsigned long size;
```

It doesn't create a fundamentally new type.

Another common example:

```c
typedef struct {
    int x;
    int y;
} Point;
```

Then:

```c
Point p;
```

---

# 15. Type is more than "how many bytes"

This is a very important distinction.

It is tempting to think:

> "A data type tells the computer how many bytes something uses."

That's only part of the story.

A type determines things such as:

- representation and size constraints
    
- alignment requirements
    
- value range
    
- signedness
    
- how expressions are evaluated
    
- which implicit conversions occur
    
- pointer arithmetic behavior
    
- which operations are valid
    
- how the compiler interprets memory
    

For example:

```c
int x = 10;
int *p = &x;
```

When you do:

```c
p + 1
```

the pointer doesn't necessarily advance by one byte.

It advances by:

```text
sizeof(int)
```

bytes.

That's because `p` has type:

```c
int *
```

Compare:

```c
char *p;
p + 1;
```

which advances by:

```text
sizeof(char) == 1
```

byte.

This is one of the places where **types directly influence machine-level behavior**.

---

# 16. Type vs object vs value

Keep these three concepts separate.

```c
int age = 25;
```

### Type

```text
int
```

### Object

```text
age
```

`age` is an object with storage.

### Value

```text
25
```

So:

```text
TYPE          OBJECT         VALUE
────          ──────         ─────
int           age            25
```

Similarly:

```c
char name[] = "Alireza";
```

roughly:

```text
TYPE          OBJECT         VALUE
────          ──────         ─────
char[8]       name           {'A','l','i','r','e','z','a','\0'}
```

---

# 17. Declaration syntax

C's declaration syntax is particularly important.

```c
int x;
```

Read it as:

> `x` is an object of type `int`.

```c
int *p;
```

> `p` is a pointer to `int`.

```c
int a[10];
```

> `a` is an array of 10 `int`.

```c
int *a[10];
```

> `a` is an array of 10 pointers to `int`.

And:

```c
int (*p)[10];
```

> `p` is a pointer to an array of 10 `int`.

This is why understanding **C types + declarators** is essential before going deeply into pointers.

---

# The mental model

Think of C's type system as telling the compiler:

```text
                TYPE
                  │
       ┌──────────┼──────────┐
       │          │          │
   representation range   operations
       │          │          │
       ▼          ▼          ▼
    memory      values     behavior
```

For example:

```c
int x;
```

means the compiler knows:

```text
x
│
├── type: int
├── storage requirements: implementation-defined
├── value domain: integer values
├── alignment: implementation-defined
└── operations: integer arithmetic, comparisons, etc.
```

And this leads directly into one of the most important C concepts:

**C's type system is the bridge between your source code and how the compiler interprets memory.**

The next concepts worth learning in order are **object → variable → declaration → type qualifiers (`const`, `volatile`, `restrict`) → integer types → arrays → pointers → structs → type conversions**.


[[C]]
[[CS 50]]