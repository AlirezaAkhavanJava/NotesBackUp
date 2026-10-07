

## 1. Definition

The **query planner** (also called the optimizer) is the part of SQLite that takes your SQL statement and decides _how_ to execute it: which indexes to use, whether to scan the table instead, and in what order to process tables in a join.

SQL is **declarative**. Your query says _what_ you want, never _how_ to get it. You don't write "use idx_people_email" anywhere in `SELECT * FROM people WHERE email = 'x'`. The planner makes that decision on its own, and it makes it **fresh for every statement**, at the moment the statement is compiled (prepared).

## 2. Why it exists and what problem it solves

Defining an index only makes a fast path _available_. Someone still has to decide to take it, and the right choice depends on the query, the table, and the data:

- Rewriting every query by hand to name its index would be fragile. If you drop or add an index, every query would need changing.
- Using an index is **not always faster**. Sometimes a full scan wins (section 6).
- With joins, there can be many possible plans, and the difference between the best and worst can be a factor of thousands.

So SQLite has a **cost-based** planner: it estimates the cost of each candidate plan and picks the cheapest.

## 3. The process, step by step

When a statement is prepared, the planner does this:

1. **Break the `WHERE` clause into terms.** Terms are split at `AND`. For `WHERE city = 'Tehran' AND active = 1 AND name LIKE 'A%'` there are three terms.
2. **Find which terms are usable by an index.** A term is _indexable_ when it has the form `column OPERATOR expression`, where the expression doesn't depend on that same table's columns. Supported operators include `=`, `<`, `<=`, `>`, `>=`, `IN`, `IS`, `BETWEEN` (rewritten internally as `>=` and `<=`), `IS NULL`, and `LIKE` with a constant prefix under the right conditions.
3. **List candidate access paths for each table:** a full scan, a rowid lookup, and one path per index that matches at least one indexable term.
4. **Estimate the cost of each candidate** (section 4).
5. **Pick the cheapest overall plan.** This includes sorting cost: if `ORDER BY` can be satisfied by walking an index, that saves a sort step, and the planner counts that in.
6. **Compile the plan into bytecode.** The execution engine just runs it.

In Java, this happens when JDBC prepares your `PreparedStatement`. You never see the choice unless you ask, which is what `EXPLAIN QUERY PLAN` is for.

## 4. How costs are estimated

The planner compares plans using two main estimates:

- **How many rows will this access path return?** (selectivity)
- **How expensive is it to get them?**

A rough model:

```
Full scan cost  ≈  read every row of the table
Index path cost ≈  descend the B-tree  +  (matching rows × cost of one table lookup)
```

Remember from the B-tree lesson that each matching index entry normally requires a second search in the table to fetch the full row. That cost is multiplied by the number of matches. This is the key to everything that follows: **an index wins when it returns few rows**.

### Where the row estimates come from

This is the core of your question. The planner needs to know how many rows a condition like `city = 'Tehran'` will match, _before_ running it. There are two sources:

**Without statistics**, SQLite uses built-in default assumptions. For example, it assumes a non-unique index equality match returns around 10 rows, and that a `UNIQUE` index equality returns at most 1. It does not know your actual data.

**With statistics**, produced by the `ANALYZE` command, SQLite uses real numbers. `ANALYZE` scans your tables and indexes and stores results in an internal table called `sqlite_stat1`.

```sql
ANALYZE;
SELECT * FROM sqlite_stat1;
```

For the `people` table from the last lesson (200,000 rows, 3 cities, unique emails), you would see something like:

```
tbl     idx               stat
people  idx_people_city   200000 66667
people  idx_people_email  200000 1
```

**How to read the `stat` column:** the first number is the total rows in the index. The next number is the **average number of rows per distinct value of the first column**. So `66667` means "an equality search on `city` returns about 66,667 rows on average", and `1` means "an equality search on `email` returns about 1 row". For a multi-column index, you get one extra number per column, each describing how many rows remain after matching that prefix.

Those numbers are exactly the selectivity information the planner needs.

## 5. Worked example: two indexes, one query

```sql
CREATE INDEX idx_people_city  ON people (city);
CREATE INDEX idx_people_email ON people (email);

EXPLAIN QUERY PLAN
SELECT * FROM people
WHERE city = 'Tehran' AND email = 'user150000@example.com';
```

Both indexes are candidates, because both terms are indexable. The planner estimates:

|Candidate|Estimated rows returned|Verdict|
|---|---|---|
|`idx_people_city`|~66,667 (then filter by email)|Many table lookups|
|`idx_people_email`|~1|One table lookup|
|Full scan|all 200,000|Reads everything|

The plan will be:

```
SEARCH people USING INDEX idx_people_email (email=?)
```

