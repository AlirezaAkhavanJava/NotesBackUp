


## 📄 From CSV Files

**1. SQLite CLI (best for large files)**

```sql
sqlite3 mydb.db
.mode csv
.import data.csv my_table
```

Speed trick — wrap in a transaction:
```sql
BEGIN;
.mode csv
.import data.csv my_table
COMMIT;
```

Skip the header row:
```sql
.import --skip 1 data.csv my_table
```

**2. `sqlite-utils` (Python CLI — super easy)**

```bash
sqlite-utils insert mydb.db mytable data.csv --csv
```

**3. DB Browser for SQLite (GUI)**

Menu: **File → Import → Table from CSV file...**
Then pick delimiter, encoding, and whether the first row is a header.

**4. Python**

```python
import csv, sqlite3

conn = sqlite3.connect('mydb.db')
cur = conn.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS users (name, email, age)")

with open('data.csv') as f:
    reader = csv.reader(f)
    next(reader)  # skip header
    cur.executemany("INSERT INTO users VALUES (?, ?, ?)", reader)

conn.commit()
conn.close()
```

---

## 🧩 From JSON Files

SQLite has built-in JSON support (`json1` extension).

**Whole file as a blob:**
```sql
INSERT INTO files(name, content) VALUES ('dogs.json', readfile('dogs.json'));
```

**Parse and insert into columns:**
```sql
INSERT INTO dogs(id, name, age)
SELECT json_extract(value, '$.id'),
       json_extract(value, '$.name'),
       json_extract(value, '$.age')
FROM json_each(readfile('dogs.json'));
```

**JSON Lines (one object per line)** — easiest via Python:
```python
import json, sqlite3
conn = sqlite3.connect('mydb.db')
cur = conn.cursor()

with open('data.jsonl') as f:
    for line in f:
        obj = json.loads(line)
        cur.execute("INSERT INTO dogs VALUES (?, ?, ?)",
                    (obj['id'], obj['name'], obj['age']))
conn.commit()
```

---

## 🐍 From Excel, HTML, Markdown, etc. (via Pandas)

```python
import pandas as pd
import sqlite3

df = pd.read_excel('data.xlsx')        # or read_html, read_json, etc.

conn = sqlite3.connect('mydb.db')
df.to_sql('my_table', conn, if_exists='replace', index=False)
conn.close()
```

- `if_exists='replace'` → overwrite the table
- `if_exists='append'` → add rows

---

## 📦 One-Shot Tool: `sqlitebiter`

Auto-detects format and dumps everything into a SQLite file.

```bash
sqlitebiter -o output.sqlite file data.csv data.xlsx page.html
```

Handles CSV, Excel, HTML, JSON, Markdown, and even other SQLite files.

---

## 💾 Restore from a SQL Dump

```bash
sqlite3 restore.db
sqlite> .read backup.sql
```

---

## 💡 Key Tips

1. **Always wrap bulk inserts in a transaction** (`BEGIN; ... COMMIT;`) — can be 100x faster.
2. **For big files**, don't load everything into memory — stream it in batches.
3. **Use `.import` in the CLI** for raw CSV speed; use Python/Pandas when you need transformation.
4. **`sqlite-utils`** and **`sqlitebiter`** save you from writing boilerplate.

---




[[1 - WHAT IS SQLITE3 🍕]]