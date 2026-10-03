


In **C, a string is a contiguous sequence of characters stored in memory and terminated by a null character `'\0'`.**

That definition contains several important ideas:

> **A C string is not a special built-in data type. It is a convention for using an array of `char` values.**

---

## 1. There is no `String` type in C

Unlike Java:

```java
String name = "Alireza";
```

C does **not** have:

```c
String name = "Alireza";   // ❌
```

Instead, C uses character storage:

```c
char name[] = "Alireza";
```

The type of `name` is:

```text
char[8]
```

because `"Alireza"` contains 7 visible characters plus the terminating `'\0'`.

---

# 2. What actually exists in memory?

Consider:

```c
char name[] = "Alireza";
```

Conceptually, memory contains:

```text
Address       Value
──────────────────────
0x1000        'A'
0x1001        'l'
0x1002        'i'
0x1003        'r'
0x1004        'e'
0x1005        'z'
0x1006        'a'
0x1007        '\0'
```

The characters occupy **contiguous memory**.

The final byte is:

```c
'\0'
```

This is called the **null character**.

It has the integer value:

```text
0
```

and should not be confused with:

```c
'0'
```

These are different:

```text
'\0'  → numeric value 0
'0'   → character zero, usually numeric value 48 in ASCII
```

---

# 3. Why does C need `'\0'`?

This is one of the most important concepts.

An array does not inherently know where its meaningful string data ends.

For example:

```c
char name[20] = "Alireza";
```

Memory could look conceptually like:

```text
A l i r e z a \0 ? ? ? ? ? ? ? ? ? ? ?
```

The array has capacity for 20 characters, but the string currently contains only 7 characters.

How does a function know that the string ends after `a`?

It searches for:

```c
'\0'
```

So:

```c
printf("%s", name);
```

essentially processes characters until it encounters:

```text
'\0'
```

Conceptually:

```text
A → l → i → r → e → z → a → \0
                                ↑
                              STOP
```

This is why C strings are called **null-terminated strings**.

---

# 4. String vs character array

This distinction is subtle and extremely important.

Every C string is stored using characters, but **not every character array is necessarily a C string**.

For example:

```c
char a[] = {'H', 'e', 'l', 'l', 'o', '\0'};
```

This is a C string.

But:

```c
char b[] = {'H', 'e', 'l', 'l', 'o'};
```

This is merely a character array.

There is no:

```c
'\0'
```

terminator.

Therefore, treating `b` as a string is incorrect.

For example:

```c
printf("%s", b);   // ❌
```

`printf` will continue reading memory looking for a zero byte. This is **undefined behavior**.

---

# 5. String literal

When you write:

```c
"Hello"
```

you are using a **string literal**.

A string literal represents the character sequence:

```text
H e l l o \0
```

So:

```c
char text[] = "Hello";
```

initializes the array approximately as:

```c
char text[] = {
    'H',
    'e',
    'l',
    'l',
    'o',
    '\0'
};
```

These are equivalent in terms of the resulting array contents:

```c
char text[] = "Hello";
```

and:

```c
char text[] = {'H', 'e', 'l', 'l', 'o', '\0'};
```

---

# 6. Why `strlen()` returns 5

Consider:

```c
char text[] = "Hello";
```

Memory:

```text
H e l l o \0
←── 5 ──→
```

Then:

```c
strlen(text)
```

returns:

```text
5
```

not `6`.

Why?

Because `strlen()` counts characters **before** the terminating null character.

Conceptually:

```c
size_t strlen(const char *str);
```

It effectively does something similar to:

```c
size_t length = 0;

while (str[length] != '\0') {
    length++;
}
```

Therefore:

```text
strlen("Hello")
     ↓
     5
```

while the amount of storage required is:

```text
5 characters + 1 null terminator = 6 bytes
```

---

# 7. Arrays and strings are closely related, but not identical

This is where C becomes interesting.

Given:

```c
char name[] = "Alireza";
```

`name` is an **array**.

Its type is:

```text
char[8]
```

But when you pass it to a function:

```c
printf("%s", name);
```

the array generally **decays to a pointer to its first element**.

Conceptually:

```text
name
 │
 ▼
┌───┬───┬───┬───┬───┬───┬───┬────┐
│ A │ l │ i │ r │ e │ z │ a │ \0 │
└───┴───┴───┴───┴───┴───┴───┴────┘
 ▲
 │
 char *
```

The pointer points to:

```c
&name[0]
```

So this:

```c
printf("%s", name);
```

essentially gives `printf` the address of the first character and tells it:

> Interpret the memory starting here as a null-terminated string.

---

# 8. `char *` and strings

You will frequently see:

```c
char *name = "Alireza";
```

This is different from:

```c
char name[] = "Alireza";
```

The first declares a **pointer**:

```c
char *name
```

The second declares an **array**:

```c
char name[8]
```

Conceptually:

### Array

```c
char name[] = "Alireza";
```

