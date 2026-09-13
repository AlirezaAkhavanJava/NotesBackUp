`git diff` looks intimidating at first because Git decided humans needed a wall of symbols to understand two versions of reality. Thankfully, once you know the pattern, it becomes pretty simple.

Example:

```diff
diff --git a/main.java b/main.java
index 83a1f3a..f5c8e91 100644
--- a/main.java
+++ b/main.java
@@ -10,7 +10,8 @@ public class Main {
     public static void main(String[] args) {
-        System.out.println("Hello");
+        System.out.println("Hello World");
+        System.out.println("Git is useful");
     }
 }
```

Let's dissect it.

---

## 1. The file header

```diff
diff --git a/main.java b/main.java
```

Means:

- `a/main.java` = old version
    
- `b/main.java` = new version
    

Git is comparing:

```
before → after
```

---

## 2. The old and new files

```diff
--- a/main.java
+++ b/main.java
```

These lines tell you:

```text
--- = old file
+++ = new file
```

Do not edit these. They are just labels.

---

## 3. The chunk location

```diff
@@ -10,7 +10,8 @@
```

This is called a **hunk header**.

Breaking it down:

```
-10,7
```

means:

> In the old file, start at line 10 and show 7 lines.

```
+10,8
```

means:

> In the new file, start at line 10 and show 8 lines.

Basically Git saying:

"Hey human, the interesting crime scene is around line 10."  
Git is basically a detective that leaves confusing notes everywhere.

---

## 4. The actual changes

### Lines starting with `-`

```diff
-        System.out.println("Hello");
```

A minus means:

**This line existed before but was removed.**

Old version:

```java
System.out.println("Hello");
```

---

### Lines starting with `+`

```diff
+        System.out.println("Hello World");
+        System.out.println("Git is useful");
```

A plus means:

**This line was added.**

New version:

```java
System.out.println("Hello World");
System.out.println("Git is useful");
```

---

### Lines with no symbol

```diff
     public static void main(String[] args) {
```

These are unchanged lines. Git shows them for context.

---

## Reading a diff mentally

Think:

```
- = delete from old version
+ = add to new version
  = unchanged
```

So:

```diff
- int x = 5;
+ int x = 10;
```

means:

Before:

```java
int x = 5;
```

After:

```java
int x = 10;
```

---

## Useful commands

### See changes you made but haven't staged:

```bash
git diff
```

Meaning:

```
working directory
        |
        v
     staging area
```

---

### See changes already staged:

```bash
git diff --cached
```

Meaning:

```
staging area
        |
        v
      commit
```

---

### Compare two commits:

```bash
git diff commit1 commit2
```

Example:

```bash
git diff a1b2c3 d4e5f6
```

---

### See only filenames changed:

```bash
git diff --name-only
```

---

### Word-level diff (often easier):

```bash
git diff --word-diff
```

Example:

```diff
Hello [-world-] {+Git+}
```

---

A good workflow while learning Git:

```bash
git status
git diff
git add filename
git diff --cached
git commit -m "message"
```

That little cycle is basically Git's heartbeat. Once you understand the diff output, Git stops looking like a cursed terminal ritual and starts behaving like a very picky but useful filing cabinet.


[[0 - Git 🍋‍🟩]]