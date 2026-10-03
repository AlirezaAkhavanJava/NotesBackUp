

## 1. Core intuition

A commit message is like the **label on a moving box**: one bold headline you can read at a glance (the _subject_), and optionally a longer note taped underneath (the _body_) explaining what's inside and why.

`--oneline` is a "show me only the headline" filter. The full message is still there, just hidden. So to read it, you drop `--oneline` or ask for the message explicitly.

## 2. The fastest ways

```bash
git log -1 main                     # full message + author + date (no diff)
git log -p -1 main                  # same, plus the patch (just remove --oneline)
git show -s main                    # message only; -s (--no-patch) suppresses the diff
git log -1 --format=%B main         # ONLY the raw message, no header at all
```

Typical output of the first one:

```
commit 8d4e0b7c2a1f...
Author: Ana Silva <ana@example.com>
Date:   Fri Oct 2 14:31:07 2026 +0200

    Fix null check in TaskService

    findById called Optional.get() directly, which threw a bare
    NoSuchElementException and surfaced as a 500 in the REST layer.
    Throw TaskNotFoundException instead so the controller advice
    can map it to a 404.

    Fixes #42
```

## 3. The anatomy of a message

```
Fix null check in TaskService          ← subject (one line)
                                       ← blank line (REQUIRED separator)
findById called Optional.get() ...     ← body (free-form paragraphs)
...
                                       
Fixes #42                              ← trailer (key: value lines at the end)
Co-authored-by: Ben <ben@example.com>
```

Why the blank line matters: Git (and every tool built on it) treats everything before the first blank line as the **subject**. `--oneline`, email patches, GitHub's commit list, and `git shortlog` all show only that part. If someone writes a long message with no blank line, `--oneline` actually joins the first paragraph into one very long line.

The message answers a different question than the diff. The diff shows _what_ changed; a good body explains **why**.

## 3. Picking out exactly the part you want

`--format` (alias `--pretty=format:`) takes placeholders:

|Placeholder|Gives you|
|---|---|
|`%h` / `%H`|Short / full hash|
|`%s`|Subject only|
|`%b`|Body only|
|`%B`|Raw full message (subject + body + trailers)|
|`%an`, `%ae`|Author name, email|
|`%ad`|Author date (control with `--date=...`)|
|`%cn`, `%cd`|Committer name, date|
|`%N`|Notes attached to the commit|
|`%(trailers)`|Just the trailer lines|

```bash
git log -1 --format='%h%n%s%n%n%b' main         # hash, subject, blank line, body
git log -1 --format=%b main                     # body only
git log -1 --format='%(trailers:key=Fixes)' main # only the "Fixes: ..." trailer
git log -1 --pretty=fuller main                 # author AND committer, both with dates
```

`--pretty=fuller` is worth knowing: **author** (who wrote the change) and **committer** (who applied it) can differ, for example after a rebase, cherry-pick, or `git am`. Their dates can also differ, which explains why a commit "looks newer" than its authored date.

## 4. Why it works this way: the message is stored in the commit object

A commit isn't a diff plus a note. It's a small object with fixed fields and the message at the bottom. You can look at the raw thing:

```bash
git cat-file -p main
```

```
tree 9f2a6c1...
parent c91d5a0...
author Ana Silva <ana@example.com> 1727872267 +0200
committer Ana Silva <ana@example.com> 1727872267 +0200

Fix null check in TaskService

findById called Optional.get() directly...
```

Everything is plain text. The message is simply "everything after the first blank line." And since a commit's hash is computed from _all_ of this content, **the message is part of the commit's identity**. This is why `git commit --amend` (even just fixing a typo in the message) produces a new hash, and the old commit is orphaned. That's the same mechanism the reflog helps you recover from.

## 5. Edge cases and gotchas

- **Merge commits** have messages too (auto-generated: `Merge branch 'feature' into main`). `git log -1 main` reads them the same way, and `%P` shows both parent hashes.
- **Pager:** long output opens in `less`. Press `q` to quit, `Space` to page down, `/word` to search. Disable it with `git --no-pager log -1 main`.
- **`%b` can be empty.** Many commits have only a subject. That's normal, not an error.
- **Indentation:** `git log` indents the message by four spaces for display only. The real stored message isn't indented. `--format=%B` gives you the true raw text.
- **Encoding:** non-ASCII text (accents, emoji) can look garbled if the terminal and `i18n.logOutputEncoding` disagree. UTF-8 everywhere avoids it.
- **Comment lines:** when you _write_ a message in the editor, lines starting with `#` are stripped (Git's default comment character). They never reach the stored message.
- **Notes live separately.** `git notes` attach extra text to a commit **without changing its hash**. They don't appear in `%B`; show them with `git log --show-notes` or `%N`. Rarely used, but it's how data can be "on a commit" without being in the message.
- **Messages in the reflog are different.** In `git reflog`, the text after `HEAD@{n}:` is the **reflog's own action description** (`commit: Fix null check...`, `reset: moving to HEAD~2`). For `commit:` entries it echoes the commit's subject, but for resets and checkouts it's not a commit message at all.

## 6. Searching and processing messages

```bash
git log --grep="TaskNotFound" --oneline         # commits whose message mentions it
git log --grep="fix" -i --oneline               # case-insensitive
git log --grep="^Fixes #42" --oneline           # regex, anchored to line start
git log --oneline --no-merges                   # hide merge commits' auto-messages
git log -1 --format=%B main > msg.txt           # save a message to a file
git shortlog -s -n                              # commit counts per author
```

Compare with the pickaxe from before: `--grep` searches the **message**, while `-S`/`-G` search the **diff content**. They find different things, so use both when hunting a change.

## 7. Changing a message (for reference)

```bash
git commit --amend                  # edit the latest commit's message
git commit --amend -m "New subject" # replace it inline
git rebase -i HEAD~3                # mark commits as 'reword' to edit older ones
```

All of these **rewrite history** (new hashes), so only do this on commits you haven't pushed or shared.

## 8. Quick reference

|You want|Command|
|---|---|
|Full message with metadata|`git log -1 main`|
|Message only, raw|`git log -1 --format=%B main`|
|Subject / body separately|`%s` / `%b` in `--format`|
|Message + patch|`git log -p -1 main` (no `--oneline`)|
|The raw stored object|`git cat-file -p main`|
|Search past messages|`git log --grep="text"`|





[[Git & Github]]