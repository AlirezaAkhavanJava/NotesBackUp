## 🔧 How to Fix Expired GitHub Token (HTTPS)

If your GitHub token expires and Git stops pushing/pulling, do this:

---

### 🧹 1. Remove the old token

```bash
rm -f ~/.git-credentials
```

---

### ⚙️ 2. Re-enable global credential storage

```bash
git config --global credential.helper store
```

This tells Git to save your credentials in `~/.git-credentials` for all repos.

---

### 🔗 3. Make sure your repo uses HTTPS

Check:

```bash
git remote -v
```

If it shows `git@github.com:...`, switch it:

```bash
git remote set-url origin https://github.com/<username>/<repo>.git
```

---

### 🔐 4. Re-authenticate once

Run:

```bash
git fetch
```

or

```bash
git push
```

When prompted:

```
Username for 'https://github.com': <your_github_username>
Password for 'https://<username>@github.com': <your_new_token>
```

Paste your **new GitHub token** as the password.

---

### ✅ 5. Verify it’s saved

```bash
cat ~/.git-credentials
```

You should see:

```
https://<username>:<new_token>@github.com
```

---

### 💡 Done

Git will now automatically use this new token for **all your GitHub repos** that use HTTPS.

##### [[0 - Git 🍋‍🟩]]