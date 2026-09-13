The command is:

```bash
gh repo delete OWNER/REPO
```

For your account, for example:

```bash
gh repo delete AlirezaAkhavanJava/RepoName
```

GitHub will ask you to confirm. The `gh repo delete` command requires the `delete_repo` scope, which you already added earlier. ([GitHub CLI](https://cli.github.com/manual/gh_repo_delete?utm_source=chatgpt.com "GitHub CLI | Take GitHub to the command line"))

### If you're absolutely sure

You can skip the confirmation:

```bash
gh repo delete AlirezaAkhavanJava/RepoName --yes
```

⚠️ **That permanently deletes the GitHub repository.** Not "remove from your local machine", not "hide it", actually delete the remote repository. GitHub does enjoy giving destructive commands very little drama. ([GitHub CLI](https://cli.github.com/manual/gh_repo_delete?utm_source=chatgpt.com "GitHub CLI | Take GitHub to the command line"))

### If you're currently inside the repo

You can also simply run:

```bash
gh repo delete
```

but GitHub CLI will **still prompt you for confirmation**, and the `--yes` flag is ignored when no repository argument is supplied. ([GitHub CLI](https://cli.github.com/manual/gh_repo_delete?utm_source=chatgpt.com "GitHub CLI | Take GitHub to the command line"))

I'd use the explicit form:

```bash
gh repo delete AlirezaAkhavanJava/RepoName
```

It makes it much harder to accidentally send the wrong repository into the fucking void.

[[0 - Git 🍋‍🟩]]