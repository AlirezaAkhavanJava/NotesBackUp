


## 1. What is a duplicate index?

**Duplicate indexes** are indexes that cover **the same columns in the same order with the same method**, making one of them useless.

### Exact duplicate (100% waste)

```sql
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_user_email_2 ON users(email);
```

---

## 2. Functional duplicates (more subtle)

### Prefix duplicates

```sql
CREATE INDEX idx_a_b ON t(a, b);
CREATE INDEX idx_a ON t(a);
```

👉 `idx_a` is usually redundant (unless special use cases).

---

### Same columns, different names

```sql
CREATE INDEX idx1 ON orders(customer_id);
CREATE INDEX idx2 ON orders(customer_id);
```

---

### Same index type + condition

```sql
CREATE INDEX idx_active_1 ON users(email) WHERE active = true;
CREATE INDEX idx_active_2 ON users(email) WHERE active = true;
```

---

## 3. What is NOT a duplicate

❌ Different order:

```sql
(a, b) ≠ (b, a)
```

❌ Different method:

```sql
btree ≠ gin
```

❌ Different predicate:

```sql
WHERE active = true ≠ WHERE active = false
```

❌ UNIQUE vs non-unique (behavior differs)

---

## 4. Why duplicates are bad (no sugarcoating)

- Slower INSERT / UPDATE / DELETE
    
- Wasted disk space
    
- Longer VACUUM / REINDEX
    
- Zero read benefit
    

---

## 5. Detect exact duplicates (SQL)

```sql
SELECT
  t.relname AS table,
  array_agg(i.relname) AS duplicate_indexes
FROM pg_index x
JOIN pg_class t ON t.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
GROUP BY t.relname, x.indkey, x.indclass, x.indpred
HAVING COUNT(*) > 1;
```

---

## 6. Detect redundant prefix indexes

```sql
SELECT
  indrelid::regclass AS table,
  indexrelid::regclass AS index,
  indkey
FROM pg_index
ORDER BY indrelid, indkey;
```

Look for:

- `(a)` and `(a,b)`
    
- Same table
    
- Same index method
    

---

## 7. Check usage before deleting

```sql
SELECT
  indexrelname,
  idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;
```

⚠️ Zero scans **does not always mean safe** (rare queries, constraints).

---

## 8. Safe removal strategy

1. Identify duplicate
    
2. Confirm functional replacement exists
    
3. Verify usage stats
    
4. Drop **one at a time**
    
5. Monitor query plans
    

```sql
DROP INDEX CONCURRENTLY idx_user_email_2;
```

---

## 9. Production rules (hard truth)

- One index = one purpose
    
- Composite indexes replace single-column ones
    
- Never duplicate UNIQUE constraints
    
- Always keep the **most selective** index
    

---

## 10. Monitoring checklist

- Monthly index review
    
- Track `idx_scan`
    
- Watch index size vs usage
    
- Re-evaluate after schema changes
    

---

### Bottom line

Duplicate indexes are **silent performance killers**.  
If two indexes answer the same question, one of them **must go**.



##### Tags : [[1 - SQL 🥞]]