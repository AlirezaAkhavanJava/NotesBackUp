

After a squash/rebase, your local branch has **new commit IDs**, so a normal push may be rejected.

### Force push

```bash
git push --force
```

This tells the remote:

> "Ignore the fact that the remote branch has a different history. Make it look like my local branch."

### Better: `--force-with-lease`

Use this instead:

```bash
git push --force-with-lease
```

It does the same job, but with a safety check.

Git essentially says:

> "Force-update the remote, **but only if nobody has changed the remote branch since I last saw it**."

---

### Example after squash

Before:

```text
Remote:

A ── B ── C ── D
              ↑
            origin/main
```

You squash locally:

```text
Local:

A ── X
     ↑
    main
```

where `X` contains the work from `B`, `C`, and `D`.

Now:

```bash
git push
```

may give:

```text
! [rejected] main -> main (non-fast-forward)
```

because Git sees:

```text
Remote: A ── B ── C ── D
Local:  A ── X
```

These histories don't have a fast-forward relationship.

So:

```bash
git push --force-with-lease
```

updates the remote:

```text
Remote:

A ── X
     ↑
origin/main
```

### Mental model

```text
normal push
    ↓
"Add my commits after what's already there."

force push
    ↓
"Make the remote branch point to my history."

force-with-lease
    ↓
"Make the remote branch point to my history,
but only if nobody unexpectedly changed it."
```

**After your own squash/rebase on a personal feature branch, `git push --force-with-lease` is usually the correct command.**



[[Git & Github]]