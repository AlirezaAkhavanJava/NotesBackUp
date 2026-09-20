
**PostgreSQL does NOT have `try/catch` keywords**, but it _does_ have the equivalent using PL/pgSQL blocks.

The PostgreSQL equivalent of:

`try {    ... } catch (Exception e) {    ... }`

is this:

`BEGIN     -- try EXCEPTION     WHEN ... THEN         -- catch END;`

That **is** the try/catch mechanism in PostgreSQL.  
The keywords are different, but the behavior is the same.

---
# ✅ 1. Basic Error Handling With `EXCEPTION`

PostgreSQL uses a `BEGIN … EXCEPTION … END` block.

### **Template**

```sql
BEGIN
    -- risky code
EXCEPTION
    WHEN some_error THEN
        -- recovery
END;
```

You can catch errors like:

- `unique_violation`
    
- `foreign_key_violation`
    
- `division_by_zero`
    
- `no_data_found`
    
- `too_many_rows`
    
- `others`
    

---

# ✅ 2. Practical Example: Catch a Unique Constraint Error

```sql
CREATE PROCEDURE add_student(p_name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO students(name)
    VALUES (p_name);

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Student "%" already exists.', p_name;
END;
$$;
```

---

# ✅ 3. Catch Multiple Errors

```sql
EXCEPTION
    WHEN unique_violation OR foreign_key_violation THEN
        RAISE NOTICE 'Constraint error: %', SQLERRM;
```

---

# ✅ 4. Access Error Details

Inside an exception block:

- `SQLSTATE` → 5-character error code
    
- `SQLERRM` → error message
    

Example:

```sql
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error code: %, Message: %', SQLSTATE, SQLERRM;
```

---

# ✅ 5. Using `RAISE` for Custom Errors

### Levels:

- `NOTICE` (info)
    
- `WARNING`
    
- `EXCEPTION` (throw error)
    

### Throw your own error:

```sql
IF new_mark < 0 THEN
    RAISE EXCEPTION 'Mark cannot be negative: %', new_mark;
END IF;
```

This stops execution.

---

# ✅ 6. Transaction Behavior in Procedures vs Functions

### **Procedures**

✔ can do `COMMIT` / `ROLLBACK`  
✔ can catch errors and continue

### **Functions**

❌ cannot use transaction control  
✔ can still catch errors with `EXCEPTION`

---

# ✅ 7. Full Realistic Example

A safer update procedure that catches errors and logs them:

```sql
CREATE PROCEDURE update_mark(
    sid INT,
    new_mark INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    old_mark INT;
BEGIN
    SELECT mark INTO STRICT old_mark
    FROM students
    WHERE id = sid;

    UPDATE students
    SET mark = new_mark
    WHERE id = sid;

    RAISE NOTICE 'Updated student %, % -> %', sid, old_mark, new_mark;

EXCEPTION
    WHEN no_data_found THEN
        RAISE NOTICE 'Student ID % does not exist.', sid;

    WHEN others THEN
        RAISE NOTICE 'Unexpected error (%): %', SQLSTATE, SQLERRM;
END;
$$;
```

---

# 🔥 8. Use `EXCEPTION` Inside Nested Blocks

You can isolate dangerous logic:

```sql
BEGIN
    -- part 1
    BEGIN
        -- risky part
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'Inner block failed';
    END;

    -- part 2
END;
```

---

# 🚀 9. Catch Division-by-Zero Example

```sql
BEGIN
    result := 10 / x;
EXCEPTION
    WHEN division_by_zero THEN
        result := 0;
END;
```



###### Tags : [[1 - SQL 🥞]]