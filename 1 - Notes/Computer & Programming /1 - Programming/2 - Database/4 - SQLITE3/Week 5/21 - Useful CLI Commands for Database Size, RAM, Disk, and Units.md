

Since you're working with SQLite on Linux, there are really **two different things** you may want to measure:

```text
1. Database/file size on disk
2. Memory/RAM being used
```

They require different commands.

---

## SQLite: database size

Inside `sqlite3`:

```sql
PRAGMA page_count;
PRAGMA page_size;
```

Multiply them:

```text
database size = page_count × page_size
```

For example:

```text
page_count = 50000
page_size  = 4096

50000 × 4096
= 204,800,000 bytes
≈ 195.31 MiB
≈ 0.195 GiB
```

SQLite also gives you:

```sql
PRAGMA freelist_count;
```

which tells you how many pages are currently free.

You can calculate the currently allocated database size with:

```sql
SELECT
    page_count * page_size AS bytes
FROM pragma_page_count(), pragma_page_size();
```

---

## Linux: easiest way to see file size

For your SQLite database:

```bash
ls -lh mfa.db
```

Example:

```text
-rw-r--r-- 1 ethan ethan 195M mfa.db
```

`-h` means **human-readable**.

Without it:

```bash
ls -l mfa.db
```

might show:

```text
204800000
```

So you get the exact byte count.

A better command for disk usage is:

```bash
du -h mfa.db
```

and exact bytes:

```bash
du -B1 mfa.db
```

---

# Linux RAM usage

To see overall RAM:

```bash
free -h
```

Example:

```text
               total   used   free
Mem:            15Gi   6.2Gi  4.1Gi
Swap:           4Gi    0Gi    4Gi
```

Exact bytes:

```bash
free -b
```

Other useful units:

```bash
free -k    # KiB
free -m    # MiB
free -g    # GiB
```

---

# See a process's memory usage

For example, while `sqlite3` is running:

```bash
ps aux | grep sqlite
```

Or:

```bash
ps -o pid,rss,vsz,comm -C sqlite3
```

Here:

```text
RSS = resident memory actually in RAM
VSZ = virtual memory size
```

For database work, **RSS** is usually the more interesting number.

---

# Bytes → KB → MB → GB → TB

For computer storage/memory, you'll often encounter **binary units**:

```text
1 KiB = 1024 bytes
1 MiB = 1024 KiB
1 GiB = 1024 MiB
1 TiB = 1024 GiB
```

Therefore:

```text
1 KiB = 1,024 bytes
1 MiB = 1,048,576 bytes
1 GiB = 1,073,741,824 bytes
1 TiB = 1,099,511,627,776 bytes
```

Linux commonly displays these as:

```text
KiB
MiB
GiB
TiB
```

but you will also see people informally write:

```text
KB
MB
GB
TB
```

while still meaning powers of 1024.

---

## Convert a size yourself

Linux has a very useful command:

```bash
numfmt --to=iec 204800000
```

Result:

```text
196M
```

Or:

```bash
numfmt --to=iec-i 204800000
```

which uses binary units explicitly:

```text
196Mi
```

And:

```bash
numfmt --to=si 204800000
```

uses decimal units:

```text
205M
```

So:

```text
IEC   → KiB, MiB, GiB
SI    → kB, MB, GB
```

---

## One command worth memorizing

When you're on Linux and wondering:

> “How big is this file?”

use:

```bash
du -h filename
```

When you want the exact number:

```bash
du -B1 filename
```

When you want:

> “How much RAM does this machine have and how much is being used?”

use:

```bash
free -h
```

And for SQLite specifically:

```sql
PRAGMA page_count;
PRAGMA page_size;
PRAGMA freelist_count;
```

These three are especially useful now that you're learning **pages, B-trees, indexes, and `VACUUM`**, because they let you connect the logical database concepts to actual disk space.


[[SQlite]]