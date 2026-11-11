
`git commit --amend --no-edit` is used to **modify the previous commit without changing its commit message**.

Let's break it down.

---

## 1. Normal commit

You have:

```text
A → B → C
        ↑
       HEAD
```

You make a change:

```bash
git add UserController.java
git commit -m "Fix user endpoint"
```

Now:

```text
A → B → C → D
             ↑
            HEAD
```

Commit `D` has:

```
message: Fix user endpoint
```

---

# 2. The problem

You forgot something.

Example:

```java
@GetMapping("/users")
public List<User> getUsers() {
    return service.findAll();
}
```

You forgot the import:

```java
import java.util.List;
```

You fix it:

```bash
git add UserController.java
```

Normally you would create another commit:

```bash
git commit -m "Add missing import"
```

History becomes:

```text
A → B → C → D → E
```

But now you have a useless extra commit.

---

# 3. Use amend

Instead:

```bash
git commit --amend
```

Git takes your new staged changes and combines them with the previous commit:

Before:

```text
A → B → C → D
             ↑
            HEAD
```

After:

```text
A → B → C → D'
             ↑
            HEAD
```

Important:

`D'` is a **new commit**.

The old `D` is replaced.

The commit hash changes.

---

# 4. What does `--no-edit` do?

Without it:

```bash
git commit --amend
```

Git opens your editor:

```
# Please enter the commit message

Fix user endpoint
```

You can change:

```
Fix user endpoint
```

to:

```
Fix user endpoint validation
```

---

With:

```bash
git commit --amend --no-edit
```

Git says:

> "Keep the existing commit message."

So:

Before:

```
commit message:
Fix user endpoint
```

After:

```
commit message:
Fix user endpoint
```

Only the contents change.

---

# Example workflow

You committed:

```bash
git commit -m "Add JWT authentication"
```

Then notice a missing file:

```bash
git add SecurityConfig.java
```

Instead of:

```bash
git commit -m "Add missing SecurityConfig"
```

do:

```bash
git commit --amend --no-edit
```

Result:

Before:

```
abc123 Add JWT authentication
```

After:

```
def456 Add JWT authentication
```

The message stays the same.

---

# Common uses

## Fix last commit typo

```bash
git add .
git commit --amend --no-edit
```

---

## Add forgotten file

```bash
git add forgotten-file.java
git commit --amend --no-edit
```

---

## Change commit message

Without `--no-edit`:

```bash
git commit --amend
```

or directly:

```bash
git commit --amend -m "New message"
```

---

# Important warning

Because amend rewrites history:

Before:

```
A → B → C
```

After:

```
A → B → C'
```

`C` and `C'` are different commits.

If you already pushed:

```bash
git push origin main
```

then amend requires:

```bash
git push --force-with-lease
```

because you changed published history.

For local commits that are not pushed yet, `--amend --no-edit` is one of the safest and most useful Git commands.



[[Git & Github]]