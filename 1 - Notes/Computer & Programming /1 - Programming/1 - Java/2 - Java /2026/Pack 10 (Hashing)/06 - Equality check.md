![[Screenshot From 2026-10-07 10-51-16.png]]


## The mental model

Think of a library:

- **The string pool** is the reference shelf, with **one** copy of each book. Any time the code says `"Alireza"` as a literal, Java hands you that shelf copy.
- **`new String("Alireza")`** is a **photocopy**. It has the same text, but it's a separate object that lives elsewhere (on the heap).

Two questions you can ask about two books:

1. "Are these the _same physical book_?" This is `==`.
2. "Do they have the _same text_?" This is `.equals()`.

## What your code does, step by step

1. `var name = "Alireza";` is a literal, so `name` points to the **pooled** object.
2. `var nameAgain = new String("Alireza");` forces a **new** object, so `nameAgain` points to a separate copy.
3. `me.giveHashCode(name)` prints `750612248`.
4. `me.giveHashCode(new String(nameAgain))` makes a **third** object (another copy), yet prints the same `750612248`.
5. `name.equals(nameAgain)` gives `true` (same characters).
6. `name == nameAgain` gives `false` (different objects).

```
name       ──► [ pool object "Alireza" ]
nameAgain  ──► [ heap object "Alireza"  ]   (copy #1)
new String(nameAgain) ──► [ heap object "Alireza" ]   (copy #2)
```

Three objects, one shared hash code.

## Why the hash codes match

`String` **overrides** `hashCode()` and `equals()` to be **content-based**. The hash is computed from the characters (the `s[0]*31^(n-1) + ...` formula from earlier), so identical text always gives an identical number, no matter which object it comes from.

This is the contract from our first lesson in action:

> If `a.equals(b)` is true, then `a.hashCode() == b.hashCode()` must be true.

Your output proves it: `equals` is `true`, and the hashes match.

## Proving the objects really are different

Add this to your `main`:

```java
System.out.println(System.identityHashCode(name));       // e.g. 1163157884
System.out.println(System.identityHashCode(nameAgain));  // different number
System.out.println(name.hashCode() == nameAgain.hashCode()); // true
```

`System.identityHashCode()` ignores any override and returns the object's **identity** hash, which is what the default `Object.hashCode()` would give. It differs for your two strings, while the content-based `hashCode()` matches. That shows `String` made a deliberate choice to override.

## Why `==` isn't just "wrong"

`==` on objects compares **references** (memory addresses), never content. It looks like it works on strings only when the pool makes the references coincide:

```java
String a = "Alireza";
String b = "Alireza";
System.out.println(a == b);        // true  (both point to the one pooled object)

String c = new String("Alireza");
System.out.println(a == c);        // false (new forces a copy)
System.out.println(a == c.intern()); // true  (intern() returns the pooled version)
```

That is why `==` on strings is a notorious bug: it works in small tests and fails in real programs, where strings come from user input, files, or databases (all created at runtime, so **not** pooled).

## Nuances and gotchas

- **Compile-time constants are pooled, runtime results are not.**
    
    ```java
    String x = "Ali" + "reza";        // folded to "Alireza" at compile time -> pooledString p = "Ali";String y = p + "reza";            // computed at runtime -> new heap objectSystem.out.println(x == "Alireza"); // trueSystem.out.println(y == "Alireza"); // false
    ```
    
- **`new String("literal")` is almost always pointless.** That's why IntelliJ underlines it: the literal already _is_ a `String`, so you're making a redundant copy. It's useful only for experiments like yours.
- **Same hash does not mean same object.** Equal hashes only tell `HashMap` "same bucket, now check with `equals()`".
- **`String` caches its hash** after the first call, so repeated `hashCode()` calls are free. Strings are immutable, which is what makes the cache and the pool safe.
- **Practical rule:** compare objects with `.equals()` (or `Objects.equals(a, b)` when one might be `null`). Use `==` only for primitives, enums, and deliberate identity checks.
- **A side note on your code:** `static void main()` with no `String[] args` is the newer Java feature for simplified entry points, which is why your run command includes `--enable-preview`.

## Connecting back to entities

This is exactly why your `User` example earlier broke: `Object`'s default behaves like `==` (identity), while `String` overrides it to compare content. When you write `equals()`/`hashCode()` on an entity, you're doing for `User` what `String` already does for text.

## Quick recap

- `==` asks "same object?"; `.equals()` asks "same content?"
- Literals share one pooled object; `new String(...)` always creates a separate one.
- `String.hashCode()` depends only on content, so all three of your objects hash to `750612248`.
- Equal objects must have equal hashes, and your output demonstrates that.

Say **"next"** when this clicks, and we'll move on to how `HashMap` works internally (resizing, treeification, and why capacity is a power of 2). If anything here is fuzzy, ask and I'll re-explain it more simply.

[[Hashing]]