**What this means:** the planner used the email index to find the single candidate row, then simply checked the `city` condition on that row. The `city` index was never used, even though it could have been. This is the planner choosing the _most selective_ index.

## 6. Why SQLite sometimes ignores an index you created

This is the practical payoff. Run this:

```sql
EXPLAIN QUERY PLAN SELECT * FROM people WHERE city = 'Tehran';
```

Before `ANALYZE`, the planner relies on its default guess (about 10 rows per match), so it will likely choose the index. After `ANALYZE`, it learns that `city = 'Tehran'` matches about a third of the table. Returning 66,667 rows through an index means 66,667 separate table lookups, jumping around the file, which can cost more than one sequential pass over the whole table. So you will likely see:

```
SCAN people
```

That is not a bug. The planner decided the scan is cheaper. **Low-selectivity columns** (few distinct values, like a boolean, a status, or a city in a small set) are usually poor index candidates for this reason.

The full list of reasons an index may not be used:

|Cause|Example|Why|
|---|---|---|
|Low selectivity|`WHERE active = 1` when 95% of rows are active|Index returns too many rows; scan is cheaper|
|Function on the column|`WHERE lower(email) = 'x'`|Tree is sorted by raw values, not function results|
|Leftmost prefix not satisfied|Index `(city, name)`, query only on `name`|No starting point in the sort order|
|Collation mismatch|Index uses `NOCASE`, query compares with default `BINARY`|Sort order differs from comparison rules|
|Leading wildcard|`LIKE '%abc'`|Not a range in the sorted order|
|Non-indexable operator|`!=`, `NOT IN`, `NOT LIKE`|Matches almost everything, no contiguous range|
|Very small table|20 rows|Scanning a page or two is already cheap|
|Type affinity mismatch|Comparing a column to a value of a different type that forces conversion|Comparison is done on converted values, not stored ones|

## 7. Keeping the planner's information fresh

Statistics are a **snapshot**. They are not updated automatically when data changes. If you load 5 million rows after running `ANALYZE`, the planner still believes the old numbers.

Two tools:

```sql
ANALYZE;            -- recompute statistics for everything
PRAGMA optimize;    -- let SQLite decide which tables actually need re-analysis
```

**What these do:** `ANALYZE` is the full recompute. `PRAGMA optimize` is the lightweight option designed to be run periodically, such as just before closing a long-lived connection, since it only analyzes tables where it judges the statistics may have gone stale.

## 8. Overriding the planner (and why to be careful)

SQLite gives you three ways to force the issue:

```sql
-- Force a specific index
SELECT * FROM people INDEXED BY idx_people_city WHERE city = 'Tehran';

-- Forbid all indexes for this table
SELECT * FROM people NOT INDEXED WHERE city = 'Tehran';

-- Disable one term's use of an index using the unary + operator
SELECT * FROM people WHERE +city = 'Tehran' AND email = 'user1@example.com';
```

**What these do:** `INDEXED BY` makes the query _fail with an error_ if that index can't be used, which makes it a debugging tool more than a tuning tool. `NOT INDEXED` forces a scan. The `+` prefix makes the term non-indexable, so the planner skips that index for it but still evaluates the condition.

Treat these as diagnostics. Hard-coding a plan means the query stops adapting when data changes. In normal work, fix the cause instead: add the right index, run `ANALYZE`, or rewrite the query.

## 9. Try it yourself

```sql
-- 1. Plan before ANALYZE
EXPLAIN QUERY PLAN SELECT * FROM people WHERE city = 'Tehran';

-- 2. Gather statistics
ANALYZE;
SELECT * FROM sqlite_stat1;

-- 3. Plan after ANALYZE
EXPLAIN QUERY PLAN SELECT * FROM people WHERE city = 'Tehran';

-- 4. A selective query for comparison
EXPLAIN QUERY PLAN SELECT * FROM people WHERE email = 'user42@example.com';
```

**What this does:** steps 1 and 3 run the same query before and after the planner has real statistics, so you can watch the decision change. Step 4 shows a selective condition still using its index. If step 3 doesn't switch to `SCAN` on your version, that's fine: the thresholds are internal estimates and vary slightly. The important thing is that `sqlite_stat1` now exists and the planner uses it.

## 10. Summary

- SQL is declarative: **you define indexes, the planner chooses** whether to use them, per statement, at prepare time.
- The planner splits `WHERE` into terms, finds indexable ones, lists candidate paths, estimates cost, and picks the cheapest.
- The deciding factor is **selectivity**: how many rows a condition matches. Few rows means index wins; many rows means a scan may win.
- Row estimates come from **built-in defaults** until you run `ANALYZE`, which stores real statistics in `sqlite_stat1`.
- `EXPLAIN QUERY PLAN` shows you the decision. `INDEXED BY`, `NOT INDEXED`, and `+` can override it, but they are for diagnosis.



[[SQlite]]