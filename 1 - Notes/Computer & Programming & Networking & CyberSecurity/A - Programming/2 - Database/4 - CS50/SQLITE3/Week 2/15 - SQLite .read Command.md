


The `.read` command is a **dot-command** (meta-command) in the SQLite3 command-line shell. It reads and executes SQL (or other dot-commands) from a file — similar to `SOURCE` in MySQL or `\i` in PostgreSQL.

## Syntax

```
.read FILENAME
```

- **FILENAME** – path to the script file to execute.
- If no path is given or the path is relative, SQLite resolves it relative to the **current working directory** of the shell.

## Basic Example

**file: schema.sql**
```sql
CREATE TABLE users (
    id    INTEGER PRIMARY KEY,
    name  TEXT NOT NULL,
    email TEXT UNIQUE
);

INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');
```

**SQLite shell session:**
```sql
sqlite> .open mydb.sqlite
sqlite> .read schema.sql
sqlite> SELECT * FROM users;
1|Alice|alice@example.com
```

## Alternative: Run from the OS shell

You can also execute the same file without entering the SQLite shell:

```bash
sqlite3 mydb.sqlite < schema.sql        # Unix redirection
sqlite3 mydb.sqlite ".read schema.sql"  # pass dot-command as argument
```

## Nested `.read` Files

Scripts loaded via `.read` can themselves contain `.read` commands, allowing you to chain files:

**main.sql**
```sql
.read tables.sql
.read indexes.sql
.read seed.sql
```

```sql
sqlite> .read main.sql
```

## Common Use Cases

| Use case | Example |
|----------|---------|
| Load a schema definition | `.read schema.sql` |
| Seed test data | `.read seed.sql` |
| Run a migration | `.read migrations/001_init.sql` |
| Run a batch of queries | `.read reports/monthly.sql` |
| Re-run a setup script interactively | `.read setup.sql` |

## Important Notes

1. **Errors don't stop execution by default** — after an error, SQLite prints a message but continues with the next statement unless you change the behavior with `.bail on`:
   ```sql
   sqlite> .bail on
   sqlite> .read schema.sql
   ```
   With `.bail on`, the script stops at the first error.

2. **Path handling** — quotes are needed if the path contains spaces:
   ```sql
   sqlite> .read "C:/My Files/schema.sql"
   ```

3. **Terminator** — statements inside the file must end with `;` (or `/` for some cases), just like typing them interactively.

4. **Relative vs. absolute paths** — `.read` uses the shell's working directory, **not** the directory of the file that called it. This matters for nested `.read` files.

5. **Same as redirection, but interactive** — `< schema.sql` at startup vs. `.read schema.sql` inside the shell are functionally equivalent.

6. **Dot-commands allowed** — the file can contain dot-commands like `.mode csv`, `.headers on`, `.import`, etc., not just SQL.

## Related Dot-Commands

| Command | Purpose |
|---------|---------|
| `.read FILE` | Execute commands from FILE |
| `.once FILE` | Send next query's output to FILE |
| `.output FILE` | Send all subsequent output to FILE |
| `.import FILE TABLE` | Import CSV/other data into a table |
| `.dump` | Export database as SQL (output can later be `.read`) |
| `.bail on\|off` | Stop on error (useful with `.read`) |

## Round-Trip Example

A common pattern is to back up a database and restore it:

```bash
# Backup
sqlite3 mydb.sqlite .dump > backup.sql

# Restore (in shell)
sqlite> .read backup.sql
```

Because `.dump` produces a file full of SQL statements, `.read` is the natural counterpart for restoring it.


[[1 - WHAT IS SQLITE3]]