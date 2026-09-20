
In PostgreSQL, you rename a table using **`ALTER TABLE ... RENAME TO`**.

### Syntax:

```sql
ALTER TABLE old_table_name RENAME TO new_table_name;
```

### Example:

```sql
ALTER TABLE student RENAME TO students_archive;
```

✅ Explanation:

- `ALTER TABLE student` → the table you want to rename.
    
- `RENAME TO students_archive` → the new table name.
    
- **Data, columns, indexes, and constraints remain intact**.
    

---

[[1 - SQL 🥞]]
