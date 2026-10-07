

## The core intuition

Picture the **"same person?" check at airport security** again. The three rules from last time (reflexive, symmetric, transitive) were about the _logic_ of the check. These two are about its **reliability**.

- **Consistent:** the officer gives the **same verdict every time** you show the same two documents. They can't say "match" at 9am and "no match" at 9:05 while nothing has changed.
- **Non-null:** if someone walks up with **no document at all**, the officer says "no match" and moves on. They don't faint (a crash) and they don't wave the person through.

## The story

It's Friday, 4:50 pm, and you're about to cut the release from `main`. A bug report comes in: _"Some bookings disappear from the active list and can never be removed."_ No exception, and no pattern. You open `UserService.java` and find this, added in commit `9d2e7b4`:

```java
Set<Users> active = new HashSet<>();

Users u = new Users(7, 1);          // id=7, day=1
active.add(u);

u.setDay(2);                        // "reschedule", someone added a setter

active.contains(u);                 // false  <-- it's literally in there
active.size();                      // 1
active.remove(u);                   // false  <-- can't be removed
```

The object is in the set but invisible, a ghost. You re-read your `equals()` and `hashCode()`. They are correct. So what's broken?

Here's the **surprise**: `u.equals(u)` is still `true`, and nothing in your methods is wrong. The _input_ to those methods changed after the object was stored. `HashSet` filed `u` into a bucket using the hash of `day=1`. After `setDay(2)`, the hash points to a different bucket, so the lookup goes to the wrong shelf and never finds it.

You then try to fix it with a dirty trick, and the **decision point** arrives. You could:

1. Remove the object from the set before changing `day`, then re-add it.
2. Make the fields `final` so the problem can't happen.
3. Stop using the whole `Users` object as the set element and use a stable key instead.

You choose option 2 where possible (immutable `Users`, change = create a new object) and option 1 where it isn't. But while reading the diff you spot a second landmine in the same commit.

```java
@Override
public boolean equals(Object o) {
    if (getClass() != o.getClass()) return false;   // someone deleted the null check
    Users users = (Users) o;
    return Objects.equals(id, users.id) && day == users.day;
}
```

In testing, it never crashes, so it sat there. Then in production:

```java
List<Users> waitlist = new ArrayList<>();
waitlist.add(null);                  // a missing row got loaded as null
waitlist.contains(new Users(7, 1));  // NullPointerException
```

`ArrayList.contains(x)` calls `x.equals(element)` on every element, including the `null` one. So your `equals(null)` runs, hits `o.getClass()` on a null reference, and throws. Your code never called `equals(null)` itself, but a collection did.

## The formal definitions

For non-null references `x` and `y`:

|Rule|Definition|In plain words|
|---|---|---|
|**Consistent**|Repeated calls to `x.equals(y)` return the same result, **provided nothing used in the comparison was modified**|Same inputs, same verdict|
|**Non-null**|`x.equals(null)` returns `false`|Never throws, never true|

## Consistency in depth

### A subtle point: your ghost-object bug is _not_ a consistency violation

Look at the precise wording: _"provided no information used in equals comparisons is modified."_ When `day` changed from 1 to 2, the inputs changed, so a different answer is allowed. `equals()` was honest. The thing that broke was **`HashSet`'s assumption** that the hash of a stored object never changes.

So there are two different failures with similar symptoms:

|Failure|Who is at fault|
|---|---|
|**Mutating a key after storing it**|The caller, who broke the unwritten rule "keys are immutable while stored"|
|**A non-deterministic `equals()`**|The author of `equals()`, who broke the contract itself|

### What a truly inconsistent `equals()` looks like

It depends on something that changes without the object changing:

```java
// BAD: result depends on the clock
public boolean equals(Object o) {
    ...
    return id.equals(u.id) && LocalDate.now().isBefore(expiry);
}

// BAD: result depends on a database or network call
public boolean equals(Object o) {
    ...
    return repository.findById(id).isActive();   // may change between calls
}

// BAD in JPA: touching a lazy relationship
return Objects.equals(orders, u.orders);   // LazyInitializationException outside a session,
                                           // or an extra query inside one
```

A famous real example is `java.net.URL.equals()`, which historically resolved host names over the network. Two URLs could be equal or not depending on DNS. This is why people are told to use `URI` instead.

### Consistency applies to `hashCode()` too

`hashCode()` must return the same value for the lifetime of a **single run**, as long as the fields used haven't changed. Between runs it may differ. This is why you should never persist `hashCode()` values or rely on `HashMap` iteration order.

### The fix pattern

- Compare only **plain fields of the object itself**, never time, randomness, I/O or lazy collections.
- Keep key fields `final`, or treat the object as frozen once it's in a collection.
- If a key must change, **remove it, change it, re-add it**.

## Non-null in depth

### Why it's required

`null` can reach your `equals()` from places you don't control: list elements, map lookups, `Objects.equals(a, b)`, a repository returning `null`, a test comparing against an unset field. The contract says: **be total**. For any input, return `true` or `false`, never crash.

Note the asymmetry:

```java
Users x = null;
x.equals(y);                  // NPE, before equals() even runs (no object to call it on)
Objects.equals(x, y);         // safe: handles x == null for you
```

The contract only promises safety for **non-null `x`** receiving a null **argument**. A null _receiver_ is the caller's problem, which is why `Objects.equals(a, b)` exists.

### Three correct ways to write the guard

```java
// 1. Explicit (what IntelliJ generated for you)
if (o == null || getClass() != o.getClass()) return false;

// 2. instanceof: null-safe by definition
if (!(o instanceof Users users)) return false;   // null instanceof X is always false

// 3. Same-object shortcut + the above
if (this == o) return true;
```

`instanceof` returns `false` for `null`, so it quietly gives you the null check for free. That's why the JPA pattern from earlier used it.

### The other half: null fields

Non-null of the _argument_ is different from null _fields inside it_. Your `id` can be `null` (an unsaved entity), so a plain `id.equals(users.id)` would throw an NPE. That's why IntelliJ used `Objects.equals(id, users.id)` and `Objects.hashCode(id)`. Together they make the **whole class** null-tolerant: null argument, null fields, null everything.

## Quick recap

- **Consistent:** repeated `equals()` calls give the same answer as long as the compared fields haven't changed. Never base it on time, randomness, I/O or lazy loading.
- Mutating a stored key isn't an `equals()` violation, but it **breaks hash-based collections**. Make keys immutable, or remove, change, then re-add.
- **Non-null:** `x.equals(null)` must return `false`, never throw. Use `o == null ||`, or `instanceof`, which is null-safe.
- Collections pass `null` to your `equals()` on your behalf, so a missing check shows up as a production-only NPE.
- Use `Objects.equals` and `Objects.hashCode` so null **fields** are handled too.




[[Hashing]]