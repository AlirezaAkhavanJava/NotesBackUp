

`git maintenance` is Git's built-in housekeeper. A Git repository slowly gets messier as you work: thousands of small loose files pile up, history lookups get slower, and fetches take longer. Maintenance cleans this up in small steps on a schedule, so you never have to stop and wait for a big cleanup.

You set it up once with `git maintenance start`. After that, Git runs light jobs in the background every hour or day, and your commands stay fast. It matters most for big repos, but it costs almost nothing on small ones. Everything is controlled through the same config keys you've been learning, so it ties in nicely with the last lessons.

## Why not just use `git gc`?

`git gc` does one heavy cleanup of everything at once. Git runs it automatically ("auto gc") when it thinks you have too many loose objects, and it can freeze your terminal for a while at a bad moment.

Maintenance splits that work into smaller tasks and runs them in the background.

||`git gc` (default)|`git maintenance`|
|---|---|---|
|When it runs|Automatically after some commands, or by hand|On a schedule in the background|
|Size of the job|One big repack|Several small jobs|
|Can interrupt you|Yes|Rarely|
|Setup|None|`git maintenance start`|

## The tasks

Each task does one specific job:

|Task|What it does|Benefit|
|---|---|---|
|`gc`|Full cleanup: repack, prune unreachable objects, expire reflog|Reclaims space. Heavy|
|`commit-graph`|Writes a file that summarizes history|Faster `git log`, `git merge-base`, and branch comparisons|
|`prefetch`|Downloads new remote objects into `refs/prefetch/` in advance|Your next `git fetch` is quick. Your branches are untouched|
|`loose-objects`|Packs loose object files into a pack|Fewer small files on disk|
|`incremental-repack`|Combines small packs into larger ones, without a full repack|Keeps the object store tidy|
|`pack-refs`|Compacts reference files|Faster branch and tag lookups|

## The recommended setup: `incremental`

With the `incremental` strategy, Git swaps the heavy `gc` for the lighter tasks:

|Task|Schedule|
|---|---|
|`commit-graph`|hourly|
|`prefetch`|hourly|
|`loose-objects`|daily|
|`incremental-repack`|daily|
|`gc`|off|

Turn it on for the current repo:

```bash
git maintenance start
```

Here is what that one command does, line by line:

1. It adds this repo's path to the `maintenance.repo` key in your **global** config. That key can hold several values, which is exactly the multi-valued key idea from the config lessons.
2. It sets `maintenance.strategy = incremental` and `maintenance.auto = false` for the repo, unless you already set them. The second one stops the automatic foreground `gc` so it doesn't compete with the background jobs.
3. It installs a scheduler entry that calls `git maintenance run` every hour, every day, and every week.

Git picks the scheduler for your system. On Windows it uses Task Scheduler, and on macOS `launchd`. On Linux it uses systemd timers when available and cron otherwise. On Debian 13, expect systemd timers. You can choose with `git maintenance start --scheduler=<name>`. Run `git help maintenance` for the accepted names.

## Commands

```bash
git maintenance start              # register this repo and install the schedule
git maintenance register           # register the repo only, without touching the scheduler
git maintenance run                # run the default tasks right now
git maintenance run --task=commit-graph      # run one task
git maintenance run --auto         # run only tasks that look needed
git maintenance run --schedule=daily         # run the tasks marked daily
git maintenance stop               # remove the scheduler entries
git maintenance unregister         # remove this repo from the list
```

- `register` is useful when you want maintenance configured but prefer to manage the scheduler yourself.
- `stop` removes the schedule but keeps the repo in the `maintenance.repo` list. That way `start` brings it back quickly.
- `unregister` takes the repo off the list.

## Checking what is set up

```bash
git config --global --get-all maintenance.repo     # every repo you registered
git config --show-origin --get-regexp '^maintenance\.'     # all maintenance settings
```

You can also look at the scheduler itself. On Debian, run `systemctl --user list-timers` to see timers whose names mention Git. On Windows, open Task Scheduler and look for "Git Maintenance" entries.

## Customizing

Each task has two settings:

```bash
git config maintenance.gc.enabled true
git config maintenance.gc.schedule weekly
git config maintenance.prefetch.enabled false
git config maintenance.strategy incremental
```

|Key|Values|
|---|---|
|`maintenance.<task>.enabled`|`true` or `false`|
|`maintenance.<task>.schedule`|`hourly`, `daily`, `weekly`|
|`maintenance.strategy`|`none` or `incremental`|
|`maintenance.auto`|`true` or `false` (the foreground auto gc)|

A reasonable tweak is to turn `gc` back on weekly, so you still get a full cleanup now and then.

## Should you use it?

- **Large repos or a slow network:** yes. Prefetching and the commit graph help a lot.
- **Small personal projects:** optional. Plain auto gc is fine.
- **A repo you rarely touch:** not worth it, because there is nothing to keep warm.

Two cautions:

- Prefetch only downloads in the background. It doesn't change your branches, so it is safe.
- If you move or delete a registered repo, the global list still points to its old path. Run `git maintenance unregister` from the repo (or edit the list) to clean it up.

## Practice run

```bash
git maintenance run --task=commit-graph      # try one task by hand
git maintenance start                        # turn on the schedule
git config --global --get-all maintenance.repo
git maintenance stop                         # turn it off again
```





[[Git & Github]]