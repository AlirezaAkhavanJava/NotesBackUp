 You have a **public repository already**, and you want to change its visibility to **private**.

Use:

```bash
gh repo edit AlirezaAkhavanJava/REPOSITORY_NAME --visibility private
```

For example, if you want `RustyAtom` to become private:

```bash
gh repo edit AlirezaAkhavanJava/RustyAtom --visibility private
```

Then verify:

```bash
gh repo view AlirezaAkhavanJava/RustyAtom --json name,visibility
```

You should get:

```json
{
  "name": "RustyAtom",
  "visibility": "PRIVATE"
}
```

### For several repositories

```bash
gh repo edit AlirezaAkhavanJava/RustyAtom --visibility private
gh repo edit AlirezaAkhavanJava/BasicsAgain --visibility private
gh repo edit AlirezaAkhavanJava/BackToFuture --visibility private
```

That's all. **Public → Private**, repository stays intact, commits stay intact, files stay intact. Only its visibility changes.


[[0 - Git 🍋‍🟩]]