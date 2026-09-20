

# ✅ 1. **Declaring Variables**

Inside a `CREATE PROCEDURE` or `CREATE FUNCTION`, variables are declared in a **DECLARE** block.

### **Syntax**

```sql
DECLARE
    variable_name data_type [DEFAULT value];
```

### Example:

```sql
DECLARE
    total_students INT;
    avg_mark NUMERIC(5,2) DEFAULT 0;
    message TEXT DEFAULT 'Hello';
```

---

# ✅ 2. **Assigning Values**

### Method 1: `:=`

```sql
total_students := 100;
```

### Method 2: `SELECT ... INTO`

```sql
SELECT COUNT(*) INTO total_students
FROM students;
```

### Method 3: `SELECT ... INTO STRICT`

Ensures exactly **one row** returned; otherwise error.

```sql
SELECT name INTO STRICT student_name
FROM students
WHERE id = 1;
```

---

# ✅ 3. **Using Variables in a Stored Procedure**

### Full example:

```sql
CREATE PROCEDURE student_summary(country_name TEXT DEFAULT 'UK')
LANGUAGE plpgsql
AS $$
DECLARE
    total INT;
    avgmark NUMERIC(5,2);
BEGIN
    SELECT COUNT(*), AVG(mark)
    INTO total, avgmark
    FROM students
    WHERE country = country_name;

    RAISE NOTICE 'Total: %, Avg: %', total, avgmark;
END;
$$;
```

Call it:

```sql
CALL student_summary();        -- country = 'UK'
CALL student_summary('US');    -- country = 'US'
```

---

# ✅ 4. **Variable Types You Can Use**

You can use any PostgreSQL type:

- `INT`, `BIGINT`
    
- `NUMERIC`
    
- `TEXT`
    
- `DATE`, `TIMESTAMP`
    
- `BOOLEAN`
    
- `UUID`
    
- `RECORD`
    
- Custom types / table row types:
    

### Example: using a table row type

```sql
DECLARE
    stu students%ROWTYPE;
BEGIN
    SELECT * INTO stu
    FROM students
    WHERE id = 1;

    RAISE NOTICE 'Name: %, Mark: %', stu.name, stu.mark;
END;
```

---

# ✅ 5. **Local Temporary Variables**

You can create computed variables:

```sql
DECLARE
    total NUMERIC := 5 * 20;
```

---

# ✅ 6. **Boolean Variables**

```sql
DECLARE
    passed BOOLEAN;
BEGIN
    passed := TRUE;
    IF passed THEN
        RAISE NOTICE 'Passed!';
    END IF;
END;
```

---

# ✅ 7. **Control Logic Using Variables**

Loops, conditions, counters:

```sql
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 5 LOOP
        RAISE NOTICE 'i = %', i;
        i := i + 1;
    END LOOP;
END;
```




###### Tags : [[1 - SQL 🥞]]