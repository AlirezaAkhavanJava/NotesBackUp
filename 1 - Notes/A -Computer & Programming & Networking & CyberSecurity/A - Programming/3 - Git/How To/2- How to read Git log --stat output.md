`git log --stat` is basically `git log` with a small accountant attached. It shows each commit **plus a summary of which files changed and how many lines were added/removed**. Git politely counts your chaos. Humanity invented version control and then immediately needed a report card for the mess.

Example:

```bash
git log --stat
```

Output:

```
commit 8f3a21c9b5e...
Author: Alireza <email@example.com>
Date:   Thu Aug 21 14:30:00 2026

    Add database connection

 src/main/java/App.java       | 25 +++++++++++++++++++++----
 src/main/resources/db.sql    | 10 ++++++++++
 README.md                    |  5 +++--
 3 files changed, 32 insertions(+), 8 deletions(-)
```

Let's break it down.

---

### 1. Commit information

```
commit 8f3a21c9b5e...
Author: Alireza <email@example.com>
Date:   Thu Aug 21 14:30:00 2026

    Add database connection
```

This is the normal `git log` part:

- **commit** → unique SHA-1/SHA-256 identifier of the commit
    
- **Author** → who created the commit
    
- **Date** → when it was created
    
- **message** → your commit description
    

The commit hash is like a fingerprint. Two commits cannot have the same identity unless Git's entire universe breaks, and Git is usually the one thing humans made that refuses to randomly explode.

---

### 2. Changed files section

```
src/main/java/App.java       | 25 +++++++++++++++++++++----
src/main/resources/db.sql    | 10 ++++++++++
README.md                    |  5 +++--
```

Each line represents a file changed in that commit.

Format:

```
filename | number of changed lines
```

Example:

```
App.java | 25 +++++++++++++++++++++----
```

means:

- `App.java` changed
    
- Total changed lines: 25
    

The `+` and `-` symbols are a visual bar.

More `+`:

```
++++++++++
```

means more additions.

More `-`:

```
----------
```

means more deletions.

---

### 3. Final summary

At the bottom:

```
3 files changed, 32 insertions(+), 8 deletions(-)
```

Meaning:

|Part|Meaning|
|---|---|
|`3 files changed`|Three files were modified|
|`32 insertions(+)`|32 lines were added|
|`8 deletions(-)`|8 lines were removed|

Important: Git counts **lines**, not characters. Changing one huge line counts as one line. Because apparently humans decided text files should be judged by line count. A brilliant system with absolutely no weird edge cases.

---

## Reading history of one file

You can combine it with a filename:

```bash
git log --stat App.java
```

Now Git only shows commits that touched `App.java`.

---

## Difference between `--stat` and `--patch`

`--stat`:

```bash
git log --stat
```

Shows **summary**.

Example:

```
App.java | 20 +++++++++++-----
```

It does not show the actual code.

---

`--patch`:

```bash
git log -p
```

Shows the actual changes:

```diff
- int age = 20;
+ int age = 21;
```

---

## A useful combination

For programming work, this is probably the one you will use often:

```bash
git log --stat --oneline
```

Example:

```
8f3a21c Add database connection

 App.java | 25 +++++++++++++++++++++----
 db.sql   | 10 ++++++++++

5c92abc Create project structure

 App.java | 40 ++++++++++++++++++++++++++++++++
```

You get:

- short commit ID
    
- commit message
    
- changed files
    

Clean and useful. Unlike the average Git output, which sometimes looks like a medieval scroll written by a terminal goblin.

[[0 - Git 🍋‍🟩]]