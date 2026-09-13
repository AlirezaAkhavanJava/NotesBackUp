
`git remote set-url` is a Git command used to **change the URL of an existing remote** in your repository.

- **Remote**: a reference to a remote repository (like GitHub) that your local repo can fetch from or push to.
    
- **Purpose**: You use it when the remote repository’s URL has changed, or if you want to point your local repo to a different remote.
    

**Syntax:**

```bash
git remote set-url <remote_name> <new_url>
```

- `<remote_name>`: usually `origin` (the default remote name).
    
- `<new_url>`: the new URL of the remote repository (SSH or HTTPS).
    

**Example:**

```bash
git remote set-url origin git@github.com:ethanwardJava/webflyx.git
```

After running this, your `origin` remote will point to the GitHub repo instead of the old URL.

✅ Verify with:

```bash
git remote -v
```

It will show the updated URLs for fetch and push.

##### Tags : [[0 - Git 🍋‍🟩]]