```text
name
 │
 ▼
┌───┬───┬───┬───┬───┬───┬───┬────┐
│ A │ l │ i │ r │ e │ z │ a │ \0 │
└───┴───┴───┴───┴───┴───┴───┴────┘
```

### Pointer

```c
char *name = "Alireza";
```

Conceptually:

```text
name
 │
 ▼
address ──────────► "Alireza\0"
```

The string literal has static storage duration, and attempting to modify it is **undefined behavior**:

```c
char *name = "Alireza";

name[0] = 'X';   // ❌ undefined behavior
```

Whereas:

```c
char name[] = "Alireza";

name[0] = 'X';   // ✅
```

is valid.

---

# 9. Strings are fundamentally about memory

This is the deeper C perspective.

When you write:

```c
char name[] = "Alireza";
```

C isn't creating a magical "String object."

There is simply memory:

```text
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  A  │  l  │  i  │  r  │  e  │  z  │  a  │ \0  │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

And a convention:

```text
"characters until \0"
```

That's essentially what a C string is.

---

# 10. The `char` type

A string consists of `char` objects:

```c
char c = 'A';
```

A `char` represents a single byte-sized character value.

For example, on an ASCII-based system:

```text
'A' → 65
'B' → 66
'a' → 97
'0' → 48
'\0' → 0
```

Therefore:

```c
char text[] = "ABC";
```

can be viewed numerically as:

```text
65  66  67  0
```

The exact character encoding matters, but ASCII is a useful model for understanding basic C strings.

---

# 11. Accessing individual characters

Because a C string is stored as an array, you can use indexing:

```c
char name[] = "Alireza";

printf("%c\n", name[0]);
printf("%c\n", name[1]);
printf("%c\n", name[2]);
```

Output:

```text
A
l
i
```

You can also modify it:

```c
name[0] = 'X';
```

Now:

```text
X l i r e z a \0
```

and:

```c
printf("%s\n", name);
```

produces:

```text
Xlireza
```

---

# 12. Pointer arithmetic

Because strings are sequences of contiguous `char` objects, pointers can traverse them.

```c
char *p = name;
```

Then:

```c
*p
```

is:

```text
'A'
```

and:

```c
*(p + 1)
```

is:

```text
'l'
```

and:

```c
*(p + 2)
```

is:

```text
'i'
```

Conceptually:

```text
p
│
▼
 A    l    i    r    e    z    a    \0
 ↑    ↑    ↑
p   p+1  p+2
```

This relationship between **arrays, pointers, and strings** is one of the foundations of C.

---

# 13. How string functions work

The standard library provides:

```c
#include <string.h>
```

Common functions include:

```c
strlen()
strcpy()
strncpy()
strcmp()
strncmp()
strcat()
strncat()
strchr()
strstr()
```

For example:

```c
strcmp("abc", "abc")
```

compares the character sequences.

And:

```c
strcpy(destination, source);
```

copies characters including the terminating `'\0'`.

Conceptually:

```text
source:
A l i r e z a \0
│
│ strcpy
▼
destination:
A l i r e z a \0
```

---

# 14. The dangerous part: C does not automatically protect you

Suppose:

```c
char name[5];

strcpy(name, "Alireza");
```

`"Alireza"` requires:

```text
8 bytes
```

but `name` has space for only:

```text
5 bytes
```

There isn't enough memory.

C doesn't automatically resize the array.

This can result in a **buffer overflow** and undefined behavior.

This is one of the reasons understanding C strings is extremely important for systems programming and security.

---

# 15. The mental model

When you encounter a C string, think:

```text
              C STRING
                  │
                  ▼
        contiguous char objects
                  │
                  ▼
             first byte
                  │
                  ▼
        characters in sequence
                  │
                  ▼
              '\0' terminator
                  │
                  ▼
                 STOP
```

For example:

```c
char s[] = "Hello";
```

Think:

```text
s
│
▼
┌─────┬─────┬─────┬─────┬─────┬──────┐
│ 'H' │ 'e' │ 'l' │ 'l' │ 'o' │ '\0' │
└─────┴─────┴─────┴─────┴─────┴──────┘
  0     1     2     3     4      5
```

The **string length** is:

```text
5
```

The **array size** is:

```text
6
```

because the terminator also occupies memory.

---

## The precise definition

If you want the definition at a level suitable for serious C programming:

> **A C string is a contiguous sequence of characters represented by an array of `char` (or an accessible sequence of character objects) whose contents are terminated by the first null character (`'\0'`). C itself does not define a distinct string object type; strings are represented through character arrays and pointers, with library functions operating according to the null-termination convention.**

That last distinction is fundamental:

```text
Java
String
  ↓
actual language/library abstraction

C
string
  ↓
convention
  ↓
char sequence + '\0'
```

Once you understand **`char[]` + `'\0'` + pointers + array-to-pointer decay + memory**, you've understood the foundation of strings in C.


[[C]]
[[CS 50]]