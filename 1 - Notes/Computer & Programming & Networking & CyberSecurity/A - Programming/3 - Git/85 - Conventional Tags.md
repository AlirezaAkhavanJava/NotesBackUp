**Conventional Tags** (or **Conventional Commits + tags**) are a way to **name Git tags** based on semantic versioning and the type of changes in your commits. They work hand-in-hand with **Semver** to automate versioning.

---

### 1. Common format

A conventional tag usually follows **`vMAJOR.MINOR.PATCH`**, e.g.:

```
v1.0.0
v2.3.1
v0.5.0
```

- The **`v`** is optional but common.
    
- Matches semantic versioning rules: `MAJOR.MINOR.PATCH`.
    

---

### 2. Purpose

- Marks **specific points in history** for releases.
    
- Can be used in CI/CD pipelines to **automatically trigger releases**.
    
- Makes it clear what version your code is at.
    

---

### 3. Creating tags

**Lightweight tag:**

```bash
git tag v1.0.0
```

**Annotated tag (recommended):**

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
```

Push tags to remote:

```bash
git push origin v1.0.0
# or all tags
git push --tags
```

---

### 4. Optional: Pre-release tags

For beta or RC releases:

```
v1.0.0-beta.1
v1.0.0-rc.2
```

- Works with **Conventional Commits** to automate next version bumps.
    

---

💡 Rule of thumb: **Conventional tags + Semver = clear, predictable releases**.




###### Tags : [[0 - Git 🍋‍🟩]]