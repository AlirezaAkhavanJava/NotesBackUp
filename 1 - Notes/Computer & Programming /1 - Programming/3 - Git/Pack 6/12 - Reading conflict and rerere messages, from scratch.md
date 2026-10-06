

When a merge conflicts, Git prints messages in the terminal and also changes your file. There are two things to read: the **terminal messages** and the **conflict markers inside the file**.

## 1. The terminal messages

Example output of `git merge main` with rerere enabled:

```
Auto-merging config.txt
CONFLICT (content): Merge conflict in config.txt
Recorded preimage for 'config.txt'
Automatic merge failed; fix conflicts and then commit the result.
```

Line by line:

|Message|Meaning|
|---|---|
|`Auto-merging config.txt`|Git tried to combine both versions of this file automatically.|
|`CONFLICT (content): Merge conflict in config.txt`|It failed. Both sides changed the same lines. `(content)` means the conflict is in the file's text.|
|`Recorded preimage for 'config.txt'`|**rerere** saved the conflicted version (the "before").|
|`Automatic merge failed; fix conflicts and then commit the result.`|The merge is paused. It's your turn.|

Other types of `CONFLICT` you may see:

|Message|Meaning|
|---|---|
|`CONFLICT (modify/delete)`|One side edited the file, the other deleted it.|
|`CONFLICT (add/add)`|Both sides created a file with the same name but different content.|
|`CONFLICT (rename/delete)`|One side renamed the file, the other deleted it.|

## 2. The rerere messages

|Message|When it appears|Meaning|
|---|---|---|
|`Recorded preimage for 'file'`|When the conflict first happens|Saved the "before" snapshot.|
|`Recorded resolution for 'file'.`|When you finish (commit or `git rerere`)|Saved your fixed version, the "after".|
|`Resolved 'file' using previous resolution.`|When the same conflict returns|Applied your saved fix automatically.|
|`Updated preimage for 'file'`|Same conflict returns, but not yet resolved|The saved conflict was refreshed.|
|`Forgot resolution for 'file'`|After `git rerere forget`|The saved fix was deleted.|

Important: even after `Resolved ... using previous resolution`, the file is **not staged**. Check it, then run `git add`.

## 3. Reading the conflict markers inside the file

Open the file and you'll see:

```
<<<<<<< HEAD
timeout = 30
=======
timeout = 60
>>>>>>> feature
```

- `<<<<<<< HEAD` starts the block. Below it is **your current branch's** version (the branch you were on when you ran `merge`).
- `=======` is the divider.
- Below the divider is the **incoming** version, from the branch you merged in (the name after `>>>>>>>`).
- `>>>>>>> feature` ends the block.

To resolve it: keep one side, or combine both, and **delete all three marker lines**. For example, the final file is just:

```
timeout = 45
```

Note: during a **rebase**, HEAD and incoming are swapped. HEAD is the branch you're rebasing _onto_, and the other side is _your_ commit being replayed. This confuses almost everyone at first.

## 4. Checking status during a conflict

```bash
git status
```

```
Unmerged paths:
        both modified:   config.txt
```

`both modified` means both branches changed it. After you fix it and run `git add config.txt`, it moves to "Changes to be committed."

Helpful extras:

```bash
git diff                 # shows the conflict
git rerere status        # files rerere is tracking
git rerere diff          # shows your edits relative to the recorded conflict
git log --merge -p       # commits from both sides that touch the conflict
```

## 5. The full sequence in order

1. `git merge main` prints `CONFLICT` and `Recorded preimage`.
2. Open the file and read the markers.
3. Edit, remove the markers.
4. `git add file`.
5. `git commit`, which prints `Recorded resolution for 'file'.`
6. Next time the same conflict appears, you see `Resolved 'file' using previous resolution.`





[[Git & Github]]