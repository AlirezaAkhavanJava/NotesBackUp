
In Git, the key difference is **whether you want to rewrite history or create a new commit that undoes history**.

## The definition

### `git revert`

**Creates a new commit that reverses an earlier commit.**

```text
A --- B --- C --- D
              ↑
          bad commit

git revert C

A --- B --- C --- D --- C'
                        ↑
                  "undo C"
```

You **keep the original commit** in history.

### `git reset`

**Moves the branch pointer (`HEAD`) backward/elsewhere.**

```text
A --- B --- C --- D
          ↑
       git reset
```

After:

```text
A --- B
      ↑
    HEAD/main

C --- D
```

The commits C and D are no longer part of the current branch history.

---

# So when do I use each?

|Situation|Use|
|---|---|
|Commit is already pushed/shared|**`git revert`**|
|You want to safely undo a commit|**`git revert`**|
|You don't want to rewrite shared history|**`git revert`**|
|Commit is only local|**`git reset`**|
|You want to remove commits from your branch|**`git reset`**|
|You want to move `HEAD` backward|**`git reset`**|
|You want to reorganize local history|**`git reset`**|

## The senior-level mental model

Think about the question:

> **"Do I want Git history to remember that this happened?"**

### Yes → `revert`

```bash
git revert abc123
```

You're saying:

> "That commit happened. Keep it in history, but create another commit that undoes its effect."

This is ideal for shared branches like `main`.

---

### No → `reset`

```bash
git reset --hard abc123
```

You're saying:

> "Move my branch back to this point. I don't want those later commits to be part of this branch anymore."

This is mainly for **your own local history**.

---

# Example

You accidentally commit:

```text
main

A --- B --- C
          ↑
       bad commit
```

### If C was pushed to GitHub

Don't do:

```bash
git reset
git push --force
```

Prefer:

```bash
git revert C
```

Result:

```text
A --- B --- C --- C'
          ↑       ↑
         bad     undo
```

Everyone can safely pull the updated history.

---

### If C is only local

You can simply do:

```bash
git reset --hard B
```

Result:

```text
A --- B
      ↑
     main
```

C effectively disappears from your branch.

---

# One important distinction

`reset` actually has **three modes**:

```bash
git reset --soft
git reset --mixed
git reset --hard
```

They all move `HEAD`, but they treat your **staging area and working tree** differently.

The important progression is:

```text
                 HEAD
                  │
              ┌───┴───┐
              │       │
           index    working tree
          (staging)    (files)
```

- `--soft` → move `HEAD` only
    
- `--mixed` → move `HEAD` + reset staging
    
- `--hard` → move `HEAD` + staging + working tree
    

So don't reduce the concept to "`reset` deletes commits." **Reset primarily moves a reference; `--hard` additionally changes your files.**

### The rule I want you to remember

> **Shared history → `revert`.**  
> **Private/local history → `reset`.**

And the deeper distinction:

> **`revert` changes the project history by adding a commit.**  
> **`reset` changes where your branch points.**

---

If you've **already pushed** a bad commit and other people may have pulled it:

```text
A --- B --- C
          ↑
       bad commit
```

You **don't erase C from history**. Instead:

```bash
git revert C
```

Git creates a new commit:

```text
A --- B --- C --- C'
          ↑       ↑
         bad    undo
```

So:

- `C` = "I introduced the fucked-up change."
    
- `C'` = "I am now undoing that change."
    
- Everyone's history remains consistent.
    
- Nobody has to deal with rewritten history.
    

That's why **`revert` is the standard tool for undoing pushed/shared commits**.

If the bad commit is **only on your local branch**, then:

```bash
git reset
```

can be appropriate because you're free to rewrite your own history.

**The core rule:**

> **Already shared → revert.**  
> **Still private → reset.**


[[Git & Github]]