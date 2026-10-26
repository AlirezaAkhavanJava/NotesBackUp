Git configuration lives in several files, and Git merges them into one final answer. So when you "retrieve" a setting, you are really asking one of four questions: what is set, where is it set, which value wins, and who will Git say I am? Each question has its own command.

If you learn only one habit from this guide, make it `git config --list --show-origin --show-scope`. It shows every setting together with its scope and file, which is usually enough to explain any surprising behavior.

## How Git finds a value

Git reads files from least to most specific. If the same key appears more than once, the **last one read wins**.

|Order|Scope|Typical location|
|---|---|---|
|1|system|`/etc/gitconfig` on Debian, `C:\Program Files\Git\etc\gitconfig` on Windows|
|2|global|`~/.gitconfig`, or `~/.config/git/config` if that exists|
|3|local|`.git/config` inside the repo|
|4|worktree|`.git/config.worktree` (only if you use `git worktree` with that feature on)|

Two extra things can change the result:

- **Included files.** An `[include]` or `[includeIf]` section pulls in another file, and its values count too.
- **Environment variables.** `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM`, and `GIT_CONFIG_NOSYSTEM` can redirect or skip files.

## 1. See what is set

```bash
git config --list                     # merged result, key=value
git config --system --list            # one scope only
git config --global --list
git config --local --list             # run inside a repo
git config --list --name-only         # just the keys, no values
```

Outside a repo, `--list` shows only system and global settings. Inside a repo it also shows local ones.

If the same key appears twice in the output, the lower line wins.

## 2. See where it is set

```bash
git config --list --show-origin
git config --list --show-scope
git config --list --show-origin --show-scope    # both
git config --show-origin user.name              # one key
```

Example output:

```
global  file:/home/you/.gitconfig   user.name=Your Name
local   file:.git/config            user.email=work@company.com
```

`--show-scope` needs Git 2.26 or newer. The output separates the origin from the value with a tab, which helps when you parse it in a script.

## 3. Get one value

```bash
git config user.name                  # effective (winning) value
git config --global user.email        # from one scope only
git config --get user.name            # same as the first line, more explicit
git config --get-all remote.origin.url        # every value of a key
git config --get-regexp '^alias\.'            # all keys matching a pattern
git config --get-regexp 'remote\..*\.url'
```

Details that matter:

- `--get` returns the **last** value if a key has several. `--get-all` returns all of them.
- `--get-regexp` matches on the **key name**. It is better than `git config --list | grep`, because `grep` also matches values.
- Quote the pattern so your shell does not expand it.

## 4. Ask Git who it thinks you are

```bash
git var GIT_AUTHOR_IDENT
git var GIT_COMMITTER_IDENT
```

These print the identity Git would actually put on a commit, after merging every config file and environment variable. The `user.name` command only shows what is written in config. If a commit shows the wrong email, check `git var` first.

## 5. Read a file directly

```bash
git config --file ~/.gitconfig --list       # read one specific file
git config --global --edit                  # open the global file in your editor
cat ~/.gitconfig                            # raw text of one file
```

Reading a raw file shows only that file. It does not show the merged result or included files. When you use `--file`, Git does not follow `include` directives unless you add `--includes`.

## 6. Use it in scripts

```bash
git config --get user.name || echo "name not set"       # exit code 1 if missing
git config --default "main" --get init.defaultBranch    # fallback value
git config --type=bool --get core.autocrlf              # normalize to true/false
git config --type=path --get core.excludesfile          # expands ~ to a full path
```

|Exit code|Meaning|
|---|---|
|0|Value found|
|1|Key not found (prints nothing)|
|2|Invalid key|

So a missing key is silent, but you can detect it from the exit code.

## Debugging recipes

|Problem|What to run|
|---|---|
|Commits show the wrong email|`git var GIT_AUTHOR_IDENT`, then `git config --show-origin user.email`|
|A setting seems ignored|`git config --list --show-origin --show-scope`, then look for the same key lower in the output|
|Work and personal emails mix|Check your `includeIf` paths with `git config --list --show-origin` inside a work repo|
|An alias does not exist|`git config --get-regexp '^alias\.'`|
|Which remote am I pushing to?|`git config --get-regexp '^remote\.'`|

## Common mistakes

- Expecting `cat ~/.gitconfig` to show every setting. It shows one file.
- Forgetting that local overrides global, so a repo can quietly use a different email.
- Running `--local` outside a repository. It fails because there is no `.git/config`.
- Using `--get` on a multi-valued key and thinking you saw all values.
- Checking one scope when the winning value comes from another.

## A short practice run

Try these in order, inside any repo:

```bash
git config --list --show-origin --show-scope
git config --get-all remote.origin.url
git config --get-regexp '^alias\.'
git var GIT_AUTHOR_IDENT
git config --get nonexistent.key; echo $?     # prints 1
```

That covers listing, sources, multiple values, effective identity, and exit codes.




[[Git & Github]]