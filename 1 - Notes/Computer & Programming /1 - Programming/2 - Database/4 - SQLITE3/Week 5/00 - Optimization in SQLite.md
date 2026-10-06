
# Optimization in SQLite: Why Care About 0.86 ms?

## What optimization means

Optimization is making your queries and database use **fewer resources** (time, CPU, disk reads, memory) to get the same result. In SQLite, that mostly means making the database **read less data** to answer your question.

## "But 0.86 ms is already fast, why bother?"

You're right that **0.86 ms alone doesn't need fixing**. A good developer doesn't optimize everything. But the number is misleading, for three reasons.

**1. It's measured on small data.**  
Your test table might have 1,000 rows. Production might have 5 million. A query that scans every row (a "full table scan") gets slower as data grows:

|Rows|Time (full scan, example)|
|---|---|
|1,000|0.86 ms|
|100,000|~86 ms|
|5,000,000|~4.3 seconds|

With an index, the same lookup often stays near **0.05 ms** regardless of size.

**2. It gets multiplied.**  
One query at 0.86 ms is nothing. But:

- A page that runs 50 queries = 43 ms
- A loop that runs the query 10,000 times = 8.6 seconds
- 1,000 users at once = they queue up, because SQLite allows only **one writer at a time**

**3. Slow queries hold locks.**  
In SQLite, a slow write blocks other writes. Even a 50 ms write, repeated under load, can cause `database is locked` errors.

## Example

```sql
-- No index: SQLite checks every row
SELECT * FROM orders WHERE customer_id = 42;

-- Check what it's doing:
EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE customer_id = 42;
-- Output: SCAN orders   <-- bad: reads everything

-- Fix:
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- Now: SEARCH orders USING INDEX idx_orders_customer  <-- good
```

## What happens if you don't optimize?

- **Slow app** as data grows, users leave
- **Timeouts and `database is locked` errors** under concurrent use
- **Higher server costs** (more CPU, more hardware to compensate)
- **Painful emergency fixes** later, when the app is already live and big
- **Battery drain** on mobile apps (SQLite is common in Android/iOS)

## The right mindset

1. **Don't optimize blindly.** Measure first.
2. **Use `EXPLAIN QUERY PLAN`** to see if you're scanning or searching.
3. **Test with realistic data sizes**, not tiny samples.
4. **Fix what's slow or what will scale badly.** Ignore what's already fine.

> Rule of thumb: 0.86 ms with an index is fine. 0.86 ms with a full table scan on a table that will grow is a **warning sign**, not a success.




[[SQlite]]