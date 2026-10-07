![[Pasted image 20261007171439.png]]

## 1. Definition

**Semantic Versioning (SemVer)** is a convention for numbering software releases based on the **kind of change** introduced.

The standard format is:

```text
MAJOR.MINOR.PATCH
```

For example:

```text
2.4.7
```

means:

```text
2   .   4   .   7
│       │       │
│       │       └── PATCH
│       └────────── MINOR
└────────────────── MAJOR
```

The important idea is that **the version number communicates compatibility**.

---

# 2. Why does SemVer exist?

Imagine you publish:

```text
my-library 1.4.2
```

Someone builds their application against it.

Later you publish:

```text
my-library 1.4.3
```

The developer wants to know:

> "Can I safely upgrade?"

The version number gives them information about the change.

SemVer establishes rules:

```text
PATCH  → bug fix, no intended API break
MINOR  → new backward-compatible functionality
MAJOR  → breaking change
```

So the version itself carries information.

---

# 3. PATCH

Example:

```text
1.4.2 → 1.4.3
```

You fixed a bug without intentionally breaking the existing public API.

For example:

```java
// 1.4.2
public int calculateTotal(int price) {
    ...
}
```

You fix an internal bug:

```java
// 1.4.3
public int calculateTotal(int price) {
    // bug fixed
    ...
}
```

Existing callers should still work.

Therefore:

```text
1.4.2
   ↓
1.4.3

PATCH changed
```

---

# 4. MINOR

Example:

```text
1.4.3 → 1.5.0
```

You add functionality **without breaking existing functionality**.

Suppose you had:

```java
public User findUser(Long id)
```

Then you add:

```java
public List<User> findUsersByName(String name)
```

Existing code still works.

Therefore:

```text
1.4.3
   ↓
1.5.0

MINOR changed
PATCH reset to 0
```

The reset is important:

```text
1.4.3 → 1.5.0
```

not:

```text
1.4.3 → 1.5.4
```

---

# 5. MAJOR

This is the big one.

Suppose:

```java
// v1
public User findUser(Long id)
```

and you change it to:

```java
// v2
public Optional<User> findUser(Long id)
```

Existing code:

```java
User user = service.findUser(42L);
```

no longer compiles.

You've introduced a **breaking change**.

So:

```text
1.5.0 → 2.0.0
```

The MAJOR version changes.

---

# 6. The basic rules

Think:

```text
PATCH
x.y.Z
    ↑
bug fixes / compatible fixes


MINOR
x.Y.0
  ↑
new compatible functionality


MAJOR
X.0.0
↑
breaking changes
```

For example:

```text
1.2.3
  │
  ├── bug fix       → 1.2.4
  │
  ├── new feature   → 1.3.0
  │
  └── breaking API  → 2.0.0
```

---

# 7. Why does MINOR reset PATCH?

Because the version describes the latest level of change.

Suppose:

```text
1.2.7
```

You add a backward-compatible feature:

```text
1.3.0
```

The new minor release starts a new patch sequence.

Then you fix another bug:

```text
1.3.1
```

Then:

```text
1.3.2
```

So:

```text
1.2.7
   ↓ feature
1.3.0
   ↓ bug fix
1.3.1
   ↓ bug fix
1.3.2
```

---

# 8. MAJOR resets both

Suppose:

```text
1.8.4
```

You introduce a breaking change:

```text
2.0.0
```

Then compatible features:

```text
2.1.0
```

Bug fixes:

```text
2.1.1
2.1.2
```

So the pattern is:

```text
1.8.4
  ↓ breaking
2.0.0
  ↓ feature
2.1.0
  ↓ fix
2.1.1
```

---

# 9. SemVer + Git tags

This connects directly to what you just learned about tags.

You might have:

```text
A──B──C──D──E──F
         ↑     ↑
       v1.0.0 v1.1.0
```

Then:

```bash
git tag -a v1.0.0 -m "Release 1.0.0" D
git tag -a v1.1.0 -m "Release 1.1.0" F
```

Your Git history now has named release points.

```text
commit D → v1.0.0
commit F → v1.1.0
```

Then you release a bug fix:

```text
A──B──C──D──E──F──G
         ↑     ↑     ↑
       v1.0.0 v1.1.0 v1.1.1
```

This is why you'll frequently see:

```bash
git tag
```

produce:

```text
v1.0.0
v1.1.0
v1.1.1
v2.0.0
```

---

# 10. Pre-release versions

SemVer also supports pre-release versions.

For example:

```text
1.0.0-alpha
1.0.0-beta
1.0.0-rc.1
1.0.0
```

Typical progression:

```text
alpha
   ↓
beta
   ↓
release candidate
   ↓
stable
```

For example:

```text
2.0.0-alpha.1
2.0.0-alpha.2
2.0.0-beta.1
2.0.0-rc.1
2.0.0
```

`rc` commonly means **release candidate**.

---

# 11. Build metadata

SemVer also allows build metadata:

```text
1.2.3+build.456
```

or:

```text
1.2.3+linux.x86_64
```

The `+...` section is metadata.

It does **not** determine the normal version precedence.

---

# 12. Important: SemVer is a contract

This is the deeper point.

SemVer isn't fundamentally about:

> "How many changes did I make?"

It's about:

> **"What compatibility guarantees does this release provide?"**

For example, adding 500 lines of internal code could still be:

```text
PATCH
```

if it only fixes a bug without changing the public API.

And changing one method signature could require:

```text
MAJOR
```

if it breaks consumers.

So don't think:

```text
small change → PATCH
big change   → MAJOR
```

Think:

```text
breaking compatibility?
        │
   ┌────┴────┐
  yes        no
   │          │
MAJOR      new feature?
             │
        ┌────┴────┐
       yes       no
        │          │
      MINOR      PATCH
```

---

# 13. Your Java/Spring projects

For something like your `DoItLater` backend:

```text
v1.0.0
```

could represent the first stable API release.

Suppose you add:

```text
GET /api/v1/tasks/search
```

without breaking existing endpoints:

```text
v1.0.0 → v1.1.0
```

Fix a bug:

```text
v1.1.0 → v1.1.1
```

Then change an existing response contract in a way that breaks clients:

```text
v1.1.1 → v2.0.0
```

And Git tags give you exact snapshots:

```text
v1.0.0 → commit A
v1.1.0 → commit B
v1.1.1 → commit C
v2.0.0 → commit D
```

That's the real power of combining:

```text
Git commits
    +
Git tags
    +
Semantic Versioning
```

You get a history where you can answer:

> **Exactly what code was released, and what compatibility level did that release claim?**

### Memorize this

```text
MAJOR → breaking changes
MINOR → backward-compatible features
PATCH → backward-compatible fixes
```

And:

```text
1.4.2
│ │ │
│ │ └── PATCH
│ └──── MINOR
└────── MAJOR
```


[[Git & Github]]