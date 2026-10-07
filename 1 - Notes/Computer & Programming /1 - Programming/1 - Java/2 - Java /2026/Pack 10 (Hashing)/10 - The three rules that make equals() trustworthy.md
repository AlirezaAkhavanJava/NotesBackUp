

## The core intuition

Think of a **"same person?" check at airport security**. For that check to make sense, three things must hold:

- **Reflexive:** you are always the same person as yourself.
- **Symmetric:** if the officer says "this passport matches that traveler," then "that traveler matches this passport" must also be true.
- **Transitive:** if passport A matches traveler B, and traveler B matches ID card C, then A must match C.

If any of these fail, the check stops being "sameness" and becomes noise. Math has a name for a relation that satisfies all three: an **equivalence relation**. The `equals()` contract says your `equals()` must be one. Collections like `HashSet`, `List.contains` and `distinct()` quietly assume it, so when you break one of the three, they misbehave without throwing any error.

## The story

It's Thursday afternoon. You're in `UserService.java`, and a teammate's branch `fix_bug` just landed in review. Its commit is `a3f9c21`: _"treat users on adjacent days as the same booking, fixes duplicate rows."_ They changed your `Users.equals()` from earlier:

```java
// commit a3f9c21 on fix_bug
@Override
public boolean equals(Object o) {
    if (o == null || getClass() != o.getClass()) return false;
    Users u = (Users) o;
    return Objects.equals(id, u.id) && Math.abs(day - u.day) <= 1;   // "close enough"
}
```

It seems reasonable and the tests pass. You merge into `main`. Two days later, support reports that a dashboard shows 2 bookings on Monday and 1 on Tuesday for the _same data_. You stare at the code. Nothing crashes.

You reproduce it in a scratch `main()`:

```java
Users a = new Users(7, 1);   // id=7, day=1
Users b = new Users(7, 2);   // id=7, day=2
Users c = new Users(7, 3);   // id=7, day=3

a.equals(b);  // true   (days differ by 1)
b.equals(c);  // true   (days differ by 1)
a.equals(c);  // false  (days differ by 2)  <-- surprise
```

That's the surprise. Then the dedupe loop:

```java
List<Users> unique = new ArrayList<>();
for (Users u : List.of(a, b, c)) if (!unique.contains(u)) unique.add(u);
System.out.println(unique.size());   // 2  -> [a, c]

unique.clear();
for (Users u : List.of(b, a, c)) if (!unique.contains(u)) unique.add(u);
System.out.println(unique.size());   // 1  -> [b]
```

The **same three objects** give a different answer depending on the order you process them. In the first run, `b` is skipped because it equals `a`, but `c` doesn't equal `a`, so it survives. In the second run, `b` is added first, and both `a` and `c` equal `b`, so they're skipped. Your code is now order-dependent, and order-dependent bugs only appear in production.

You've reached the **decision point**. You can keep the "close enough" rule or revert to exact comparison. You'll revert, because "close enough" can never be an equivalence relation. Matching with a tolerance fails transitivity, since small gaps chain into big ones. If the business really wants "within one day," that belongs in a separate method like `isNear(Users other)`, never in `equals()`.

Your reasoning from here is: _which rule did that break, and what would breaking the other two look like?_

## The formal definitions

For any non-null references `x`, `y`, `z`:

|Rule|Definition|In plain words|
|---|---|---|
|**Reflexive**|`x.equals(x)` is `true`|An object equals itself|
|**Symmetric**|`x.equals(y)` ⇔ `y.equals(x)`|Direction doesn't matter|
|**Transitive**|`x.equals(y)` and `y.equals(z)` ⇒ `x.equals(z)`|Equality chains|

The contract also requires **consistency** (repeated calls give the same answer if nothing changed) and **`x.equals(null)` is `false`**. Those two plus the three above are the full set.

## How each rule breaks, with real examples

### Transitivity: the story above

Any "approximately equal" or tolerance-based `equals()` breaks it. Related example: comparing `double` values with a tolerance (`Math.abs(a - b) < 0.001`) fails the same way.

### Symmetry: when you compare across types

The classic case is a wrapper that tries to be friendly with `String`:

```java
class CaseInsensitiveString {
    private final String s;
    CaseInsensitiveString(String s) { this.s = s; }

    @Override
    public boolean equals(Object o) {
        if (o instanceof CaseInsensitiveString c) return s.equalsIgnoreCase(c.s);
        if (o instanceof String str)              return s.equalsIgnoreCase(str); // "helpful"
        return false;
    }
}

CaseInsensitiveString cis = new CaseInsensitiveString("Alireza");
String plain = "alireza";

cis.equals(plain);   // true
plain.equals(cis);   // false  (String.equals only accepts Strings)
```

Because you don't control `String.equals()`, you can never make this symmetric. A `List<String>` containing `plain` answers `contains(cis)` differently than a list of `cis` answers `contains(plain)`. This is why `equals()` should compare only with its **own type**, which is what your `getClass() != o.getClass()` guard does.

Inheritance causes the same trouble: if `Users` has a subclass `PremiumUsers` that adds a field, an `instanceof`-based `equals()` in the parent says the two are equal while the child's version says they aren't. That's why the strict `getClass()` check is the safe default for plain classes.

### Reflexivity: the rarest and strangest break

It seems impossible to get wrong, but it's easy with entities. Remember the safe JPA pattern from earlier:

```java
return id != null && id.equals(other.id);   // unsaved entities never equal each other
```

Without the first line of that method, `if (this == o) return true;`, an **unsaved** entity (`id == null`) returns `false` when compared to **itself**:

```java
User u = new User();          // id is null
list.add(u);
list.contains(u);             // false!  (reflexivity broken)
```

So in that pattern, the `this == o` shortcut isn't just an optimization. I described it as optional for your plain class, which is true when `id` can't be null. For entities, it's what keeps the contract intact.

The other source is **`NaN`**. For `double` fields, `Double.NaN == Double.NaN` is `false`, so a hand-written `==` comparison breaks reflexivity. IntelliJ generates `Double.compare(a, b) == 0` for double fields for exactly this reason. For your `day` field, `==` is correct only because it's an `int` (or an enum).

## Why this matters for `hashCode()`

The commit `a3f9c21` also broke something else. Its `equals()` considered `a` and `b` equal, but `hashCode()` still used `day` exactly. That means equal objects got **different hash codes**, which violates the hashCode/equals contract from the first lesson. A `HashSet` would put `a` and `b` in different buckets and never call `equals()` on them, so the "duplicates" the teammate wanted to remove would still be there. The bug had two layers: an equivalence-relation break in `equals()` and a contract break between `equals()` and `hashCode()`.

## Quick recap

- `equals()` must be an **equivalence relation**: reflexive, symmetric and transitive (plus consistent, and `false` for `null`).
- **Transitive** breaks with "close enough" comparisons. **Symmetric** breaks when you compare across types you don't control. **Reflexive** breaks with `null` ids or `NaN`.
- Your `getClass()` check protects symmetry, `Objects.equals` protects against nulls, and exact field comparison keeps transitivity.
- Fuzzy matching belongs in a separate method, never in `equals()`.





[[Hashing]]