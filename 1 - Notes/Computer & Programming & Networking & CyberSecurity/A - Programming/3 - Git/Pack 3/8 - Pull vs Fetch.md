


||`git fetch`|`git pull`|
|---|---|---|
|What it does|Downloads new commits/objects from remote|Downloads **and** integrates them into your current branch|
|Touches working directory?|No|Yes — updates your files|
|Touches local branch (`main`)?|No — only updates `origin/main`|Yes — moves `main` forward|
|Equivalent to|Just the download step|`fetch` + `merge` (or `rebase`)|
|Risk of surprise conflicts|None — purely informational|Possible — merge/rebase happens immediately|
|Lets you review before integrating?|Yes|No, unless you use `--no-commit`|
|Typical use|"What's changed upstream? Let me look first."|"I trust it, just bring my branch up to date now."|

---

## Simple Mental Model

```
fetch = check the mailbox, bring mail inside, don't open it
pull  = check the mailbox AND open + act on every letter immediately
```

---

## When to Use Which

- **`fetch`** → when you want to inspect incoming changes first (`git log main..origin/main`, `git diff`), especially on important/shared branches, or before deciding merge vs rebase
- **`pull`** → when you're confident and just want to sync up fast — common for quick, low-risk, solo work

---

**One-line rule to remember:**

> `fetch` is safe and passive (look only); `pull` is fast but immediately changes your branch and files (look + act). When in doubt, `fetch` first.



[[0 - Git 🍋‍🟩]]