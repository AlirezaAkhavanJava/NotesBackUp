
Stash has [a few options](https://git-scm.com/docs/git-stash), but the ones that you will use most are:

```sh
git stash
git stash pop
git stash list
```

### `git stash pop` – What it does

`git stash pop` applies the most recent stashed changes (the top of the stash stack, i.e. `stash@{0}`) back to your working directory **and then removes that stash entry** from the stack if the apply succeeds without conflicts.

#### Command syntax
```bash
git stash pop [stash-ref]    # e.g. git stash pop stash@{2}
```

- If you don’t specify a stash reference, it defaults to the latest one (`stash@{0}`).
- You can pop a specific older stash with `git stash pop stash@{n}`.

#### What happens step-by-step
1. Git tries to **apply** the stashed changes (like `git stash apply`).
2. If the apply is completely clean (no conflicts):
   - The stash entry is **automatically dropped** (deleted from the stash list).
3. If there are **merge conflicts**:
   - The stash is applied as far as possible.
   - Conflicts are marked in the files (just like a normal merge).
   - The stash entry is **NOT dropped** – it stays in the list so you can try again later after resolving conflicts.
4. If the apply fails entirely (very rare), the stash also remains.

#### Common options
| Option                  | Description                                                                 | Example                          |
|-------------------------|-----------------------------------------------------------------------------|----------------------------------|
| `--index`               | Also restore the staged state that was stashed (if it had any)              | `git stash pop --index`          |
| `-q` or `--quiet`       | Suppress output                                                             | `git stash pop -q`               |
| `stash@{n}`             | Pop a specific stash instead of the latest                                  | `git stash pop stash@{3}`        |

#### Difference between `git stash pop` and `git stash apply`
| Command            | Applies changes? | Removes stash on success? | Keeps stash on conflict? | Typical use case                          |
|--------------------|------------------|--------------------------|--------------------------|-------------------------------------------|
| `git stash apply`  | Yes              | No                       | Yes                      | Try changes without losing the stash      |
| `git stash pop`    | Yes              | Yes                      | Yes (keeps it)           | One-time restore, clean up stash list     |

#### Practical examples
```bash
# Pop the latest stash (most common)
git stash pop

# Pop a specific older stash and restore index state too
2
git stash pop --index stash@{2}

# If you get conflicts, resolve them, then you can drop manually if you want
git stash drop stash@{0}   # after resolving
```

#### Safety tip
Many people prefer `git stash apply` first to preview what will happen, then `git stash drop` when they’re sure. `pop` is convenient but can be surprising when conflicts leave the stash still in the list.

#### Popular alias (the one that makes “git pop” work)
```bash
git config --global alias.pop 'stash pop'
```
After that, `git pop` does exactly `git stash pop`.

That’s pretty much everything you need to know to use `git stash pop` confidently! Let me know if you hit a specific issue.
###### Tags : [[Git]]
[[0 - Git 🍋‍🟩]]