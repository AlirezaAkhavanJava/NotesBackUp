`git log -p` is one of the best commands for understanding **what actually changed in each commit**.

Think of it as:

```bash
git log -p
```

= **"Show me the commit history AND the exact changes introduced by every commit."**

---

## 1. Basic structure

You'll see something like:

```text
commit a1b2c3d4...
Author: Ethan <ethan@example.com>
Date:   Sat Aug 30 15:30:00 2026 +0330

    Add login validation

diff --git a/Login.java b/Login.java
index 1234567..89abcde 100644
--- a/Login.java
+++ b/Login.java
@@ -10,3 +10,5 @@
     String username = input.nextLine();
+    if (username.isEmpty()) {
+        return;
+    }
```

Read it **from top to bottom**.

---

# 2. `commit`

```text
commit a1b2c3d4...
```

This is the **commit object's ID**.

Git identifies the commit using its SHA-1/SHA-256 hash.

You can do:

```bash
git show a1b2c3d4
```

to inspect that particular commit.

---

# 3. `Author`

```text
Author: Ethan <ethan@example.com>
```

Who created the commit.

Then:

```text
Date: Sat Aug 30 ...
```

When the commit was created.

---

# 4. Commit message

```text
Add login validation
```

This tells you **why the commit was made**.

It's basically the human-readable label for the commit.

---

# 5. The important part: `diff`

```text
diff --git a/Login.java b/Login.java
```

This says:

> "Here is the difference between the old version and the new version of `Login.java`."

The:

```text
a/Login.java
```

means the **old version**.

```text
b/Login.java
```

means the **new version**.

The `a/` and `b/` aren't necessarily actual directories in your project.

---

# 6. `---` and `+++`

You'll see:

```text
--- a/Login.java
+++ b/Login.java
```

Very important:

```text
--- = old version
+++ = new version
```

So:

```text
--- a/Login.java
+++ b/Login.java
```

means:

> Compare the old `Login.java` with the new `Login.java`.

---

# 7. The actual changes

This is the part you really care about.

```diff
 String username = input.nextLine();
+if (username.isEmpty()) {
+    return;
+}
```

The symbols tell you what happened:

```text
+  added
-  removed
  unchanged
```

For example:

```diff
 String username = input.nextLine();
-if (username == null) {
-    return;
-}
+if (username.isEmpty()) {
+    return;
+}
```

Means:

**Before:**

```java
String username = input.nextLine();

if (username == null) {
    return;
}
```

**After:**

```java
String username = input.nextLine();

if (username.isEmpty()) {
    return;
}
```

So Git isn't showing you the entire file.

It's showing you the **difference between two snapshots**.

---

# 8. The weird `@@`

You'll encounter something like:

```text
@@ -10,7 +10,9 @@
```

This is called a **hunk header**.

You can roughly read it as:

```text
old file: start at line 10, 7 lines
new file: start at line 10, 9 lines
```

So:

```text
-10,7
```

refers to the old version.

And:

```text
+10,9
```

refers to the new version.

You don't usually need to memorize this immediately. The important idea is:

> `@@` tells Git where this particular change occurs in the files.

---

# 9. Example: understand the whole thing

Suppose you run:

```bash
git log -p
```

and get:

```diff
commit abc123
Author: Ethan
Date:   Sat Aug 30

    Add age validation

diff --git a/User.java b/User.java
index 1234567..9876543 100644
--- a/User.java
+++ b/User.java
@@ -5,6 +5,9 @@
 public class User {
     private String name;
     private int age;
 
+    public boolean isAdult() {
+        return age >= 18;
+    }
+
 }
```

Read it like this:

### Commit

```text
abc123
```

Git commit ID.

### Message

```text
Add age validation
```

Human explanation of the commit.

### File

```text
User.java
```

was changed.

### Old version

```text
private String name;
private int age;
```

### New version

These lines were added:

```diff
+public boolean isAdult() {
+    return age >= 18;
+}
```

Therefore:

> This commit added an `isAdult()` method to `User.java`.

---

# 10. Why this is especially important with Git objects

This connects directly to what you were learning about **commits, trees and blobs**.

When you run:

```bash
git log -p
```

Git is essentially showing you:

```text
Commit A
   ↓
Tree A
   ↓
files/blobs

        compared with

Commit B
   ↓
Tree B
   ↓
files/blobs
```

and generating the **diff** between those snapshots.

For example:

```text
Commit 1
   |
   v
Tree 1
   |
   +-- file.txt -> blob AAA

Commit 2
   |
   v
Tree 2
   |
   +-- file.txt -> blob BBB
```

If `AAA` and `BBB` contain different contents, Git can show:

```diff
-old content
+new content
```

That's basically what you're looking at in `git log -p`.

---

## One mental model to keep

When reading `git log -p`, think:

```text
COMMIT
  ↓
What happened?

DIFF
  ↓
Which files changed?

--- 
  ↓
OLD version

+++
  ↓
NEW version

- line
  ↓
removed

+ line
  ↓
added

  line
  ↓
unchanged context
```

And one very useful command while learning:

```bash
git log --oneline -p
```

This gives you the compact commit history **plus the patches**, making it much easier to follow commit-by-commit.

[[0 - Git 🍋‍🟩]]