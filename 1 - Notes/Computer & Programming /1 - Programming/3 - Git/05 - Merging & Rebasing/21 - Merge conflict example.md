

 A **Spring Boot controller** is a good example because the conflict becomes very obvious.

Let's simulate two developers modifying the **same lines** on different branches.

### 1. Starting point — `main`

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public String getUsers() {
        return "All users";
    }
}
```

Repository:

```text
main
 │
 └── UserController.java
```

Now create a feature branch:

```bash
git switch -c feature/user-message
```

---

## 2. Developer A changes the code

On `feature/user-message`:

```java
@GetMapping
public String getUsers() {
    return "Welcome to the user API";
}
```

Commit it:

```bash
git add .
git commit -m "Change user API message"
```

History:

```text
main
  │
  A  ← feature/user-message
```

---

## 3. Meanwhile, Developer B changes the same code

Imagine `main` receives another commit:

```java
@GetMapping
public String getUsers() {
    return "User list";
}
```

Commit:

```bash
git add .
git commit -m "Update user list response"
```

Now Git looks like:

```text
        A ← feature/user-message
       /
--- M
       \
        B ← main
```

The important thing is that **A and B both modified the same part of the same file**.

---

# 4. Try to merge

Switch to `main`:

```bash
git switch main
```

Then:

```bash
git merge feature/user-message
```

Git cannot automatically decide which version you want.

You get something like:

```text
CONFLICT (content): Merge conflict in UserController.java
Automatic merge failed; fix conflicts and then commit the result.
```

---

# 5. Look at the file

Git modifies the file and puts **conflict markers** into it:

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public String getUsers() {
<<<<<<< HEAD
        return "User list";
=======
        return "Welcome to the user API";
>>>>>>> feature/user-message
    }
}
```

This is the actual anatomy of a Git merge conflict.

```text
<<<<<<< HEAD
        return "User list";
=======
        return "Welcome to the user API";
>>>>>>> feature/user-message
```

### Meaning

```text
<<<<<<< HEAD
```

means:

> "This is what is currently checked out."

Since we're on `main`, `HEAD` means the `main` version.

---

```text
=======
```

means:

> "The two versions are separated here."

---

```text
>>>>>>> feature/user-message
```

means:

> "This is the version coming from the branch being merged."

So conceptually:

```text
              CONFLICT
                 │
       ┌─────────┴─────────┐
       │                   │
     main             feature/user-message
       │                   │
 "User list"     "Welcome to the user API"
```

Git is basically asking:

> **Which code should the final file contain?**

---

# 6. You resolve it

Suppose you decide the API should return:

```java
return "Welcome to the user API";
```

You manually remove the conflict markers:

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public String getUsers() {
        return "Welcome to the user API";
    }
}
```

Now tell Git:

```bash
git add UserController.java
```

This means:

> "I have resolved this conflict."

Then:

```bash
git commit
```

Git creates the merge commit.

```text
        A
       / \
--- M     \
       \   \
        B---C
```

Where `C` is the merge commit.

---

# The important mental model

A merge conflict is **not a Git error**.

It's Git saying:

> "I can see two different changes, but I don't know which one represents your intended final state."

Git handles the **mechanical merge**.

You handle the **semantic decision**.

For example:

```java
<<<<<<< HEAD
return "User list";
=======
return "Welcome to the user API";
>>>>>>> feature/user-message
```

Git cannot know whether you want:

```java
return "User list";
```

or:

```java
return "Welcome to the user API";
```

or perhaps:

```java
return "Welcome! Here is the user list";
```

The last one is a **human decision**.

---

## Spring Boot example where you keep BOTH changes

Imagine `main` changed:

```java
@GetMapping
public String getUsers() {
    return "User list";
}
```

while the feature branch added logging:

```java
@GetMapping
public String getUsers() {
    log.info("Fetching users");
    return "All users";
}
```

You could resolve the conflict as:

```java
@GetMapping
public String getUsers() {
    log.info("Fetching users");
    return "User list";
}
```

So conflict resolution isn't necessarily:

> "Choose ours OR theirs."

It can be:

> **Understand both changes and construct the correct final code.**

That's the important professional Git skill.


[[Git & Github]]
[[Spring Framework]]