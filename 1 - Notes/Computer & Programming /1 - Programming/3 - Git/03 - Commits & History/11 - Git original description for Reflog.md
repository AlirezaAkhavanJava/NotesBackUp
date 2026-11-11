
Reference logs, or "reflogs", record when the tips of branches and other references were updated in the local repository. Reflogs are useful in various Git commands, to specify the old value of a reference. For example, `HEAD@{2}` means "where HEAD used to be two moves ago", `master@{one.week.ago}` means "where master used to point to one week ago in this local repository", and so on. See [gitrevisions[7]](https://git-scm.com/docs/gitrevisions) for more details.

The command takes various subcommands, and different options depending on the subcommand:

The "show" subcommand (which is also the default, in the absence of any subcommands) shows the log of the reference provided in the command-line (or `HEAD`, by default). The reflog covers all recent actions, and in addition the `HEAD` reflog records branch switching. `git` `reflog` `show` is an alias for `git` `log` `-g` `--abbrev-commit` `--pretty=oneline`; see [git-log[1]](https://git-scm.com/docs/git-log) for more information.

The "list" subcommand lists all refs which have a corresponding reflog.

The "exists" subcommand checks whether a ref has a reflog. It exits with zero status if the reflog exists, and non-zero status if it does not.

The "write" subcommand writes a single entry to the reflog of a given reference. This new entry is appended to the reflog and will thus become the most recent entry. The reference name must be fully qualified. Both the old and new object IDs must not be abbreviated and must point to existing objects. The reflog message gets normalized.

The "delete" subcommand deletes single entries from the reflog, but not the reflog itself. Its argument must be an _exact_ entry (e.g. "`git` `reflog` `delete` `master@{2}`"). This subcommand is also typically not used directly by end users.

The "drop" subcommand completely removes the reflog for the specified references. This is in contrast to "expire" and "delete", both of which can be used to delete reflog entries, but not the reflog itself.

---
## OPTIONS

### [](https://git-scm.com/docs/git-reflog#_options_for_show)Options for `show`

`git` `reflog` `show` accepts any of the options accepted by `git` `log`.

### [](https://git-scm.com/docs/git-reflog#_options_for_delete)Options for `delete`

`git` `reflog` `delete` accepts options `--updateref`, `--rewrite`, `-n`, `--dry-run`, and `--verbose`, with the same meanings as when they are used with `expire`.

### [](https://git-scm.com/docs/git-reflog#_options_for_drop)Options for `drop`

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---all)`--all`

Drop the reflogs of all references from all worktrees.

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---single-worktree)`--single-worktree`

By default when `--all` is specified, reflogs from all working trees are dropped. This option limits the processing to reflogs from the current working tree only.

### [](https://git-scm.com/docs/git-reflog#_options_for_expire)Options for `expire`

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---all-1)`--all`

Process the reflogs of all references.

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---single-worktree-1)`--single-worktree`

By default when `--all` is specified, reflogs from all working trees are processed. This option limits the processing to reflogs from the current working tree only.

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---expiretime)`--expire=`_<time>_

Prune entries older than the specified time. If this option is not specified, the expiration time is taken from the configuration setting `gc.reflogExpire`, which in turn defaults to 90 days. `--expire=all` prunes entries regardless of their age; `--expire=never` turns off pruning of reachable entries (but see `--expire-unreachable`).

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---expire-unreachabletime)`--expire-unreachable=`_<time>_

Prune entries older than _<time>_ that are not reachable from the current tip of the branch. If this option is not specified, the expiration time is taken from the configuration setting `gc.reflogExpireUnreachable`, which in turn defaults to 30 days. `--expire-unreachable=all` prunes unreachable entries regardless of their age; `--expire-unreachable=never` turns off early pruning of unreachable entries (but see `--expire`).

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---updateref)`--updateref`

Update the reference to the value of the top reflog entry (i.e. <ref>@{0}) if the previous top entry was pruned. (This option is ignored for symbolic references.)

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---rewrite)`--rewrite`

If a reflog entry’s predecessor is pruned, adjust its "old" SHA-1 to be equal to the "new" SHA-1 field of the entry that now precedes it.

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---stale-fix)`--stale-fix`

Prune any reflog entries that point to "broken commits". A broken commit is a commit that is not reachable from any of the reference tips and that refers, directly or indirectly, to a missing commit, tree, or blob object.

This computation involves traversing all the reachable objects, i.e. it has the same cost as _git prune_. It is primarily intended to fix corruption caused by garbage collecting using older versions of Git, which didn’t protect objects referred to by reflogs.

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt--n)`-n`

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---dry-run)`--dry-run`

Do not actually prune any entries; just show what would have been pruned.

[](https://git-scm.com/docs/git-reflog#Documentation/git-reflog.txt---verbose)`--verbose`

Print extra information on screen.

[[Git & Github]]