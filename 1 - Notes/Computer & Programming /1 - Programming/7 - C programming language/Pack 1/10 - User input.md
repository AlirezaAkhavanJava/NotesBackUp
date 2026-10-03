
# Getting User Input in C

C does not have a single universal `input()` function like Python. User input is normally obtained from **standard input (`stdin`)**, using functions such as `scanf()`, `fgets()`, and lower-level I/O functions.

The important idea is:

```text
Keyboard
   │
   ▼
stdin
   │
   ▼
C input function
   │
   ▼
Your variable
```

---

## 1. `scanf()` — formatted input

The simplest example:

```c
#include <stdio.h>

int main(void)
{
    int age;

    printf("Enter your age: ");
    scanf("%d", &age);

    printf("You are %d years old.\n", age);

    return 0;
}
```

If you enter:

```text
25
```

then:

```text
age
 ↓
25
```

### Why `&age`?

This is critical.

`scanf()` needs the **address of the variable** so that it can write the user's input into that memory.

```c
scanf("%d", &age);
```

Think:

```text
          address
             │
             ▼
        ┌─────────┐
age ───►│   25    │
        └─────────┘
```

`&age` means:

> Give me the memory address of `age`.

---

# 2. Reading different data types

The format specifier tells `scanf()` what type of input to expect.

### Integer

```c
int age;

scanf("%d", &age);
```

### `float`

```c
float temperature;

scanf("%f", &temperature);
```

### `double`

```c
double price;

scanf("%lf", &price);
```

### Character

```c
char grade;

scanf(" %c", &grade);
```

Notice the space before `%c`:

```c
" %c"
```

That tells `scanf()` to skip leading whitespace such as `'\n'`.

---

# 3. Reading a string

You can use:

```c
char name[50];

scanf("%49s", name);
```

Notice something important:

```c
scanf("%49s", name);
```

not:

```c
scanf("%49s", &name);   // ❌
```

For an array:

```c
char name[50];
```

`name` normally converts to a pointer to its first element when passed to a function.

So:

```text
name
 │
 ▼
┌───┬───┬───┬───┬─────┐
│ A │ l │ i │...│ \0  │
└───┴───┴───┴───┴─────┘
 ▲
 │
char *
```

---

# 4. The problem with `%s`

Suppose:

```c
char name[50];

scanf("%49s", name);
```

and the user enters:

```text
Alireza
```

It works.

But `%s` stops reading at whitespace.

So:

```text
Alireza Akhavan
```

produces only:

```text
Alireza
```

because the space terminates the `%s` input.

---

# 5. `fgets()` — usually better for strings

For reading a line of text, use:

```c
char name[100];

printf("Enter your name: ");
fgets(name, sizeof name, stdin);
```

Now:

```text
Alireza Akhavan
```

can be read as one input line.

`fgets()` is particularly useful because you explicitly provide the size of the destination buffer:

```c
fgets(name, sizeof name, stdin);
```

Conceptually:

```text
keyboard
   │
   ▼
stdin
   │
   ▼
fgets()
   │
   ▼
┌───────────────────────┐
│ A l i r e z a ... \0 │
└───────────────────────┘
         name[100]
```

---

# 6. `fgets()` can keep the newline

If the user enters:

```text
Alireza↵
```

`fgets()` may store:

```text
'A' 'l' 'i' 'r' 'e' 'z' 'a' '\n' '\0'
```

You can remove the newline:

```c
#include <stdio.h>
#include <string.h>

int main(void)
{
    char name[100];

    printf("Enter your name: ");
    fgets(name, sizeof name, stdin);

    name[strcspn(name, "\n")] = '\0';

    printf("Hello, %s!\n", name);

    return 0;
}
```

---

# 7. Always consider input failure

This:

```c
scanf("%d", &age);
```

doesn't guarantee that the user actually entered an integer.

You can check its return value:

```c
if (scanf("%d", &age) == 1) {
    printf("Age: %d\n", age);
} else {
    printf("Invalid input.\n");
}
```

`scanf()` returns the number of successfully assigned values.

For example:

```c
scanf("%d %f", &age, &temperature);
```

could return:

```text
2 → both succeeded
1 → only one succeeded
0 → neither succeeded
EOF → input stream ended/error
```

---

# 8. `stdin`

This is the deeper model.

C programs normally have three standard streams:

```text
stdin   → standard input
stdout  → standard output
stderr  → standard error
```

For a terminal program:

```text
Keyboard
   │
   ▼
 stdin
   │
   ▼
 your program
   │
   ├──────► stdout ──────► terminal
   │
   └──────► stderr ──────► terminal
```

That's why:

```c
fgets(..., stdin);
```

explicitly says:

> Read this data from the standard input stream.

---

# 9. `scanf()` vs `fgets()`

A useful rule:

|Function|Good for|
|---|---|
|`scanf()`|Formatted numeric/simple input|
|`fgets()`|Reading an entire line|
|`getchar()`|Reading one character|
|`fgetc()`|Reading one character from a stream|

For serious C programs, especially when dealing with user-controlled input, **`fgets()` + explicit parsing/validation** is often easier to control than relying heavily on `scanf()`.

For example, a robust approach is:

```text
stdin
  ↓
fgets()
  ↓
character buffer
  ↓
parse
  ↓
validate
  ↓
typed value
```

rather than:

```text
stdin
  ↓
scanf()
  ↓
hope input matches
```

---

## The key connection to what you just learned

You learned that C has **data types** and that a string is a **null-terminated sequence of `char`**.

User input connects those concepts:

```text
USER
 │
 ▼
stdin
 │
 ▼
input function
 │
 ├── "%d"  ──► int
 ├── "%f"  ──► float
 ├── "%lf" ──► double
 ├── "%c"  ──► char
 └── fgets ──► char[]
                    │
                    ▼
                 string
```

And the most important C concept underneath `scanf()` is **pointers**: the input function needs an address so it can modify the object in your program's memory.


[[CS 50]]
[[C]]