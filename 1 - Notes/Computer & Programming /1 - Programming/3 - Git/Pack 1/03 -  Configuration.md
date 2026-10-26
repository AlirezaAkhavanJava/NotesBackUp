
Git configuration is how you tell Git who you are and how you like it to behave. You set it once, and every command after that follows your rules. That includes the name on your commits, your editor, shortcuts for long commands, and how pushing and pulling work.

Git reads settings from three places, and the most specific one wins. That means a repo can override your personal settings, and your personal settings can override the machine's.

|Level|Flag|File|Applies to|
|---|---|---|---|
|System|`--system`|`/etc/gitconfig`|Everyone on the machine|
|Global|`--global`|`~/.gitconfig`|You, in every repo|
|Local|`--local` (default)|`.git/config`|One repo only|

## Start here: the essentials

Run these once on every new machine:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global core.editor "nano"     # default is vi/vim
```

To check or remove settings:

```bash
git config user.name           # read one value
git config --list --show-origin   # see every setting AND which file it came from
git config --global --unset core.editor
```

Use `--show-origin` when a setting behaves strangely. It tells you which file is responsible.

One fix to the note: don't use `git config --add` for your name or email. `--add` appends a second value instead of replacing the first. Plain `git config` replaces it.

## Useful settings

**Aliases** turn long commands into short ones:

```bash
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all"
```

Now `git st` and `git lg` work.

**Pull and push behavior** is worth setting deliberately:

```bash
git config --global pull.rebase false    # false = merge, true = rebase
git config --global push.default simple  # push the current branch to its upstream
```

`simple` is already the default in modern Git. Avoid `matching`, which pushes every branch with a matching name.

**Small comfort settings:**

```bash
git config --global color.ui auto
git config --global help.autocorrect 10   # fixes typos after a 1-second delay
```

## Power settings

### Conditional includes (work vs personal)

You can use a different email depending on the folder:

```ini
# ~/.gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/work/.gitconfig
```

```ini
# ~/work/.gitconfig
[user]
    email = work@company.com
```

Any repo under `~/work/` now uses your work email automatically. The trailing `/` matters.

### Credentials

You can stop typing your password every time:

|Helper|Where it stores credentials|Safe?|
|---|---|---|
|`cache`|In memory, temporarily|Yes|
|`store`|Plain text in `~/.git-credentials`|No|
|`manager`|Windows' secure store (Git Credential Manager)|Yes|
|`libsecret`|Linux keyring (often needs a package installed on Debian)|Yes|

The note lists `wincred` for Windows. `manager` is the newer recommended choice. Use a personal access token as your password for GitHub.

### Commit signing

```bash
git config --global user.signingkey <GPG-KEY-ID>
git config --global commit.gpgsign true
```

Find your key ID with `gpg --list-keys`, then add the public key to GitHub or GitLab.

### Merge and diff tools

```bash
git config --global merge.tool meld
git config --global diff.tool meld
```

Then use `git mergetool` and `git difftool`.

### Commit template

```bash
git config --global commit.template ~/.gitmessage
```

Put your preferred message layout in `~/.gitmessage`, and Git fills it in each time you commit.

## Hooks and custom commands

**Hooks** are scripts in `.git/hooks/` that run at certain moments. For example, `pre-commit` runs before a commit is made, and `commit-msg` checks your message. Make them executable with `chmod +x`. Hooks live inside `.git/`, so they are not shared when someone clones the repo.

**Custom commands:** any executable named `git-something` on your PATH can be run as `git something`.

## Quick cleanup

- The last line of your note mentions xAI's API. It has nothing to do with Git, so delete it.
- You use both Debian and Windows, so look at `core.autocrlf` (line endings) if files ever show as fully changed after switching systems.
- Back up `~/.gitconfig` before big edits.
- For details, run `git help config`.


---

So far we have only read and set values. This part is about changing and removing them, plus the parts of the config system that stay hidden until you need them: the file format, multi-valued keys, includes, one-off overrides, and a set of settings worth knowing about. Once you understand these, you can treat your config files as something you control and not as a mystery.

## 1. Removing and changing settings

### The basic commands

```bash
git config --global --unset core.editor            # remove one setting
git config --global --unset-all remote.origin.fetch   # remove every value of a repeated key
git config --global --edit                         # open the file and edit by hand
```

**Pick the scope on purpose.** If you don't write `--global` or `--system`, Git works on the **local** file, `.git/config`. Outside a repo, that fails. Before you remove something, find its file:

```bash
git config --show-origin core.editor
```

If it's defined in the global file but you ran `--unset` without `--global`, nothing changes and the value stays. This is the most common reason an unset "doesn't work".

### Exit codes

|Code|Meaning|
|---|---|
|0|Removed|
|5|Key didn't exist in that file, or it has several values and you used `--unset`|

If you get a failure on a repeated key, use `--unset-all`.

### Keys that can have several values

Some keys can appear more than once, such as `remote.origin.fetch` or `credential.helper`.

|Goal|Command|
|---|---|
|Add another value|`git config --add key value`|
|Replace all values with one|`git config --replace-all key value`|
|Remove only one value|`git config --unset key "value-regex"`|
|Remove all values|`git config --unset-all key`|

The regex on the unset line matches against the **value**. Use `--fixed-value` (Git 2.30+) to match the text exactly and skip regex.

This is why earlier I said to avoid `--add` for `user.name`. It would create a second value, and reading the key would return the last one.

### Whole sections

```bash
git config --global --remove-section alias
git config --rename-section remote.origin remote.upstream    # works in the file's scope
```

Be careful with `--remove-section`, because it deletes every key in that section.

### A safe habit

```bash
cp ~/.gitconfig ~/.gitconfig.bak
git config --global --unset <key>
git config --global --list      # confirm
```

## 2. The file format

When you edit a file by hand, you work in this format:

```ini
# comments use # or ;
[user]
    name = Your Name
    email = you@example.com
