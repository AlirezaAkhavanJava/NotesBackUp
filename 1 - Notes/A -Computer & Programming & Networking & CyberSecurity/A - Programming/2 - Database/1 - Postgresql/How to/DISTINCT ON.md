
The DISTINCT ON clause **retrieves the first unique entry from each column or combination of columns in a result set**. The key factor for determining which unique entry is selected lies in the columns that appear in the ORDER BY clause

```SQL
SELECT DISTINCT ON (country) country 
FROM students
```

The **`**DISTINCT ON**`** clause in ****PostgreSQL**** allows us to retrieve unique rows based on specific columns by offering more flexibility than the standard **`**DISTINCT**`** clause. **`**DISTINCT ON**`** allow us to specify which row to keep for each unique value based on an **`**ORDER BY**`** clause.


#### SELECT DISTINCT ON expressions must match initial ORDER BY expressions

> ⚠️ **Problem:** In PostgreSQL, when you use `DISTINCT ON (column)`, the `ORDER BY` must **include the same columns in the same order** as the DISTINCT. Otherwise, it can behave unexpectedly.





[[1 - SQL 🥞]]