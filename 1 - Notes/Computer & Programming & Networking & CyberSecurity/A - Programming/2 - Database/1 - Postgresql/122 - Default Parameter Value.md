
# ✅ Stored Procedure with Default Parameter Value

Yes — PostgreSQL **supports default values** in procedure parameters.

### **Syntax**

```sql
CREATE PROCEDURE procedure_name(
    param1 type DEFAULT default_value
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- logic
END;
$$;
```

---

# ✅ **Example 1 — Simple default parameter**

```sql
CREATE PROCEDURE log_message(
    msg TEXT DEFAULT 'No message provided'
)
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Message: %', msg;
END;
$$;
```

### Usage:

```sql
CALL log_message();              -- uses default
CALL log_message('Hello Ethan'); -- overrides default
```

---

# ✅ **Example 2 — Multiple parameters with defaults**

Important: **parameters with defaults must be last**.

❌ Wrong:

```sql
(a DEFAULT 10, b INT)
```

✅ Correct:

```sql
(a INT, b INT DEFAULT 10)
```

Example:

```sql
CREATE PROCEDURE add_student(
    name TEXT,
    country TEXT DEFAULT 'UK',
    active BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO students(name, country, active)
    VALUES (name, country, active);

    RAISE NOTICE 'Inserted %, country %, active %', name, country, active;
END;
$$;
```

### Usage:

```sql
CALL add_student('John');  
CALL add_student('John', 'US');  
CALL add_student('John', 'US', false);
```

---

# ✅ **Example 3 — Default SQL expression**

You can use:

- `CURRENT_DATE`
    
- `now()`
    
- `uuid_generate_v4()`
    
- Subqueries
    

```sql
CREATE PROCEDURE record_login(
    username TEXT,
    login_time TIMESTAMPTZ DEFAULT now()
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO logins(username, time)
    VALUES (username, login_time);
END;
$$;
```

---



###### Tags : [[1 - SQL 🥞]]