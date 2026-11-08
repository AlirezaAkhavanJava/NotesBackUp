


## SIMILAR TO: what it actually is

Your notes call it "regex-like", which is a good summary. It sits between `LIKE` and full regex. It uses `LIKE`'s wildcards (`%`, `_`) plus a few regex features, and it must match the **whole string**, like `LIKE` and unlike `~`, which matches anywhere.

|Symbol|Meaning|
|---|---|
|`%` and `_`|any string / any one character (as in `LIKE`)|
|`\|`|alternation: `Alice\|Bob`|
|`*`, `+`, `?`|zero or more, one or more, zero or one|
|`{m}`, `{m,}`, `{m,n}`|repetition counts|
|`( )` and `[ ]`|grouping and character classes|

A `.` is a plain dot here, not "any character".

```sql
WHERE code SIMILAR TO '[A-Z]{3}-[0-9]{4}'      -- ABC-1234, whole string only
WHERE name SIMILAR TO '(Alice|Bob)%'           -- starts with Alice or Bob
```

Postgres rewrites `SIMILAR TO` into a regular expression internally, so it adds nothing over `~`. The same first example as a regex needs explicit anchors: `code ~ '^[A-Z]{3}-[0-9]{4}$'`. In practice most people use `LIKE` for simple cases and `~` for everything else.

## Regex essentials for `~`

Since `~` is the better tool, here's the minimum you need:

|Piece|Meaning|
|---|---|
|`^` `$`|start / end of string|
|`.`|any one character|
|`\d` `\w` `\s`|digit / word character / whitespace|
|`[abc]` `[^abc]`|one of / none of|
|`a\|b`|a or b|
|`x{2,4}`|2 to 4 repeats|
|`(?i)` at the start|case-insensitive for the whole pattern|

```sql
WHERE phone ~ '^\+?\d{7,15}$'
WHERE name ~ '(?i)^dr\.'          -- same as ~* '^dr\.'
```

From PostgreSQL 15 there is also `regexp_like(text, pattern, flags)`, a function form of the same check.

## LIKE beyond the basics

**Escaping wildcards.** This matters whenever the pattern comes from a user. If someone searches for `100%`, the `%` becomes a wildcard and matches almost everything. Declare an escape character:

```sql
WHERE note LIKE '100!%' ESCAPE '!'        -- literal "100%"
```

For a "starts with" search on arbitrary input, `starts_with()` avoids escaping altogether:

```sql
WHERE starts_with(name, $1)
```

**Several patterns at once** with `ANY` or `ALL`:

```sql
WHERE name LIKE ANY (ARRAY['A%', 'B%'])           -- matches at least one pattern
WHERE name ILIKE ALL (ARRAY['%red%', '%wool%'])   -- matches every pattern
```

**`NOT LIKE` and NULL.** `NULL NOT LIKE 'x%'` is `NULL`, not true, so rows with a `NULL` value disappear from `NOT LIKE` results, the same silent filter you saw with `<>`.

## ANY and ALL: the edge cases

Your notes show the basic form, and it works, but two situations give surprising results. Take your example:

```sql
SELECT * FROM employees
WHERE salary > ALL (SELECT salary FROM employees WHERE department_id = 1);
```

The rules are:

- `ANY` is `TRUE` if any comparison is true, `FALSE` if all are false (or the set is empty), and `NULL` otherwise.
- `ALL` is `TRUE` if every comparison is true (or the set is empty), `FALSE` if any is false, and `NULL` otherwise.

That gives two traps:

1. **Empty set:** if department 1 has no employees, `> ALL (empty)` is `TRUE`, so **every** employee passes. `> ANY (empty)` does the opposite and matches nobody.
2. **A `NULL` in the set:** if one salary in department 1 is `NULL`, then no row can ever be `TRUE` for `> ALL`, so the query returns nothing. This is the same mechanism behind the `NOT IN` trap, since `NOT IN` is really `<> ALL`.

For "greater than everyone", an aggregate is usually clearer and ignores `NULL`s:

```sql
WHERE salary > (SELECT max(salary) FROM employees WHERE department_id = 1)
```

