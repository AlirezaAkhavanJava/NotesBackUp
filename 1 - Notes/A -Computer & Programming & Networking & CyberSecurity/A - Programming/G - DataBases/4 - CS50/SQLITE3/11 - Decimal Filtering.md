### `ROUND(number, decimals)`

```sql
ROUND(number, number_of_decimal_places)
```

> For example:

```sql
SELECT ROUND(123.456789, 2);
```

Result:

```text
123.46
```

Different amounts:

```sql
SELECT ROUND(123.456789, 0); -- 123.0
SELECT ROUND(123.456789, 1); -- 123.5
SELECT ROUND(123.456789, 2); -- 123.46
SELECT ROUND(123.456789, 3); -- 123.457
SELECT ROUND(123.456789, 4); -- 123.4568
SELECT ROUND(123.456789, 5); -- 123.45679
```

### With a column

If you have:

```sql
SELECT AVG(score)
FROM athletes;
```

You can do:

```sql
SELECT ROUND(AVG(score), 2)
FROM athletes;
```

This gives the average rounded to **2 decimal places**.

### Important distinction

`ROUND()` **rounds the numeric value**. It doesn't necessarily force SQLite's output to visually contain a fixed number of zeros.

For example:

```sql
SELECT ROUND(10.5, 3);
```

may display:

```text
10.5
```

rather than:

```text
10.500
```

If you specifically want **exactly N digits displayed after the decimal**, use `printf()`:

```sql
SELECT printf('%.3f', 10.5);
```

Result:

```text
10.500
```

So:

```text
ROUND()  → controls numeric rounding
printf() → controls how the number is displayed
```


[[1 - WHAT IS SQLITE3]]