

### What is `git bisect`?

`git bisect` is a powerful Git tool that uses **binary search** to find the exact commit that introduced a bug (or any regression) in your repository history.  
It’s incredibly fast — even in repositories with thousands of commits, it usually takes only 10–15 steps.

### When to use it
- A feature that worked before now fails (e.g., tests, crashes, wrong output, etc.).
- You don’t know where the bug was introduced.
- You have an automated way (or manual) to say “good” or “bad” for a given commit.

### How git bisect works (step by step)

```bash
# 1. Start the bisect session
git bisect start

# 2. Mark the current commit (usually HEAD) as bad
git bisect bad

# 3. Mark a known good commit (e.g., a tag or older commit) as good
git bisect good v1.0.0          # or git bisect good a1b2c3d4

# Git now checks out a commit roughly in the middle
# 4. Test the code here
#    If the bug is present  → git bisect bad
#    If the bug is NOT present → git bisect good

# Repeat step 4 until Git tells you the first bad commit
# 5. When finished, Git shows something like:
#    abc123456789 is the first bad commit

# 6. Exit bisect mode and return to your original branch
git bisect reset
```

### Full example (realistic scenario)

```bash
# Bug is present on main right now
git bisect start
git bisect bad HEAD                 # current commit is bad

# You know version 2.5.0 was working fine
git bisect good v2.5.0

# Git checks out something like commit 8f3d2a1...
# You run your tests / app
./run-tests.sh                      # → fails → bug present
git bisect bad

# Git checks out another commit, say 5e7f9b2...
./run-tests.sh                      # → passes → no bug
git bisect good

# ... continues automatically ...
# After ~10-12 steps:
# 3d9a7b4c1f2e is the first bad commit
# commit 3d9a7b4c1f2e
# Author: Alice <alice@example.com>
# Date:   Wed Oct 15 14:22:01 2025
#
#     Fix memory leak in parser → this "fix" actually broke everything!

git bisect reset                    # back to where you started
```

### Powerful options & shortcuts

| Command                                | What it does                                                                 |
|----------------------------------------|------------------------------------------------------------------------------|
| `git bisect start <bad> <good>`        | Skip the two separate bad/good commands                                     |
| `git bisect good` / `git bisect bad`   | Mark current checkout as good or bad                                         |
| `git bisect skip`                      | If a commit won’t compile or can’t be tested, skip it                        |
| `git bisect run ./test-script.sh`      | Fully automated! Git will run the script; exit 0 = good, non-zero = bad      |
| `git bisect visualize` or `view`       | Opens gitk or tig to show where you are                                      |
| `git bisect log`                       | Shows the full history of your bisect session (useful for replay)             |
| `git bisect replay <logfile>`          | Replay a previous bisect session                                             |

### Pro tip: Fully automated bisect (the best way)

If you have a test script that returns non-zero on failure:

```bash
git bisect start HEAD v2.5.0
git bisect run ./scripts/regression-test.sh
# → Git does everything automatically and tells you the bad commit in seconds
```

Even works with `npm test`, `pytest`, `make test`, etc.

### Common pitfalls
- Forgetting `git bisect reset` → you stay in a detached HEAD in the middle of history.
- Bisecting merge commits can be confusing (use `git bisect skip` if needed).
- If your bug depends on external state (DB, network), make sure the test is reproducible at any commit.

### Summary

| Situation                          | Command to use                  |
|------------------------------------|---------------------------------|
| Manual hunt                       | `git bisect start` + good/bad   |
| One-liner with known good tag      | `git bisect start HEAD v1.2.3`  |
| Fully automated                    | `git bisect run ./test.sh`      |

`git bisect` is one of Git’s most underused superpowers — once you use it a couple of times, you’ll wonder how you ever lived without it.

Got a specific bug you’re hunting right now? Paste the details and I’ll give you the exact bisect commands! 🕵️‍♂️



##### Tags : [[0 - Git 🍋‍🟩]]