[core]
    editor = nano
[remote "origin"]
    url = git@github.com:you/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[alias]
    st = status
    undo = reset --soft HEAD~1
```

Rules:

- A **section** is in `[brackets]`. A **subsection** is in quotes, like `[remote "origin"]`.
- Section names and key names are not case-sensitive. **Subsection names are.**
- The key `remote.origin.url` is section `remote`, subsection `origin`, key `url`.
- Put a value in `"quotes"` if it has leading or trailing spaces. A backslash at the end of a line continues the value on the next line.
- A line like `st = status` under `[alias]` is the same as running `git config alias.st status`.

If a hand-edited file breaks, Git says `bad config line N in file X`. The message tells you where to look.

## 3. Aliases beyond shortcuts

An alias starting with `!` runs as a **shell command**, so it can run any program or pipe several commands:

```bash
git config --global alias.undo "reset --soft HEAD~1"
git config --global alias.visual "!gitk"
git config --global alias.last "log -1 --stat"
```

Aliases can't override real Git commands, so don't name one `commit` or `status`.

## 4. Includes, in more depth

You saw `includeIf "gitdir:~/work/"`. There are more conditions:

|Condition|Applies when|
|---|---|
|`gitdir:~/work/`|The repo is inside that folder (case-sensitive)|
|`gitdir/i:~/Work/`|Same, but case-insensitive (useful on Windows)|
|`onbranch:release/*`|The current branch matches the pattern|
|`hasconfig:remote.*.url:git@github.com:mycompany/**`|A remote URL matches (Git 2.36+)|

The last one is very practical. It selects your work identity based on where the repo is hosted, no matter which folder it lives in.

A plain include has no condition:

```ini
[include]
    path = ~/.gitconfig.aliases
```

Relative paths are relative to the file that contains the `include`. Use `git config --list --show-origin` to see which included file supplied each value.

## 5. Changing settings for one command only

You don't have to write a setting to a file:

```bash
git -c user.email="other@example.com" commit -m "One-off"
git -c core.pager=cat log
```

To test with a clean config, ignore your global and system files:

```bash
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git config --list
```

On Windows in PowerShell, set the variable first with `$env:GIT_CONFIG_NOSYSTEM=1`. The `/dev/null` form works on Debian. In PowerShell, use `$env:GIT_CONFIG_GLOBAL="NUL"`.

## 6. Value types

Git's boolean values accept `true/false`, `yes/no`, `on/off`, and `1/0`. When you read a value in a script, ask for a type so Git normalizes it:

```bash
git config --type=bool core.autocrlf
git config --type=int http.postBuffer
git config --type=path core.excludesfile
```

## 7. Settings worth knowing about

|Setting|What it does|
|---|---|
|`fetch.prune true`|Deletes local references to branches removed on the remote|
|`pull.ff only`|Refuses a pull that would need a merge commit, so you decide|
|`push.autoSetupRemote true`|First `git push` on a new branch sets its upstream automatically (Git 2.37+)|
|`rebase.autoStash true`|Stashes and restores your uncommitted changes around a rebase|
|`merge.conflictStyle zdiff3`|Shows the original text in conflict markers (Git 2.35+)|
|`rerere.enabled true`|Remembers how you resolved a conflict and reuses it|
|`commit.verbose true`|Shows the diff inside the commit message editor|
|`diff.colorMoved default`|Colors moved lines differently from added or removed ones|
|`branch.sort -committerdate`|Lists recently used branches first|

Two entries worth special care:

```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

This quietly rewrites URLs, so HTTPS links use SSH. It is handy, and equally easy to forget about, so check it with `--get-regexp url`.

```bash
git config --global safe.directory /path/to/repo
```

Git refuses to work in a repo owned by another user, as a protection. This line makes an exception. Use it only for folders you trust.

### Settings that matter on both Debian and Windows

|Setting|Why|
|---|---|
|`core.autocrlf true` (Windows) / `input` (Debian)|Line-ending conversion. A `.gitattributes` file is the stronger fix|
|`core.longpaths true`|Windows only. Allows paths longer than 260 characters|
|`core.fileMode false`|Stops Git from seeing permission bits as changes, for example on a Windows drive mounted on Linux|
|`core.ignorecase`|Set by Git at `init`. Don't change it by hand unless you know why|

## 8. Signing with SSH instead of GPG

If you don't want GPG, Git can sign with an SSH key (Git 2.34+):

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

Then add the same public key to GitHub as a **signing key**.

## 9. Safety notes

- `http.sslVerify false` turns off certificate checks. Never leave it on globally. Use it only for one command with `-c`.
- `credential.helper store` keeps passwords as plain text. Prefer `manager` on Windows or `libsecret` on Debian.
- Never put tokens or passwords directly in `.git/config`. That file is easy to copy by accident.

## Quick practice run

```bash
git config --global alias.tmp "status -s"
git config --show-origin alias.tmp
git config --global --unset alias.tmp
git config alias.tmp; echo $?        # prints 1, it's gone
```

Add, find, remove, and confirm. Repeating that cycle is the easiest way to feel comfortable with config.




[[Git & Github]]