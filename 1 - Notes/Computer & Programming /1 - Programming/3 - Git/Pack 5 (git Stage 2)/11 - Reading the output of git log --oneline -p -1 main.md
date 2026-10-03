


## 1. Core intuition

This command prints **two things stacked on top of each other**:

1. **The message zone:** a single line, hash plus subject. `--oneline` deliberately shows only the first line of the commit message.
2. **The patch zone:** the diff. This is **not** part of the message. It's computed from the commit's changes.

So the "message" in this output is only the one line at the very top. Everything below it is code changes.

## 2. Annotated output

```
8d4e0b7 Fix null check in TaskService            ← MESSAGE ZONE (hash + subject only)
diff --git a/src/.../TaskService.java b/src/.../TaskService.java   ← PATCH ZONE starts here
index 3f9a1c2..b71e4d0 100644
--- a/src/.../TaskService.java
+++ b/src/.../TaskService.java
@@ -42,7 +42,9 @@ public class TaskService {
     public Task findById(Long id) {
-        return taskRepository.findById(id).get();
+        return taskRepository.findById(id)
+                .orElseThrow(() -> new TaskNotFoundException(id));
     }
```

How to tell the zones apart: the message zone is the **first line**, and the patch zone begins at the first line starting with `diff --git`. Anything before that is message.

## 3. Why you may be missing part of the message

A commit message can have a **subject** (first line) and a **body** (extra paragraphs after a blank line):

```
Fix null check in TaskService          ← subject: the only part --oneline shows

findById called Optional.get() ...     ← body: hidden by --oneline
Fixes #42                              ← trailer: hidden too
```

`--oneline` is shorthand for `--pretty=oneline --abbrev-commit`, and the `oneline` format by definition prints only the subject. If the commit has a body, you won't see it with this command. If it has no body, the one line really is the whole message.

## 4. Seeing the full message _and_ the patch

Keep `-p -1 main`, and change only the format:

```bash
git log -p -1 main
```

Removing `--oneline` returns Git's default (`medium`) format, so you get the full message and the patch:

```
commit 8d4e0b7c2a1f...
Author: Ana Silva <ana@example.com>
Date:   Fri Oct 2 14:31:07 2026 +0200

    Fix null check in TaskService

    findById called Optional.get() directly, which threw a bare
    NoSuchElementException and surfaced as a 500 in the REST layer.

    Fixes #42

diff --git a/src/.../TaskService.java b/src/.../TaskService.java
...
```

Here the message is the **indented block** (Git indents it four spaces for display) between the `Date:` line and the `diff --git` line.

Other options:

```bash
git log -p -1 --pretty=fuller main            # adds committer + committer date
git log -p -1 --format='%h %s%n%n%b' main     # hash, subject, blank line, body, then the patch
git show main                                 # same idea; also handles merge commits
git show -s main                              # message only, no patch
```

## 5. If you only get the message line and no patch

If the one line prints and **nothing follows**, the latest commit on `main` is probably a **merge commit**. By default `-p` shows no diff for merges, because they have two parents and Git doesn't pick one for you. Add `-m --first-parent` to see what the merge brought into `main`:

```bash
git log --oneline -p -1 -m --first-parent main
```

## 6. How to read the message once you have it

- **Subject:** a summary of _what_ the commit does. Convention is an imperative phrase ("Fix null check", not "Fixed" or "Fixes").
- **Body:** _why_ the change was made, and context the diff can't show.
- **Trailers** (last lines, like `Fixes #42` or `Co-authored-by:`): metadata for tools, linking issues or crediting authors.
- **Message vs patch:** the message is the author's _intent_, and the patch is the _reality_. When they disagree (a message says "fix typo" but the patch rewrites logic), trust the patch and be suspicious of the commit.

## 7. Summary

|You see|It is|
|---|---|
|First line, `8d4e0b7 Fix null check...`|The commit message's **subject** (all that `--oneline` shows)|
|Lines from `diff --git` onward|The **patch**, not part of the message|
|Nothing after the first line|Likely a merge commit, or a commit with no file changes|
|Want the hidden body|Drop `--oneline`, or use `git show -s main`|



[[Git & Github]]