


First, the confusing part: **`git checkout -c` does not exist.** If you saw it somewhere, it's one of these:

- A typo for `-b`
- You're thinking of **`git switch -c`**, which is the real `-c`
- Someone's custom alias

That's why it feels like nonsense. Two different commands use two different letters for the same idea.

## 1. What a branch is

A **branch** is a movable label pointing at a commit. When you commit, the label moves forward. Creating a branch just creates a new label; it's nearly free.

**HEAD** is Git's pointer to "where you are right now." Normally it points at a branch name.

## 2. `git checkout -b`

`git checkout` is an old, overloaded command that does several unrelated things:

- switch to a branch
- restore files
- detach HEAD at a commit

The `-b` flag means **create a new branch, then switch to it**:

```bash
git checkout -b my-feature
```

This is shorthand for two commands:

```bash
git branch my-feature     # create the label
git checkout my-feature   # move HEAD onto it
```

The new branch starts at your current commit. You can pick a different start point:

```bash
git checkout -b my-feature origin/main
```

## 3. `git switch -c`

Because `checkout` does too many things, Git 2.23 (2019) split it into two clearer commands:

|Command|Job|
|---|---|
|`git switch`|change branches|
|`git restore`|restore files|

`git switch` has its own flag for creating a branch: **`-c`**, meaning **create**.

```bash
git switch -c my-feature
```

Same result as `git checkout -b my-feature`.

## 4. Side by side

|Goal|Old way|New way|
|---|---|---|
|Switch to existing branch|`git checkout dev`|`git switch dev`|
|Create and switch|`git checkout -b dev`|`git switch -c dev`|
|Create from a start point|`git checkout -b dev origin/main`|`git switch -c dev origin/main`|

## 5. Why different letters?

`-b` is historical ("branch"), kept for backward compatibility. When `switch` was designed, `-c` ("create") was chosen as clearer, and `-C` for force-create (reset an existing branch). They are separate commands that happen to do the same job, so the flags never had to match.

## Summary

- `git checkout -b name` = create and switch (old command)
- `git switch -c name` = create and switch (new command)
- `git checkout -c` = doesn't exist

Use either; `switch -c` is the more modern one.





[[Git & Github]]