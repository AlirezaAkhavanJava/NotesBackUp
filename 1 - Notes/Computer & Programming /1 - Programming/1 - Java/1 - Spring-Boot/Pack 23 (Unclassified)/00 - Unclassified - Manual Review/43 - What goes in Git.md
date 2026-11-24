

Your config file has to live in the repo so teammates know what settings exist, but it's also where passwords and API keys most often slip into a commit. The catch: **git never forgets**. Once a secret is pushed, deleting it later doesn't help, because anyone can read the old commit. So the whole goal is one rule: **secrets never get committed in the first place.**

---

## The idea: split config into two kinds

|Goes in git|Stays out of git|
|---|---|
|`application.properties` (structure, defaults)|Real passwords, keys, tokens|

---

## Do this (5 steps)

**1. Use placeholders in the committed file**

```properties
# application.properties (committed)
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
```

Spring fills `${...}` from environment variables at startup, so no real value is ever written down.

**2. Put real values in an ignored file or env vars**

```bash
export DB_USERNAME=postgres
export DB_PASSWORD=real_password
```

Or use a local file and load it:

```properties
spring.config.import=optional:file:.env[.properties]
```

`optional:` stops startup from failing when the file is missing (fresh clone, CI).

**3. Add it to `.gitignore`**

```gitignore
.env
application-local.properties
```

Warning: this only works for files that were _never_ committed. Check with:

```bash
git log --all --full-history -- .env
```

**4. Commit a template for teammates**

```properties
# .env.example (committed)
DB_USERNAME=your_username_here
DB_PASSWORD=your_password_here
```

New dev copies it to `.env` and fills in real values.

**5. Add a safety net: gitleaks**

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

It scans what you're about to commit and **blocks the commit** if it spots a secret. This catches mistakes `.gitignore` can't, like pasting a password into a tracked file.

---

## If a secret already got committed

1. **Rotate it immediately** (change the password, revoke the key). This is the real fix, because bots scan public repos within minutes.
2. Remove it from history: `git filter-repo --path <file> --invert-paths`
3. Force-push and have everyone re-clone.

Cleanup is painful, which is why steps 1-5 above are worth it.

---

## Quick gotchas

- `git rm --cached` stops future tracking but leaves the secret in old commits.
- `application-prod.properties` with real credentials counts as a secret file too.
- CI secrets belong in your CI's secret store (e.g. GitHub Actions secrets), not in any properties file.
- Run `git diff --cached` before committing config changes.
- `git-crypt` / SOPS can commit _encrypted_ secrets. Good to know, overkill for most apps.

---

**One-line summary:** placeholders in git, real values outside git, gitleaks as the guard.



[[Spring Framework]]
[[Git & Github]]