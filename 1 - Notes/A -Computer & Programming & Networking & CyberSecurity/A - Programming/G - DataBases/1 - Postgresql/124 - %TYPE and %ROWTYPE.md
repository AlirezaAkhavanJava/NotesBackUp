# ✅ 1. `%TYPE` — Match the Type of a Column or Variable

**Purpose:** Create a variable with **the exact same data type** as an existing table column or another variable.

### Why use it?

- If the column type changes later (e.g., `VARCHAR(50)` → `TEXT`), your procedure won’t break.
    
- Avoids duplicated type definitions.
    
- Clean, future-proof code.
    

### Example: simple usage

```sql
DECLARE
    student_name students.name%TYPE;
    student_mark students.mark%TYPE;
```

If `students.name` is `VARCHAR(100)`, then `student_name` becomes `VARCHAR(100)` automatically.

---

# Example in a Procedure

```sql
CREATE PROCEDURE get_student(IN sid INT)
LANGUAGE plpgsql
AS $$
DECLARE
    name students.name%TYPE;
    mark students.mark%TYPE;
BEGIN
    SELECT s.name, s.mark
    INTO name, mark
    FROM students s
    WHERE s.id = sid;

    RAISE NOTICE 'Name: %, Mark: %', name, mark;
END;
$$;
```

---

# 👍 Useful patterns with `%TYPE`

### Reference another variable’s type:

```sql
DECLARE
    a INT;
    b a%TYPE; -- same type as a
```

### Using with expressions:

```sql
DECLARE
    new_mark students.mark%TYPE := 0;
```

---

# ✅ 2. `%ROWTYPE` — Match an Entire Table Row

**Purpose:** Create a variable that represents a full **row structure** of a table or view.

Meaning:  
One variable with all the table's columns inside it.

### Example:

```sql
DECLARE
    stu students%ROWTYPE;
```

`stu` now has:

```
stu.id
stu.name
stu.mark
stu.country
stu.active
...
```

All with correct data types automatically.

---

# Example: load a full row

```sql
DECLARE
    stu students%ROWTYPE;
BEGIN
    SELECT *
    INTO stu
    FROM students
    WHERE id = 1;

    RAISE NOTICE 'Name: %, Mark: %', stu.name, stu.mark;
END;
```

---

# 💡 Tip: `%ROWTYPE` is perfect when:

- You want many columns from a table.
    
- You want to return a complex row structure.
    
- You want type safety without listing each column manually.
    

---

# 🎯 `%TYPE` vs `%ROWTYPE` — Quick Comparison

|Feature|`%TYPE`|`%ROWTYPE`|
|---|---|---|
|Matches data type of|One column / variable|Entire row (all columns)|
|Use for|One field|Many fields|
|Prevents break when table type changes?|Yes|Yes|
|Example|`students.name%TYPE`|`students%ROWTYPE`|

---

# 🔥 Advanced Example — Combine `%ROWTYPE` and `%TYPE`

```sql
DECLARE
    stu students%ROWTYPE;
    q students.country%TYPE;
BEGIN
    SELECT * INTO stu
    FROM students
    WHERE id = 1;

    q := stu.country;

    RAISE NOTICE 'Country: %', q;
END;
```


###### Tags : [[1 - SQL 🥞]]