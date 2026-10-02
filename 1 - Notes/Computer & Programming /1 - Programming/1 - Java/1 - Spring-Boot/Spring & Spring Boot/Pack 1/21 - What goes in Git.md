
## The core intuition first

Here's the fundamental tension: `application.properties` needs to be in your repo (your teammates need the structure, the non-secret defaults, the key names) — but it's also the single most likely place for a database password, API key, or JWT secret to accidentally end up in plaintext, committed, and pushed to a public GitHub repo forever.

Git's danger isn't "you might type the wrong command." It's that **git never truly forgets**. Once a commit is pushed, that secret exists in the repo's history permanently — even if you delete it in the next commit, anyone can `git log` back to the old version and read it. Deleting a line doesn't delete the leak; it just adds a new commit on top of the leak.

So the entire safety strategy boils down to one principle: **secrets should never reach a `git commit` in the first place.** Everything below is mechanics in service of that one rule.

---

## The mental model: two files, two audiences

Think of your config as split into two categories that should live in two _different_ files:

|File|Contains|Goes in git?|
|---|---|---|
|`application.properties`|Structure, non-sensitive defaults, key names|Yes|
|`application-local.properties` / `.env` / env vars|Actual passwords, API keys, secrets|**No**|

The first file is documentation-as-code for your team ("here are the settings this app needs"). The second is per-developer or per-environment and never travels through git at all.

---

## 1. `.gitignore` — the first line of defense

```gitignore
# .gitignore
application-local.properties
application-secrets.properties
.env
*.env.local
```

**Why this works:** git simply never tracks these files, so `git add .` or `git commit -a` can't accidentally scoop them up. This is a _preventive_ control — it stops the leak before it happens, which is far better than any cleanup after the fact.

**The gotcha:** `.gitignore` only prevents _new_ tracking. If a file was ever committed even once — even in your very first commit before you added the ignore rule — it's already in history and `.gitignore` does nothing retroactively. Check with:

```bash
git log --all --full-history -- application-local.properties
```

If that returns commits, the file (and whatever secret was in it at the time) is already exposed in history, regardless of what your `.gitignore` says today.

---

## 2. Structure: separate the committed file from the secret file

```properties
# application.properties (committed — safe defaults, structure only)
spring.application.name=inventory-service
server.port=8080
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
```

```properties
# application-local.properties (NOT committed — real values)
DB_USERNAME=postgres
DB_PASSWORD=actual_real_password_here
```

Or, more idiomatically, just use environment variables directly and skip the second file entirely:

```bash
export DB_USERNAME=postgres
export DB_PASSWORD=actual_real_password_here
```

The `${DB_USERNAME}` syntax in the properties file is **placeholder resolution against the `Environment`** — same mechanism from the previous answer. It looks up `DB_USERNAME` from OS env vars (or a `.env` file, or a local properties file layered on top via `spring.config.import`), substitutes it in, and the actual value never has to be typed into a file git tracks.

For local dev, a common pattern is `spring.config.import`:

```properties
# application.properties
spring.config.import=optional:file:.env[.properties]
```

`optional:` means "don't fail startup if this file doesn't exist" — important because this file _shouldn't_ exist on a fresh clone or in CI.

---

## 3. Templates — the missing-context problem

If `application-local.properties` is gitignored, a new teammate who clones the repo has **no idea what keys they're even supposed to fill in**. The fix is a committed _template_ with dummy/blank values:

```properties
# application-local.properties.example  (this one IS committed)
DB_USERNAME=your_username_here
DB_PASSWORD=your_password_here
```

Onboarding instructions become: "copy `application-local.properties.example` to `application-local.properties` and fill in real values." The `.example` file documents the shape without leaking the substance.

---

## 4. Pre-commit hooks — catching mistakes before they leave your machine

`.gitignore` protects files by _name_, but it won't stop you from accidentally pasting a password into a file that _is_ tracked (like `application.properties` itself). For that you want a pre-commit scanner.

**gitleaks** is the standard tool here:

```bash
# install once
brew install gitleaks   # or apt/binary on Debian

# scan the whole repo history
gitleaks detect --source . -v

# or wire it as a pre-commit hook so it runs automatically
```

`.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

This runs a regex/entropy-based scan on every file you're about to commit, looking for patterns that look like AWS keys, JWTs, private keys, generic "password=" assignments, etc. If it finds one, the commit is **blocked** before it's created — this is the key advantage over any after-the-fact cleanup: the secret never becomes a git object at all.

---

## 5. What to do if a secret _already_ got committed

This is the part people usually discover too late, so it's worth knowing even though you hope to never need it.

**Step 1 — treat the secret as compromised immediately.** Rotate it (change the DB password, revoke and reissue the API key) _regardless_ of what you do to git history. Removing it from history doesn't un-leak it if anyone already pulled the repo, forked it, or if it was public even briefly — bots scan public GitHub repos for exposed keys within minutes.

**Step 2 — remove it from history**, using either:

```bash
# git-filter-repo (modern, recommended over the old filter-branch)
git filter-repo --path application.properties --invert-paths
```

or BFG Repo-Cleaner for a gentler targeted removal:

```bash
bfg --replace-text passwords.txt
```

**Step 3 — force-push and have every collaborator re-clone.** Rewriting history changes every commit hash downstream, so old clones become incompatible — this is disruptive, which is exactly why prevention (`.gitignore` + pre-commit hooks) is so much cheaper than cure.

---

## Gotchas and advanced nuances

- **`git rm --cached` isn't enough by itself.** If you accidentally committed a secret and then run `git rm --cached application-secrets.properties` followed by a normal commit, the file stops being tracked _going forward_, but the secret still sits in every earlier commit. You've fixed the symptom, not the leak.
- **Forks and mirrors outlive your repo.** If your repo was ever public, assume the secret is permanently compromised the moment it's pushed — GitHub's own secret-scanning + third-party scrapers routinely index new public commits within minutes. Rotation, not history-rewriting, is the real fix.
- **CI/CD secrets don't belong in any `.properties` file at all**, committed or not. Use your CI platform's secret store (GitHub Actions secrets, GitLab CI/CD variables) and inject them as env vars at pipeline runtime:
    
    ```yaml
    # GitHub Actions exampleenv:  DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
    ```
    
    This keeps the secret out of your repo _and_ out of your CI logs (GitHub automatically redacts registered secret values from log output).
- **Spring profiles can leak too.** A common mistake: committing `application-prod.properties` with real production credentials because "it's just the prod config, not really a secret file." Treat _any_ profile-specific file with real credentials the same as a generic secret file — gitignore it, template it.
- **`git diff` before every commit involving config files** is a cheap habit that catches a surprising number of near-misses — `git diff --cached application.properties` right before `git commit` costs three seconds and has saved more leaked secrets than most tooling.
- **Encrypted secrets in git (advanced option):** tools like `git-crypt` or SOPS let you commit _encrypted_ versions of secret files directly to git, decrypted transparently on checkout for authorized users. This is useful when you specifically want secrets version-controlled alongside code (e.g., infrastructure-as-code repos) rather than externalized — different trade-off than the "keep it out of git entirely" approach above, worth knowing exists but overkill for a typical app repo.


[[Java]]
[[0 - Git]]
[[Spring Framework]]