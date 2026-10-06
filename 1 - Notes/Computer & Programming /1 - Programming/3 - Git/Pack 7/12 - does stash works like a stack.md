

 Git stash is _structured_ like a stack, but you aren't restricted to stack operations. You can pop or apply any entry by its index.

## Stack-like behavior

- New stashes are pushed on top as `stash@{0}`, and older ones shift down (`@{1}`, `@{2}`, ...).
- A bare `git stash pop` or `git stash apply` always takes the top (`stash@{0}`).

## Accessing the middle

```bash
git stash list
# stash@{0}: On main: login form WIP
# stash@{1}: On main: refactor api client
# stash@{2}: On main: experiment with caching

git stash pop stash@{1}      # apply and remove the middle one
git stash apply stash@{2}    # apply but keep it
git stash drop stash@{1}     # delete without applying
git stash show -p stash@{2}  # inspect it first
```

## What happens to the indexes

When you remove an entry from the middle, everything below it shifts up to fill the gap. After popping `stash@{1}` from the list above:

```
stash@{0}: On main: login form WIP
stash@{1}: On main: experiment with caching   # was @{2}
```

So **re-run `git stash list` before each operation** if you're doing several in a row, since indexes change. Dropping by the wrong index is an easy mistake.

## Tip

Since indexes are positional and shift around, naming stashes with `git stash push -m "description"` makes it much easier to identify the right one. Newer Git versions (2.x) also let you reference by message-matching in some workflows, but the `stash@{n}` form is the universally reliable one.



[[Git & Github]]