
When resolving merge conflicts, `git checkout` has special tools to choose **which side of the conflict you want**.

(Modern Git also provides `git restore`, but `checkout` is still commonly seen.)

---

# The conflict situation

Imagine:

```text
        main
         |
A---B---C
     \
      D---E
          |
       feature
```

You are merging:

```bash
git merge feature
```

Conflict happens.

Git marks a file:

```java
<<<<<<< HEAD
return "User list";
=======
return "All users";
>>>>>>> feature
```

Now you have three options:

1. Keep your current branch (`HEAD`)
    
2. Keep the incoming branch (`feature`)
    
3. Manually combine both
    

---

# 1. `git checkout --ours`

## Meaning:

> Keep the version from the branch you are currently on.

Example:

You are on `main`:

```bash
git checkout --ours UserController.java
```

Result:

```java
@GetMapping
public String users() {
    return "User list";
}
```

The `feature` changes are discarded **for this file only**.

Then:

```bash
git add UserController.java
```

marks it resolved.

---

# 2. `git checkout --theirs`

## Meaning:

> Keep the version from the branch being merged in.

Example:

```bash
git checkout --theirs UserController.java
```

Result:

```java
@GetMapping
public String users() {
    return "All users";
}
```

The current branch version is discarded for this file.

Then:

```bash
git add UserController.java
```

---

# 3. See the difference

During conflict:

```bash
git diff
```

Shows:

```diff
<<<<<<< HEAD
return "User list";
=======
return "All users";
>>>>>>> feature
```

You can also compare:

### Current branch:

```bash
git show :2:UserController.java
```

### Incoming branch:

```bash
git show :3:UserController.java
```

Git stores three versions temporarily:

```
:1 = common ancestor
:2 = ours (HEAD)
:3 = theirs (incoming)
```

---

# 4. Resolve all files at once

If you want everything from your branch:

```bash
git checkout --ours .
```

Then:

```bash
git add .
```

---

If you want everything from the incoming branch:

```bash
git checkout --theirs .
```

Then:

```bash
git add .
```

---

# 5. Important: `ours` and `theirs` are relative

Example:

You are on `main`:

```bash
git checkout main
git merge feature
```

During conflict:

```
ours   = main
theirs = feature
```

But reverse it:

```bash
git checkout feature
git merge main
```

Now:

```
ours   = feature
theirs = main
```

The names are not about "correct" and "wrong".

They mean:

```
ours   = current HEAD
theirs = branch being merged
```

---

# 6. After resolving

Check:

```bash
git status
```

You should see:

```
All conflicts fixed but you are still merging.
```

Then:

```bash
git commit
```

or:

```bash
git commit --no-edit
```

to keep Git's generated merge message.

---

# Professional conflict workflow

Usually:

```bash
git merge feature

# see conflicts
git status

# inspect
git diff

# choose or edit
git checkout --ours file.java
# OR
git checkout --theirs file.java
# OR manually edit

git add file.java

# finish
git commit
```

The key idea:

```
ours   → current branch (HEAD)
theirs → branch you are bringing in
```

Not "my code" vs "their code" — it depends on **where you are standing when you run merge**.



[[Git & Github]]