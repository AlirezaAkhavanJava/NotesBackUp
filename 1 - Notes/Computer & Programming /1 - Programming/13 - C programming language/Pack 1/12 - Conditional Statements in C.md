


A **conditional statement** allows a C program to make a decision based on whether an expression evaluates to **true or false**.

The fundamental idea is:

```text
condition
    │
    ├── true  → execute one path
    │
    └── false → execute another path
```

For example:

```c
int age = 20;

if (age >= 18) {
    printf("Adult\n");
}
```

Here:

```c
age >= 18
```

is the **condition**.

Because `20 >= 18` is true, the body executes.

---

## 1. Conditions in C are expressions

C does not have a separate `BooleanExpression` type like some languages.

An expression is treated as:

```text
0       → false
non-zero → true
```

For example:

```c
if (0) {
    printf("False\n");
}
```

doesn't execute.

But:

```c
if (42) {
    printf("True\n");
}
```

does execute.

This is a fundamental C rule.

---

# 2. `if`

The basic syntax is:

```c
if (condition) {
    // statements
}
```

Example:

```c
int temperature = 30;

if (temperature > 25) {
    printf("It is hot.\n");
}
```

Execution:

```text
temperature > 25
       │
       ▼
      30 > 25
       │
      true
       │
       ▼
"It is hot."
```

---

# 3. `if ... else`

When you need two possible paths:

```c
if (condition) {
    // true
} else {
    // false
}
```

Example:

```c
int age = 16;

if (age >= 18) {
    printf("Adult\n");
} else {
    printf("Minor\n");
}
```

Flow:

```text
          age >= 18?
          /       \
       yes         no
        │           │
        ▼           ▼
     Adult        Minor
```

---

# 4. `else if`

For multiple mutually exclusive conditions:

```c
if (condition1) {
    ...
} else if (condition2) {
    ...
} else {
    ...
}
```

Example:

```c
int score = 85;

if (score >= 90) {
    printf("A\n");
} else if (score >= 80) {
    printf("B\n");
} else if (score >= 70) {
    printf("C\n");
} else {
    printf("Fail\n");
}
```

The conditions are evaluated from **top to bottom**.

For `85`:

```text
score >= 90   → false
score >= 80   → true
                  ↓
                  B
```

Once a branch executes, the remaining branches are skipped.

---

# 5. Comparison operators

Conditions commonly use comparison operators:

|Operator|Meaning|
|---|---|
|`==`|equal|
|`!=`|not equal|
|`>`|greater than|
|`<`|less than|
|`>=`|greater than or equal|
|`<=`|less than or equal|

Example:

```c
int x = 10;

if (x == 10) {
    printf("x is 10\n");
}
```

### Important: `=` vs `==`

These are completely different:

```c
x = 10;     // assignment
x == 10;    // comparison
```

A very common C bug is accidentally writing:

```c
if (x = 10)
```

instead of:

```c
if (x == 10)
```

The first **assigns** `10` to `x` and then evaluates the resulting value (`10`, which is non-zero and therefore true).

---

# 6. Logical operators

You can combine conditions.

### AND — `&&`

Both conditions must be true:

```c
if (age >= 18 && age <= 65) {
    printf("Working-age adult\n");
}
```

Conceptually:

```text
A && B

true only when:

A = true
B = true
```

---

### OR — `||`

At least one condition must be true:

```c
if (day == 6 || day == 7) {
    printf("Weekend\n");
}
```

---

### NOT — `!`

Reverses a condition:

```c
if (!logged_in) {
    printf("Please log in.\n");
}
```

If:

```text
logged_in = true
```

then:

```text
!logged_in = false
```

---

# 7. Truth values

C's rules are worth understanding precisely.

```text
0       → false
1       → true
2       → true
-1      → true
42      → true
```

Any value other than zero is logically true.

For example:

```c
int x = -5;

if (x) {
    printf("true\n");
}
```

This executes.

---

# 8. `_Bool` and `stdbool.h`

Modern C also provides `_Bool`:

```c
_Bool logged_in = 1;
```

With:

```c
#include <stdbool.h>
```

you can use:

```c
bool logged_in = true;
```

Example:

```c
#include <stdbool.h>
#include <stdio.h>

int main(void)
{
    bool logged_in = true;

    if (logged_in) {
        printf("Welcome!\n");
    }

    return 0;
}
```

The important distinction is that **C's conditional expressions don't require a `bool` value**. Integer and pointer expressions can also be used as conditions according to C's truth-value rules.

---

# 9. Nested conditions

An `if` can contain another `if`:

```c
if (age >= 18) {
    if (has_license) {
        printf("Can drive.\n");
    }
}
```

Flow:

```text
age >= 18?
    │
   yes
    │
    ▼
has_license?
    │
   yes
    │
    ▼
Can drive
```

You can often simplify this:

```c
if (age >= 18 && has_license) {
    printf("Can drive.\n");
}
```

---

# 10. Conditional operator `?:`

C also has a compact conditional expression:

```c
condition ? value_if_true : value_if_false
```

Example:

```c
int age = 20;

const char *status = age >= 18 ? "Adult" : "Minor";
```

Think:

```text
age >= 18
    │
    ├── true  → "Adult"
    │
    └── false → "Minor"
```

Unlike `if`, `?:` is an **expression that produces a value**.

That's why this is possible:

```c
int max = a > b ? a : b;
```

Conceptually:

```text
a > b ?
  │
  ├── true  → a
  └── false → b
```

---

# 11. `switch`

When you're comparing one expression against several constant cases, C provides `switch`.

```c
int command = 2;

switch (command) {
    case 1:
        printf("Start\n");
        break;

    case 2:
        printf("Stop\n");
        break;

    case 3:
        printf("Pause\n");
        break;

    default:
        printf("Unknown command\n");
        break;
}
```

For:

```c
command = 2;
```

execution reaches:

```c
case 2:
```

and prints:

```text
Stop
```

### Why `break`?

Without `break`, execution normally continues into the following case.

For example:

```c
switch (x) {
    case 1:
        printf("One\n");

    case 2:
        printf("Two\n");
}
```

If `x == 1`, both messages can execute.

This behavior is called **fall-through**.

---

# 12. Conditional control-flow model

At a higher level:

```text
                   expression
                       │
                       ▼
                evaluate condition
                       │
                ┌──────┴──────┐
                │             │
              true          false
                │             │
                ▼             ▼
            branch A       branch B
                │             │
                └──────┬──────┘
                       │
                       ▼
                   continue
```

This is the foundation of **control flow**.

Your program isn't just executing statements sequentially:

```text
A
↓
B
↓
C
↓
D
```

A conditional introduces a decision:

```text
A
↓
condition
├── true  → B
│
└── false → C
             ↓
             D
```

---

## The core conditional tools in C

```c
if
if ... else
if ... else if ... else
switch
?:              // conditional operator
```

And the underlying concepts you should master are:

```text
comparison
    ↓
logical operators
    ↓
truth values
    ↓
if/else
    ↓
switch
    ↓
conditional operator
    ↓
control-flow analysis
```

One particularly important C concept to learn next is **truthiness, short-circuit evaluation (`&&` / `||`), and operator precedence**, because these explain many subtle conditional bugs.


[[C]]
[[CS 50]]