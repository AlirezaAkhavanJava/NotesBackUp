## The Style, Formalized

**Core principle:** _Ignore rules belong in `.gitignore` only if they describe the project. Anything that exists purely because of how you personally work belongs in `.git/info/exclude`._

His version of this works, but it has three structural weaknesses worth fixing.

---

## Weakness 1: Doesn't Survive Re-clone

`.git/info/exclude` lives inside `.git/`, which is **not part of the repository's content** — it's local to one working copy. Clone the repo on a new machine, or even just re-clone it fresh on the same machine, and the exclude rules are gone. He'd have to remember to re-add `out`, `out2`, etc. every time.

**Fix: automate re-adding it instead of relying on memory.**

Add a tiny setup script to the project (this one's fine to commit — it doesn't reveal _what_ he ignores, just _that_ new clones should self-configure):

```bash
#!/usr/bin/env bash
# scripts/setup-local.sh
cat >> .git/info/exclude <<'EOF'
out
out2
out3
.scratch*
EOF
echo "Local excludes configured."
```

Run once per clone:

```bash
bash scripts/setup-local.sh
```

Now the _mechanism_ is documented and shareable (a teammate could run it for their own personal scratch habits too, with their own patterns) without ever exposing _his specific_ ignored filenames in a tracked `.gitignore`.

---

## Weakness 2: Loose, Unscaled Naming (`out`, `out2`, `out3`...)

This is the real improvement. Right now every new scratch file needs its own exclude line, and `out`, `out2` as names are fragile — generic enough to risk colliding with something a teammate _does_ track someday.

**Fix: one naming convention, one exclude rule, infinite files.**

```bash
# .git/info/exclude
.scratch/
```

Then he just always writes scratch output into a dedicated, consistently-named folder:

```bash
mkdir -p .scratch
echo "foo" > .scratch/out
some-command > .scratch/debug-1
curl ... > .scratch/response.json
```

One line in the exclude file covers **every** file he'll ever dump in there, forever — no more editing the exclude file every time he invents a new scratch filename.

---

## Weakness 3: Risk of Committing Before the Exclude Exists

Here's a subtle gotcha tying back to something from earlier: **`.gitignore`/exclude rules only prevent _staging_, they don't retroactively hide already-tracked files.** If he runs `git add .` even once _before_ his exclude rule exists (e.g., brand-new clone, forgot to run the setup script first), `out` gets committed — now it's in history, visible to the whole team, and removing it cleanly requires `git rm --cached` plus a commit.

**Fix: make the habit un-skippable by tying it to repo setup, not memory.**

If using the dedicated-folder approach above, you can also harden it with a pre-commit hook as a safety net (not as the primary mechanism — exclude is still primary — just a backstop):

```bash
# .git/hooks/pre-commit
if git diff --cached --name-only | grep -q '^\.scratch/'; then
  echo "Refusing to commit .scratch/ files."
  exit 1
fi
```

This never lets a scratch file slip into a commit even if the exclude rule somehow wasn't active yet.

---

## Full Improved Workflow

```bash
# One-time, per clone:
mkdir -p .scratch
echo ".scratch/" >> .git/info/exclude

# Daily use, unlimited scratch files, zero further exclude edits:
echo "foo" > .scratch/out
command > .scratch/whatever-i-want

git status        # .scratch/ never appears, no matter what's inside it
```

Optional convenience — a shell function in `~/.bashrc` so creating scratch output is one keystroke shorter and consistent across every repo he works in:

```bash
scratch() {
  mkdir -p .scratch
  "$@" > ".scratch/$(date +%s).out"
}
```

```bash
scratch echo "foo"        # writes to .scratch/1696185032.out automatically
```

---

## Why This Is a Genuine Upgrade, Not Just Style Preference

|Original (`out`, `out2` in exclude)|Improved (`.scratch/` folder in exclude)|
|---|---|
|New scratch filename → must edit exclude file again|New scratch filename → zero exclude edits, ever|
|Easy to forget re-adding after re-clone|Setup script makes it one command, repeatable|
|Risk of accidental commit before exclude exists|Optional pre-commit hook makes that structurally impossible|
|Flat files mixed into repo root — visually noisy in file explorer|One folder, clean separation, easy to `rm -rf .scratch` entirely when done|

---

**One-line summary:**

> Keep the core instinct exactly as his tutor taught it — personal-workflow files go in `.git/info/exclude`, never `.gitignore` — but generalize from "list every filename" to "ignore one dedicated folder," and automate the exclude-setup step so it survives re-clones instead of depending on memory.





[[0 - Git]]