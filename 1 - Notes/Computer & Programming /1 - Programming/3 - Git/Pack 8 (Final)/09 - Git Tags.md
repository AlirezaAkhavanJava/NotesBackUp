

## 1. Definition

A **Git tag is a permanent-looking name attached to a specific Git object, usually a commit.**

Instead of remembering:

```text
b6c5f1b
```

you can give that commit a meaningful name:

```text
v1.0.0
```

So:

```text
v1.0.0
   │
   ▼
b6c5f1b
   │
   ▼
commit
```

The important distinction:

> **A branch is a moving reference. A tag normally identifies a specific point in history.**

---

# 2. Why do tags exist?

Imagine your history:

```text
A──B──C──D──E──F──G
```

You release version 1.0 at `D`.

Without a tag, you'd have to remember:

```text
v1.0.0 = commit D
```

Instead:

```text
A──B──C──D──E──F──G
         ↑
       v1.0.0
```

Now you can refer to that release by:

```bash
git checkout v1.0.0
```

or:

```bash
git show v1.0.0
```

or:

```bash
git diff v1.0.0 HEAD
```

Tags are therefore especially useful for:

- releases
    
- milestones
    
- production versions
    
- known stable states
    
- marking important historical commits
    

---

# 3. Branch vs tag

This is the most important distinction.

Suppose:

```text
A──B──C
      ↑
     main
```

Then you create:

```bash
git tag v1.0.0
```

Now:

```text
A──B──C
      ↑
      ├── main
      └── v1.0.0
```

Then you make another commit:

```text
A──B──C──D
      │     ↑
      │    main
      │
      └── v1.0.0
```

`main` moved.

`v1.0.0` didn't.

So:

```text
branch → intended to move
tag    → intended to stay at that historical point
```

Technically, Git can move a tag too, but that is generally avoided because it destroys the meaning of the tag as a stable reference.

---

# 4. Creating a tag

First find your commits:

```bash
git log --oneline
```

Suppose:

```text
b6c5f1b O : I hate the left party
a9b350f N : Revert M
f3450b2 M : My dog has cancer
```

To tag the current commit:

```bash
git tag v1.0.0
```

Now:

```text
b6c5f1b
   ↑
 v1.0.0
```

---

# 5. Tagging an older commit

You don't have to be checked out at the commit.

```bash
git tag v0.9.0 f3450b2
```

Now:

```text
...──L──M──N──O
      ↑
   v0.9.0
```

You simply tell Git:

```text
tag name + commit
```

---

# 6. Listing tags

```bash
git tag
```

Example:

```text
v0.1.0
v0.2.0
v1.0.0
v1.1.0
```

For more information:

```bash
git show v1.0.0
```

You'll see the commit the tag refers to and its metadata.

---

# 7. Lightweight vs annotated tags

Git has **two important kinds of tags**.

## Lightweight tag

```bash
git tag v1.0.0
```

This is basically:

```text
v1.0.0
   ↓
commit
```

It's a simple reference.

Good for:

- temporary markers
    
- local development
    
- simple internal references
    

---

## Annotated tag

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
```

This creates a proper **tag object** containing metadata such as:

```text
tag name
tagger
date
message
target object
```

Conceptually:

```text
v1.0.0
   │
   ▼
Tag Object
   │
   ├── name
   ├── tagger
   ├── date
   ├── message
   │
   ▼
Commit
```

For actual software releases, **annotated tags are generally the better choice**.

---

# 8. Why does the tag object matter?

Suppose you have:

```bash
git tag -a v1.0.0 -m "First production release"
```

Then:

```bash
git show v1.0.0
```

can show information about the tag itself:

```text
tag v1.0.0
Tagger: ...
Date: ...

First production release

commit b6c5f1b
...
```

A lightweight tag doesn't have that separate tag object.

---

# 9. Checking out a tag

You can do:

```bash
git switch --detach v1.0.0
```

or older-style:

```bash
git checkout v1.0.0
```

You'll be at the exact commit represented by the tag.

But notice:

```text
HEAD
 ↓
v1.0.0
 ↓
commit
```

You're **not on a branch**.

Git will usually tell you:

```text
HEAD is now at ...
```

This is called **detached HEAD**.

If you want to make new work starting from the tag:

```bash
git switch -c hotfix-v1 v1.0.0
```

Now:

```text
             ┌── hotfix-v1
             │
A──B──C──────D
             ↑
          v1.0.0
```

Actually, more precisely:

```text
             ┌── hotfix-v1
             │
A──B──C──D
         ↑
      v1.0.0
```

Both the tag and branch initially point at `D`.

---

# 10. Deleting a tag

Local tag:

```bash
git tag -d v1.0.0
```

This removes the tag reference locally.

It **doesn't delete the commit**.

That's important.

```text
v1.0.0 ──X
             \
              commit D
```

Deleting the tag only removes:

```text
v1.0.0
```

The commit can still exist through:

```text
main → D
```

or other references.

---

# 11. Tags and remotes

Creating a tag locally does **not automatically push it**.

For one tag:

```bash
git push origin v1.0.0
```

Or all tags:

```bash
git push origin --tags
```

Now the remote also has:

```text
origin
  │
  └── v1.0.0 → commit
```

To delete a remote tag:

```bash
git push origin --delete v1.0.0
```

---

# 12. Tags are extremely useful for releases

Your own `DoItLater` project is a good example.

You had a release:

```text
v1.0.0
```

The idea is:

```text
development:

A──B──C──D──E──F
         ↑
       v1.0.0
```

Then development continues:

```text
A──B──C──D──E──F──G──H──I
         ↑
       v1.0.0
```

Now you can always say:

```text
"v1.0.0 is exactly commit F."
```

That's much better than saying:

```text
"Use that commit from three months ago."
```

---

# 13. Tag naming conventions

For software releases, you'll commonly see:

```text
v1.0.0
v1.1.0
v1.1.1
v2.0.0
```

This usually follows **Semantic Versioning**:

```text
MAJOR.MINOR.PATCH
```

For example:

```text
1.4.2
│ │ │
│ │ └── patch
│ └──── minor
└────── major
```

Very roughly:

```text
1.4.2 → bug fix
1.5.0 → backward-compatible feature
2.0.0 → breaking change
```

---

# The mental model

Don't think of a tag as "another branch."

Think:

```text
BRANCH
   │
   └── movable pointer
          ↓
        commit
          ↓
        commit
          ↓
        commit


TAG
   │
   └── named historical marker
          ↓
        commit
```

And the most useful commands to memorize are:

```bash
# Create lightweight tag
git tag v1.0.0

# Create annotated tag
git tag -a v1.0.0 -m "Release 1.0.0"

# Tag a specific commit
git tag -a v1.0.0 <commit> -m "Release 1.0.0"

# List
git tag

# Inspect
git show v1.0.0

# Push
git push origin v1.0.0

# Delete local
git tag -d v1.0.0

# Delete remote
git push origin --delete v1.0.0
```

The **one sentence to remember**:

> **A tag gives a stable human-readable name to an important point in Git history, most commonly a release.**


[[Git & Github]]