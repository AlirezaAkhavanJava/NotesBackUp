
# `ON UPDATE`

I'm assuming you mean the twin of `ON DELETE`. If you meant the plain `UPDATE` statement, tell me and I'll teach that instead.

## 1. The intuition

`ON DELETE` answers: _"what if the parent row disappears?"_  
`ON UPDATE` answers: _"what if the parent's **key value changes**?"_

Analogy: children carry a sticky note saying "my parent's ID is `UK`". If the country code is renamed from `UK` to `GB`, every sticky note is now wrong. `ON UPDATE` says what to do with them:

- "Rewrite all the notes automatically" → `CASCADE`
- "Refuse the rename while notes point at the old value" → `RESTRICT` / `NO ACTION`
- "Erase the notes" → `SET NULL`
- "Replace the notes with a default" → `SET DEFAULT`

It uses the same five actions as `ON DELETE`, and it's declared in the same place, on the child's FK.

## 2. Syntax

```sql
FOREIGN KEY (country_code) REFERENCES countries(code)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
```

The two clauses are independent. You can combine any `ON UPDATE` action with any `ON DELETE` action, in either order.

## 3. When it fires

It only triggers when the **referenced column's value actually changes** on the parent. These do **not** trigger it:

- updating other columns of the parent (`UPDATE countries SET name = ...`)
- updating the parent's key to the same value
- updating the child's FK column (that's a different check, covered in section 6)

## 4. Examples

**CASCADE: propagate the new key (SQLite)**

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE countries (code TEXT PRIMARY KEY, name TEXT);
CREATE TABLE cities (
    id           INTEGER PRIMARY KEY,
    name         TEXT,
    country_code TEXT,
    FOREIGN KEY (country_code) REFERENCES countries(code)
        ON UPDATE CASCADE
);

INSERT INTO countries VALUES ('UK', 'United Kingdom');
INSERT INTO cities VALUES (1, 'London', 'UK'), (2, 'Leeds', 'UK');

UPDATE countries SET code = 'GB' WHERE code = 'UK';

SELECT * FROM cities;
-- 1|London|GB
-- 2|Leeds|GB
```

You changed one row, and the database rewrote two child rows for you.

**NO ACTION / RESTRICT: block the change**

Remove the `ON UPDATE` clause (or write `ON UPDATE RESTRICT`) and rerun:

```sql
UPDATE countries SET code = 'GB' WHERE code = 'UK';
-- SQLite:     FOREIGN KEY constraint failed
-- PostgreSQL: ERROR: update or delete on table "countries" violates foreign key
--             constraint ... DETAIL: Key (code)=(UK) is still referenced from table "cities".
```

A country with no cities could be renamed freely, because only rows with children are protected.

**SET NULL: detach the children (PostgreSQL)**

```sql
CREATE TABLE teams (code TEXT PRIMARY KEY);
CREATE TABLE players (
    id        SERIAL PRIMARY KEY,
    team_code TEXT REFERENCES teams(code) ON UPDATE SET NULL
);
INSERT INTO teams VALUES ('A1');
INSERT INTO players (team_code) VALUES ('A1'), ('A1');

UPDATE teams SET code = 'A2' WHERE code = 'A1';
SELECT * FROM players;   -- team_code is NULL on both rows
```

This is rarely what you want, since the children lose the link instead of following it. It exists for completeness.

**Both clauses together, the realistic combination**

```sql
CREATE TABLE cities (
    id           SERIAL PRIMARY KEY,
    country_code TEXT NOT NULL
        REFERENCES countries(code)
        ON UPDATE CASCADE      -- renames follow automatically
        ON DELETE RESTRICT     -- can't delete a country that has cities
);
```

Renames are harmless because the cascade keeps everything consistent. Deletes are dangerous because data would be lost, so they're blocked.

## 5. Why you rarely write it

Most tables use **surrogate keys** (`id SERIAL`, auto-increment), and a surrogate key never changes. If a value never changes, `ON UPDATE` never fires, so it is effectively dead code there.

It matters when the PK or referenced column is a **natural key**, a real-world value that can change:

- country or currency codes (`UK` → `GB`)
- usernames, emails, SKUs, license plates
- composite keys built from business data

This is also an argument against natural keys: if a value can be renamed, you now depend on cascades to keep every referencing table correct. Surrogate keys avoid the problem entirely.

## 6. Nuances and gotchas

1. **Default is `NO ACTION`**, same as for `ON DELETE`. Without the clause, renaming a referenced key is blocked.
2. **Updating a child's FK column is a separate check.** `UPDATE cities SET country_code = 'XX'` fails if `XX` isn't in `countries`, whatever `ON UPDATE` says. `ON UPDATE` governs changes to the _parent_, not the child.
3. **SQLite needs `PRAGMA foreign_keys = ON`**, or the cascade silently doesn't run and you get orphans, exactly like with deletes.
4. **Cascades chain.** If `cities.code` is itself referenced by another table with `ON UPDATE CASCADE`, the change keeps propagating. One key change can rewrite rows across many tables.
5. **Performance:** a cascading update rewrites every child row, and without an index on the child's FK column, each parent change scans the whole child table.
6. **PostgreSQL can defer the check** with `DEFERRABLE INITIALLY DEFERRED` (with `NO ACTION`), letting you change parent and children yourselves inside a transaction and be validated at `COMMIT`. This is the same trick as in the deferred delete example.
7. **`SET DEFAULT`'s default must exist** in the parent, or the update fails, same as with `ON DELETE`.

## 7. The Spring Boot connection

JPA/Hibernate **treats an entity's `@Id` as immutable**. Changing it through an entity (`entity.setId(...)`) is an error or undefined behavior, so in a typical Spring Boot app, primary keys are never updated through JPA. That is one more reason `ON UPDATE CASCADE` is rare in application code: it shows up mostly in hand-written SQL, migrations, and legacy schemas with natural keys.

## Quick summary

|Event on parent|Clause|Typical use|
|---|---|---|
|Row deleted|`ON DELETE ...`|very common, you choose per relationship|
|Referenced key value changed|`ON UPDATE ...`|uncommon, natural keys only|

Rule of thumb: surrogate keys → skip `ON UPDATE`. Natural keys that might change → `ON UPDATE CASCADE`.





[[1 - WHAT IS SQLITE3 🍕]]