You can ask GitHub for **today's commits and which repository they belong to**.

The easiest way is GitHub's search API through `gh`:

```bash
gh search commits \
  --author=AlirezaAkhavanJava \
  --committer-date="2026-08-21..2026-08-21" \
  --limit 100
```

That gives you something like:

```text
AlirezaAkhavanJava/RustyAtom    2026-08-21T10:32:14Z    Structure created
AlirezaAkhavanJava/RustyAtom    2026-08-21T11:04:51Z    Added parser
AlirezaAkhavanJava/BasicsAgain  2026-08-21T13:21:09Z    Fixed arrays
AlirezaAkhavanJava/DirtyPenguin 2026-08-21T15:42:31Z    Added packet handler
```

Then **count them**:

```bash
gh api search/commits -f q="author:AlirezaAkhavanJava committer-date:2026-08-21" \
  --jq '.total_count'
```

You'll get:

```text
4
```

So:

> **4 commits today**

### See commits grouped by repository

This is probably closer to what you're actually after:

```bash
gh api search/commits -f q="author:AlirezaAkhavanJava committer-date:2026-08-21" \
  --jq '.items[].repository.full_name' \
  | sort \
  | uniq -c \
  | sort -nr
```

Output:

```text
  12 AlirezaAkhavanJava/RustyAtom
   5 AlirezaAkhavanJava/DirtyPenguin
   2 AlirezaAkhavanJava/BasicsAgain
```

Meaning:

|Repository|Commits today|
|---|--:|
|`RustyAtom`|12|
|`DirtyPenguin`|5|
|`BasicsAgain`|2|
|**Total**|**19**|

One caveat: GitHub's commit search is based on GitHub's indexed commit data and the author/committer metadata. If you made commits locally but haven't pushed them to GitHub, **GitHub can't see them**. The damn thing isn't psychic.

[[0 - Git 🍋‍🟩]]