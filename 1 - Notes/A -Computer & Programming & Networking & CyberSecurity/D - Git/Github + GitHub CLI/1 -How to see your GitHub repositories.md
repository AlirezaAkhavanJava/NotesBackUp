If you want to **see your remaining GitHub repositories from the CLI**, the command you've already been using is:

```bash
gh repo list AlirezaAkhavanJava --limit 100
```

### What each part means

```text
gh
│
└── repo
    │
    └── list
```

- `gh` → GitHub's CLI
    
- `repo` → you're working with repositories
    
- `list` → list repositories
    
- `AlirezaAkhavanJava` → your GitHub username
    
- `--limit 100` → show up to 100 repositories
    

Since you currently have only 8, you could simply use:

```bash
gh repo list AlirezaAkhavanJava
```

It'll show your remaining repositories.

### But here's a more useful command

If you want to see **more information** about them:

```bash
gh repo list AlirezaAkhavanJava \
  --limit 100 \
  --json name,description,isPrivate,isFork,pushedAt
```

That gives you structured JSON containing:

```text
name
description
isPrivate
isFork
pushedAt
```

And because you're a CLI bastard now, you can pipe it through `jq` to make exactly the view you want.

For example, **just repository names**:

```bash
gh repo list AlirezaAkhavanJava \
  --limit 100 \
  --json name \
  | jq -r '.[].name'
```

Output:

```text
RustyAtom
BasicsAgain
DirtyPenguin
megacorp
cs50
chere
FoxiLoop
BackToFuture
```

Or **name + last update date**:

```bash
gh repo list AlirezaAkhavanJava \
  --limit 100 \
  --json name,pushedAt \
  | jq -r '.[] | "\(.name)\t\(.pushedAt)"'
```

That's the useful bit to learn here: **`gh` gets the GitHub data, `jq` transforms it**. Two small tools doing their jobs instead of one bloated GUI trying to be your entire fucking operating system.

[[0 - Git 🍋‍🟩]]