Note the difference: with an empty department, `max` returns `NULL`, so nobody passes. That's often the behavior you actually want.

## Optional filters (the search-form problem)

A very common real need is a query where some filters may be absent: "filter by department if one was chosen, otherwise show everyone." The popular trick looks like this:

```sql
SELECT * FROM employees
WHERE ($1::int IS NULL OR department_id = $1)
  AND ($2::numeric IS NULL OR salary >= $2);
```

Two details make or break it:

- **Add the cast** (`$1::int`). With a bare `$1 IS NULL`, Postgres can't infer the parameter's type and fails with _could not determine data type of parameter $1_.
- **Mind the plan.** Postgres can't tailor a plan when it doesn't know whether `$1` is `NULL`. After a few executions of a prepared statement, it may settle on a generic plan that scans the whole table even when you pass a selective value. If that bites, you can set `plan_cache_mode = force_custom_plan`, or build the query so it only contains the conditions that are actually present (still using bound parameters, never string-pasted values).

Two tempting alternatives are worse. `COALESCE($1, department_id) = department_id` silently drops rows where the column is `NULL` and blocks index use. `IS NOT DISTINCT FROM $1` does the wrong job here, because it makes a `NULL` parameter match `NULL` rows instead of meaning "ignore this filter."

## Conditions that live outside WHERE

The same boolean logic shows up in other places, and each has a twist.

**CHECK constraints** reject rows whose condition is false:

```sql
ALTER TABLE employees ADD CONSTRAINT salary_positive CHECK (salary > 0);
```

The twist: a `CHECK` passes when the condition is `TRUE` **or `NULL`**. So a `NULL` salary sails through, and you need `NOT NULL` as well if that's not allowed.

**Partial indexes** index only the rows that match a condition, which keeps them small. A partial _unique_ index is the classic way to enforce uniqueness among live rows:

```sql
CREATE UNIQUE INDEX ON users (email) WHERE deleted_at IS NULL;
```

Your query must include a condition that implies the index's condition (`WHERE deleted_at IS NULL`) for Postgres to use it.

**Trigger `WHEN` clauses** run the trigger function only when a condition holds, which saves a lot of wasted calls:

```sql
CREATE TRIGGER log_change
AFTER UPDATE ON accounts
FOR EACH ROW
WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION audit_change();
```

## A few fixes for your notes

Some lines in your notes are a bit misleading:

- **`WHERE NOT department_id = 3`** also drops rows where `department_id` is `NULL`. If you want them kept, use `WHERE department_id IS DISTINCT FROM 3`.
- **Section 5.2, `WHERE COALESCE(department_id, 0) = 0`:** this doesn't mean the same as `IS NULL`, because it also matches rows whose id is really `0`, and it blocks a plain index on the column. Use `WHERE department_id IS NULL`.
- **Section 5.3, `WHERE NULLIF(bonus, 0) IS NOT NULL`:** this is just `bonus <> 0`, since `NULL` already fails the comparison. The `NULLIF` belongs in the division (`salary / NULLIF(bonus, 0)`), not the filter.
- **Section 6.3:** with `LEFT JOIN ... WHERE d.dept_name IS NOT NULL`, the `LEFT JOIN` behaves as an `INNER JOIN`, because unmatched rows are filtered out. The note "can handle NULLs" is misleading here. If you want an inner join, write `JOIN`; if you want to keep unmatched rows, move conditions on `d` into the `ON` clause.

## Lines to add to your notes

- `SIMILAR TO` matches the **whole** string and is rewritten as a regex internally. Prefer `LIKE` or `~`.
- `LIKE ... ESCAPE '!'` for literal `%` and `_`; `starts_with(col, x)` for safe prefix search.
- `LIKE ANY (ARRAY[...])` / `LIKE ALL (ARRAY[...])` for multiple patterns.
- `> ALL (empty set)` is `TRUE`; a `NULL` in the set makes `ALL` unable to succeed.
- Optional filter: `($1::int IS NULL OR col = $1)`, and always cast the parameter.
- `CHECK` passes on `NULL`, so pair it with `NOT NULL`.
- Partial indexes and trigger `WHEN` are conditions too.





[[PostgreSQL]]