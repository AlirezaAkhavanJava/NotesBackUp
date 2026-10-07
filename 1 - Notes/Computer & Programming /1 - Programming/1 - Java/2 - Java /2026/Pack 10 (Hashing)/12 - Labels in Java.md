
# Labels in Java: `name: { ... }`

## The core intuition

Think of a **building with nested rooms**. Normally `break` means "leave the room I'm standing in." If you're in a closet inside a bedroom inside a house, one `break` only gets you out of the closet. A **label** is a **name tag on a room**, so you can shout "everybody out of the _house_!" and leave several rooms at once.

```java
house: {
    // ... nested stuff ...
    break house;   // jump out of the block named "house"
}
```

Your `name: {}` is exactly that shape: a **name**, a **colon**, then a **statement** (here a block). It is **not** a JavaScript or JSON object (`{ name: ... }`), and it isn't the ternary `a ? b : c`. In Java, `identifier :` in front of a statement is a label.

## The story

It's Tuesday, and you're in `SeatService.java` on branch `fix_bug`. Support says: _"The system books a second seat for a customer after it already found one."_ You find the code from commit `5be1c90`:

```java
boolean[][] taken = loadSeats();   // rows x columns
int bookedRow = -1, bookedCol = -1;

for (int r = 0; r < taken.length; r++) {
    for (int c = 0; c < taken[r].length; c++) {
        if (!taken[r][c]) {
            bookedRow = r;
            bookedCol = c;
            break;                 // you meant "stop searching"
        }
    }
}
System.out.println("Booked " + bookedRow + "," + bookedCol);
```

You think `break` stops the search. The **surprise** is that it only exits the **inner** loop. The outer loop moves to the next row, finds another free seat, and **overwrites** the result. So the customer is booked into the _last_ free seat found, not the first, and every extra row costs wasted work.

Now the **decision point**. You have three ways out:

1. **A flag variable** (`boolean found`) checked in both loop conditions. It works, but it's noisy.
2. **Extract a method and `return`.** Often the cleanest.
3. **A label**, to say precisely which loop to leave.

You pick the label for this quick fix:

```java
search:                                   // label on the OUTER loop
for (int r = 0; r < taken.length; r++) {
    for (int c = 0; c < taken[r].length; c++) {
        if (!taken[r][c]) {
            bookedRow = r;
            bookedCol = c;
            break search;                 // leaves BOTH loops
        }
    }
}
```

Now the first free seat wins, and you stop immediately. You then ship it. Later you'll decide whether option 2 would have been nicer, and you'll see why below.

## The formal definition

A **labeled statement** is:

```
Identifier : Statement
```

The label names the statement that follows it. You then use it in two ways:

|Form|Meaning|Allowed on|
|---|---|---|
|`break label;`|Terminate the labeled statement and continue **after** it|**Any** labeled statement (loop, block, `if`, `switch`...)|
|`continue label;`|Skip to the next iteration of the labeled loop|**Loops only** (`for`, `while`, `do`)|

There's no `goto` in Java. A label is **not** a place you can jump _to_ from anywhere. You can only jump to a label from **inside** the statement it labels.

## Examples

### 1. `break` on a labeled loop (above)

### 2. `continue` on a labeled loop

```java
rows:
for (Users[] row : table) {
    for (Users u : row) {
        if (u == null) continue rows;      // skip the REST of this row
        process(u);
    }
}
```

A plain `continue` would only skip to the next `u`. `continue rows` abandons the whole row.

### 3. `break` on a labeled block (your `name: {}` shape)

This is the lesser-known use. You can label a **plain block** and exit early from it:

```java
validation: {
    if (user == null)          break validation;
    if (user.getId() == null)  break validation;
    save(user);                // only reached if both checks passed
}
System.out.println("done");    // always runs; break lands HERE
```

`break validation;` jumps to the first statement **after** the block. Here, it acts like a structured early exit without nested `if`s. It's rare in real code, and many teams prefer an early `return` in a small method.

## Edge cases and gotchas

- **`continue` needs a loop.** `continue block;` on a labeled plain block is a compile error.
- **Scope is only inside the labeled statement.** `break search;` outside the loop fails to compile. You can't jump into a loop, only out of it.
- **Labels have their own namespace.** A label and a variable can share a name (`int search; search: for ...`), but it's confusing, so avoid it.
- **You can't reuse a label inside itself.** Nesting two statements both labeled `search:` is an error.
- **Labels don't cross method boundaries.** A `break outer;` inside a lambda or an anonymous class can't reach a label in the enclosing method.
- **`finally` still runs.** If a `break label;` leaves a `try` block, the `finally` runs on the way out.
- **Convention:** labels are usually `lowercase` or `UPPER_CASE`, and few developers use them. If you reach for one, ask whether **extracting a method** is clearer:

```java
private int[] findFreeSeat(boolean[][] taken) {
    for (int r = 0; r < taken.length; r++)
        for (int c = 0; c < taken[r].length; c++)
            if (!taken[r][c]) return new int[]{r, c};   // return exits everything
    return null;
}
```

`return` already exits every loop, with no label needed. That's usually the better design, and labels are the right tool when the surrounding logic makes extraction awkward.

## Quick recap

- A **label** is `name:` placed before a statement, giving it a name.
- `break name;` exits **that** labeled statement, even from deep inside nested loops.
- `continue name;` goes to the next iteration of that labeled **loop**.
- `name: { ... }` labels a block, so `break name;` exits it early.
- It isn't a `goto`, a JSON object, or a ternary. It's only usable from inside the statement it labels.
- Prefer extracting a method with `return` when it reads better.

Say **"next"** when this clicks and we'll continue with `HashMap` internals (resizing, treeification, and why capacity is a power of 2). If any part is fuzzy, ask and I'll explain it more simply.


[[Java]]
[[Hashing]]