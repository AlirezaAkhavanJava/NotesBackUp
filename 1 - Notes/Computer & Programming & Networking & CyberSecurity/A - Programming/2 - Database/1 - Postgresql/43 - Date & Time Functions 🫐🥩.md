

## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

**Date & Time functions** let you handle **dates, times, and timestamps** — you can extract parts, compare, calculate intervals, and format them.

PostgreSQL supports these data types:

- `DATE` → only date (e.g., `2025-10-18`)
    
- `TIME` → only time (e.g., `14:25:00`)
    
- `TIMESTAMP` → date + time
    
- `TIMESTAMPTZ` → timestamp with timezone
    
- `INTERVAL` → duration (e.g., `3 days`, `2 hours`)
    

---

### 🔹 Basic Functions

|Function|Description|Example|Output|
|---|---|---|---|
|`CURRENT_DATE`|Current date|`SELECT CURRENT_DATE;`|`2025-10-18`|
|`CURRENT_TIME`|Current time|`SELECT CURRENT_TIME;`|`14:26:15.1234`|
|`CURRENT_TIMESTAMP` or `NOW()`|Current date & time|`SELECT NOW();`|`2025-10-18 14:26:15.1234+03:30`|
|`AGE(date1, date2)`|Difference as interval|`AGE('2025-01-01', '2020-01-01')`|`5 years`|
|`EXTRACT(field FROM source)`|Extract part of date/time|`EXTRACT(YEAR FROM NOW())`|`2025`|
|`DATE_PART(field, source)`|Same as `EXTRACT`|`DATE_PART('month', NOW())`|`10`|

---

## ⚙️ **2. INTERMEDIATE LEVEL**

### 🔹 Date Arithmetic

You can **add or subtract intervals** or **dates** directly:

```sql
SELECT NOW() + INTERVAL '7 days';  -- 7 days later
SELECT NOW() - INTERVAL '2 hours'; -- 2 hours earlier
SELECT DATE '2025-10-18' + 10;     -- 10 days later
```

### 🔹 Interval Creation

```sql
SELECT INTERVAL '1 year 3 months 5 days';
```

You can also multiply intervals:

```sql
SELECT INTERVAL '1 day' * 5;  -- 5 days
```

---

### 🔹 Date Comparison

```sql
SELECT *
FROM orders
WHERE order_date BETWEEN '2025-01-01' AND '2025-12-31';
```

---

### 🔹 Conversion & Formatting

|Function|Description|Example|Output|
|---|---|---|---|
|`TO_CHAR(timestamp, format)`|Format date/time as string|`TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI')`|`'2025-10-18 14:27'`|
|`TO_DATE(string, format)`|Convert string to date|`TO_DATE('18-10-2025','DD-MM-YYYY')`|`2025-10-18`|
|`TO_TIMESTAMP(string, format)`|Convert string to timestamp|`TO_TIMESTAMP('2025-10-18 14:27','YYYY-MM-DD HH24:MI')`|`2025-10-18 14:27:00`|

---

## 🧠 **3. ADVANCED LEVEL (PostgreSQL-specific)**

### 🔹 Extracting Parts

```sql
SELECT
    EXTRACT(YEAR FROM NOW())   AS year,
    EXTRACT(MONTH FROM NOW())  AS month,
    EXTRACT(DAY FROM NOW())    AS day,
    EXTRACT(DOW FROM NOW())    AS weekday,
    EXTRACT(HOUR FROM NOW())   AS hour;
```

### 🔹 Date Truncation

Rounds a timestamp to a specified precision.

```sql
SELECT DATE_TRUNC('month', NOW());  -- '2025-10-01 00:00:00'
SELECT DATE_TRUNC('day', NOW());    -- '2025-10-18 00:00:00'
```

### 🔹 Time Zone Conversion

```sql
SELECT NOW() AT TIME ZONE 'UTC';         -- Convert to UTC
SELECT NOW() AT TIME ZONE 'America/New_York'; -- Convert to EST
```

### 🔹 Extracting Interval Components

```sql
SELECT EXTRACT(DAY FROM INTERVAL '2 years 3 months 5 days'); -- 5
```

---

### 🔹 Nested Examples

```sql
SELECT
  TO_CHAR(DATE_TRUNC('month', NOW()), 'Month YYYY') AS current_month;
```

Explanation:

1. `NOW()` → full timestamp
    
2. `DATE_TRUNC('month', NOW())` → first day of the month
    
3. `TO_CHAR(..., 'Month YYYY')` → formatted string
    

---

## ⚔️ **4. RULES & PITFALLS**

|Rule|Explanation|
|---|---|
|⚠ **Timezone awareness**|`TIMESTAMP` has no timezone; `TIMESTAMPTZ` adjusts to client zone.|
|📅 **Implicit casting**|`'2025-01-01'` → automatically cast to `DATE`. Use explicit types for clarity.|
|⏱ **Math with intervals**|Works with both DATE and TIMESTAMP; integers add days to DATE.|
|🧩 **Formatting tokens**|Format patterns must match your string exactly when using `TO_DATE()` / `TO_TIMESTAMP()`.|
|🚫 **NULL handling**|Same as other functions — operations with NULL result in NULL.|
|💡 **Truncation vs Extraction**|`DATE_TRUNC` modifies precision; `EXTRACT` just reads a field.|
|🔢 **DATE vs TIMESTAMP math**|Subtracting two `TIMESTAMP`s gives an `INTERVAL`; subtracting `DATE`s gives integer days.|

---

## 🚀 **5. REAL-WORLD USE CASES**

### 1️⃣ Get users registered this month

```sql
SELECT * FROM users
WHERE DATE_TRUNC('month', registration_date) = DATE_TRUNC('month', NOW());
```

### 2️⃣ Calculate user age

```sql
SELECT name, AGE(NOW(), birth_date) AS age FROM users;
```

### 3️⃣ Format for reports

```sql
SELECT TO_CHAR(order_date, 'DD Mon YYYY HH24:MI') AS formatted_date FROM orders;
```

### 4️⃣ Find orders older than 30 days

```sql
SELECT * FROM orders
WHERE order_date < NOW() - INTERVAL '30 days';
```

### 5️⃣ Group by month

```sql
SELECT DATE_TRUNC('month', order_date) AS month, SUM(total)
FROM orders
GROUP BY 1
ORDER BY month;
```

---

## 📋 **6. Quick Cheat Sheet**

|Category|Function|Example|Output|
|---|---|---|---|
|Current Date/Time|`CURRENT_DATE`, `NOW()`|`NOW()`|`2025-10-18 14:27:00+03:30`|
|Extraction|`EXTRACT`, `DATE_PART`|`EXTRACT(YEAR FROM NOW())`|`2025`|
|Arithmetic|`+`, `-`, `INTERVAL`|`NOW() + INTERVAL '1 day'`|tomorrow|
|Formatting|`TO_CHAR`, `TO_DATE`, `TO_TIMESTAMP`|`TO_CHAR(NOW(),'YYYY-MM-DD')`|`'2025-10-18'`|
|Truncation|`DATE_TRUNC`|`DATE_TRUNC('month', NOW())`|`'2025-10-01'`|
|Comparison|`BETWEEN`, `<`, `>`|`order_date BETWEEN ...`|boolean|
|Aggregation|`GROUP BY DATE_TRUNC('month', date)`|—|monthly summary|

---

🐐 **Mental model:**  
Date/time functions are your **temporal Swiss Army knife** — extract, format, shift, and compare time in any way.  
They’re critical for **reporting**, **analytics**, and **time-based logic**.


## 🧱 **1️⃣ Basics — Date & Time Data Types**

|Type|Description|Example|
|---|---|---|
|`DATE`|Only date (year-month-day)|`2025-10-18`|
|`TIME`|Only time (hours-minutes-seconds)|`15:30:45`|
|`TIMESTAMP`|Date + time (no timezone)|`2025-10-18 15:30:45`|
|`TIMESTAMPTZ`|Date + time + timezone|`2025-10-18 15:30:45+03`|
|`INTERVAL`|Duration or difference|`3 days 5 hours`|

---

## 🕒 **2️⃣ Current Date & Time**

|Function|Description|Example|Result|
|---|---|---|---|
|`CURRENT_DATE`|Returns current date|—|`2025-10-18`|
|`CURRENT_TIME`|Current time|—|`15:32:00+03`|
|`CURRENT_TIMESTAMP`|Date + time + tz|—|`2025-10-18 15:32:00+03`|
|`LOCALTIMESTAMP`|Date + time (no tz)|—|`2025-10-18 15:32:00`|
|`NOW()`|Same as current_timestamp|—|same|
|`TIMEOFDAY()`|Text form of current time|—|`Sat Oct 18 15:32:00 2025 +0330`|
|`STATEMENT_TIMESTAMP()`|Timestamp when current SQL started|—|same|
|`CLOCK_TIMESTAMP()`|Actual current time (changes mid-query)|—|same|
|`TRANSACTION_TIMESTAMP()`|Time transaction began|—|same|

---

## 📆 **3️⃣ Extracting Parts**

|Function|Description|Example|Result|
|---|---|---|---|
|`EXTRACT(field FROM source)`|Extracts part|`EXTRACT(YEAR FROM NOW())`|`2025`|
|Supported fields:|YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, DOW (0=Sunday), DOY (day of year), QUARTER|—|—|
|Shortcut|`DATE_PART('year', timestamp)`|`DATE_PART('month', NOW())`|`10`|

---

## 🧮 **4️⃣ Date Arithmetic**

|Operation|Example|Result|
|---|---|---|
|Add interval|`NOW() + INTERVAL '7 days'`|adds 7 days|
|Subtract interval|`NOW() - INTERVAL '2 hours'`|subtracts 2 hours|
|Date difference|`'2025-10-20'::DATE - '2025-10-18'::DATE`|`2 days`|
|Combine interval|`INTERVAL '1 day' + INTERVAL '2 hours'`|`1 day 2 hours`|

---

## 🧭 **5️⃣ Formatting Dates**

|Function|Description|Example|Result|
|---|---|---|---|
|`TO_CHAR(timestamp, format)`|Converts to text|`TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS')`|`'2025-10-18 15:32:00'`|
|`TO_DATE(text, format)`|Parse text to date|`TO_DATE('2025-10-18', 'YYYY-MM-DD')`|`2025-10-18`|
|`TO_TIMESTAMP(text, format)`|Parse text to timestamp|`TO_TIMESTAMP('2025-10-18 15:30', 'YYYY-MM-DD HH24:MI')`|full timestamp|

🧩 **Common Format Patterns:**

|Code|Meaning|
|---|---|
|`YYYY`|Year|
|`MM`|Month|
|`DD`|Day|
|`HH24`|Hour (24h)|
|`MI`|Minute|
|`SS`|Second|
|`DY`|Abbrev weekday|
|`MONTH`|Full month name|

---

## 🔄 **6️⃣ Comparison & Ranges**

|Example|Description|
|---|---|
|`WHERE order_date BETWEEN '2025-01-01' AND '2025-12-31'`|Range check|
|`WHERE EXTRACT(MONTH FROM order_date) = 10`|Filter October|
|`WHERE order_date < NOW()`|Past records|
|`WHERE order_date > CURRENT_DATE + INTERVAL '7 days'`|Future dates|

---

## ⚙️ **7️⃣ Age & Intervals**

|Function|Description|Example|Result|
|---|---|---|---|
|`AGE(timestamp1, timestamp2)`|Difference in years, months, days|`AGE(NOW(), '2020-10-18')`|`5 years`|
|`JUSTIFY_DAYS(interval)`|Normalizes 30 days → 1 month|`JUSTIFY_DAYS(INTERVAL '60 days')`|`2 mons`|
|`JUSTIFY_HOURS(interval)`|Converts 24h → 1 day|`JUSTIFY_HOURS(INTERVAL '48 hours')`|`2 days`|
|`JUSTIFY_INTERVAL(interval)`|Normalizes both days + months|—|—|

---

## 📏 **8️⃣ Rules to Remember**

1. **Always cast text → date/time** using `::DATE` or `TO_DATE()`.
    
2. `CURRENT_DATE` returns date **without time**.
    
3. `NOW()` includes **time zone** if server configured so.
    
4. **Date arithmetic uses INTERVAL**, not integers.
    
5. `AGE()` returns composite interval (years, mons, days).
    
6. `BETWEEN` is inclusive of both ends.
    
7. **Never store timestamps as TEXT** — you’ll lose sorting accuracy.
    
8. `TIMESTAMPTZ` adjusts automatically for timezone changes.
    

---

## 🧠 **9️⃣ Pro Practice Example**

```sql
SELECT
    id,
    TO_CHAR(order_date, 'Mon DD, YYYY') AS formatted_date,
    EXTRACT(DOW FROM order_date) AS day_of_week,
    AGE(NOW(), order_date) AS time_since_order,
    order_date + INTERVAL '5 days' AS estimated_delivery
FROM orders
WHERE order_date > CURRENT_DATE - INTERVAL '30 days';
```

✅ Shows:

- formatted date
    
- weekday extraction
    
- age
    
- date arithmetic
    
- recent 30-day filter
---

# Common functions → PostgreSQL equivalents

### Current time / now

- `GETDATE()` (SQL Server) → `NOW()` (Postgres)
    
    ```sql
    SELECT NOW();
    ```
    
- `SYSDATE()` (Oracle) → `CURRENT_TIMESTAMP` / `NOW()`
    
- `CURRENT_DATE`, `CURRENT_TIME`, `CURRENT_TIMESTAMP` — standard (Postgres supported)
    

---

### Day / Month / Year / Hour / Minute / Second

- `DAY(date)` / `DAYOFMONTH(date)` → `EXTRACT(DAY FROM date)` or `DATE_PART('day', date)`
    
- `MONTH(date)` → `EXTRACT(MONTH FROM date)` or `DATE_PART('month', date)`
    
- `YEAR(date)` → `EXTRACT(YEAR FROM date)` or `DATE_PART('year', date)`
    
- `HOUR(date)` → `EXTRACT(HOUR FROM timestamp)`
    
- `MINUTE(date)` → `EXTRACT(MINUTE FROM timestamp)`
    
- `SECOND(date)` → `EXTRACT(SECOND FROM timestamp)`
    

Examples:

```sql
SELECT 
  EXTRACT(DAY FROM order_date)   AS day,
  EXTRACT(MONTH FROM order_date) AS month,
  EXTRACT(YEAR FROM order_date)  AS year
FROM orders;
```

---

### DATEADD / DATE_SUB / ADDDATE / DATE_ADD (SQL Server / MySQL)

- No `DATEADD` function in Postgres — use `+ INTERVAL` or `make_interval()` or `interval` arithmetic:
    

```sql
-- add 7 days
SELECT order_date + INTERVAL '7 days' FROM orders;

-- add months with make_interval
SELECT order_date + make_interval(months => 3) FROM orders;
```

Equivalent to `DATEADD(day, 7, order_date)` → `order_date + INTERVAL '7 days'`.

---

### DATEDIFF (SQL Server) — difference in units

- Postgres: `end::date - start::date` gives integer days. For other units use `EXTRACT(EPOCH FROM (end - start))` or `AGE()` and then convert.
    

```sql
-- days
SELECT (end_date::date - start_date::date) AS days_diff FROM t;

-- seconds
SELECT EXTRACT(EPOCH FROM (end_ts - start_ts)) AS seconds_diff FROM t;

-- months (approx) using AGE()
SELECT (DATE_PART('year', age(end_date, start_date)) * 12 + DATE_PART('month', age(end_date, start_date))) AS months_diff
FROM t;
```

---

### EOMONTH (SQL Server)

- Postgres equivalent:
    

```sql
SELECT (date_trunc('month', d) + INTERVAL '1 month' - INTERVAL '1 day')::date AS month_end
FROM (SELECT '2025-10-18'::date AS d) s;
```

---

### DATENAME / DATEPART (SQL Server)

- `DATENAME(part, date)` → `TO_CHAR(date, format)` or `EXTRACT` for numeric parts.
    

```sql
-- name of weekday
SELECT TO_CHAR(order_date, 'Day') FROM orders;

-- numeric Month
SELECT DATE_PART('month', order_date) FROM orders;
```

---

### TO_DATE, TO_TIMESTAMP, STR_TO_DATE

- Postgres: `TO_DATE(string, format)` for date; `TO_TIMESTAMP(string, format)` for timestamp.
    

```sql
SELECT TO_DATE('18-10-2025', 'DD-MM-YYYY');
SELECT TO_TIMESTAMP('2025-10-18 14:00','YYYY-MM-DD HH24:MI');
```

---

### FORMAT / STRING conversion (DATENAME-like)

- `FORMAT` / `DATENAME` equivalents:
    

```sql
SELECT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS') AS ts_str;
SELECT TO_CHAR(order_date, 'FMDay') AS weekday_name FROM orders;
```

---

### ISDATE / TRY_PARSE / TRY_CONVERT

- Postgres doesn’t have a built-in `ISDATE` — validate using regex or safe-parse functions (or write wrapper that uses `to_timestamp` in exception block).  
    Example validate (simple ISO check):
    

```sql
SELECT '2025-10-18' ~ '^\d{4}-\d{2}-\d{2}$' AS looks_like_iso_date;
```

For robust parsing, create a PL/pgSQL function that attempts `TO_TIMESTAMP` in `BEGIN...EXCEPTION WHEN others THEN ...` and returns boolean.

---

### MAKE_DATE / MAKE_TIMESTAMP (constructors)

- Postgres has helpers:
    

```sql
SELECT make_date(2025,10,18); -- date
SELECT make_timestamp(2025,10,18,14,30,0); -- timestamp
```

---

### AGE / TIMESTAMPDIFF

- `AGE(timestamp1, timestamp2)` returns an interval with years/months/days:
    

```sql
SELECT AGE(NOW(), '1990-01-01'::date) AS age_interval;
```

- To get numeric difference in days: `(later::date - earlier::date)`
    

---

### DATE_TRUNC

- Round/truncate to time unit (month/day/hour):
    

```sql
SELECT DATE_TRUNC('month', NOW());  -- first moment of current month
```

---

### Timezone conversions

- `AT TIME ZONE` to convert between timezones:
    

```sql
SELECT (timestamp_with_time_zone AT TIME ZONE 'UTC') AS utc_ts;
SELECT (timestamp_without_tz AT TIME ZONE 'Europe/London') AT TIME ZONE 'UTC' AS converted;
```

---

### Special functions you might expect

- `WEEK()` (MySQL) → derive with `EXTRACT(week FROM date)` or `DATE_PART('week', date)`
    
- `QUARTER()` → `EXTRACT(QUARTER FROM date)` or `DATE_PART('quarter', date)`
    
- `DAYNAME()` / `MONTHNAME()` → `TO_CHAR(date,'FMDay')`, `TO_CHAR(date,'FMMonth')`
    
- `ISOWEEK` variants → `EXTRACT(ISODOW|WEEK FROM date)` etc.
    

---

# Examples mapping — quick cheat examples

```sql
-- GETDATE() -> NOW()
SELECT NOW();

-- DAY(col) -> EXTRACT
SELECT EXTRACT(DAY FROM created_at) FROM t;

-- DATEADD(day, 5, col) -> col + interval
SELECT created_at + INTERVAL '5 days' FROM t;

-- DATEDIFF(day, a, b) -> b::date - a::date
SELECT (end_date::date - start_date::date) AS days_between FROM t;

-- EOMONTH(col) 
SELECT (date_trunc('month', col) + INTERVAL '1 month' - INTERVAL '1 day')::date AS eom FROM t;

-- DATENAME(dw,col) -> TO_CHAR
SELECT TO_CHAR(col,'Day') FROM t;

-- ISDATE(str) -> regex or try-parse function
SELECT '2025-10-18' ~ '^\d{4}-\d{2}-\d{2}$' AS looks_like_date;
```

---

# Gotchas / Rules you must know

1. **Dialect differences** — functions named in SQL Server/MySQL/Oracle often don’t exist in Postgres; learn Postgres equivalents.
    
2. **Integer vs interval math** — adding an integer to a `DATE` adds days, but for `TIMESTAMP` prefer `INTERVAL`.
    
3. **Timezones** — `TIMESTAMP` has no timezone; `TIMESTAMPTZ` does. `NOW()` returns a timetz-aware value.
    
4. **Datediff months/years** — tricky because months vary in length; use `AGE()` for year/month components.
    
5. **Parsing errors** — `TO_DATE`/`TO_TIMESTAMP` can throw errors on bad input; protect with validation or `EXCEPTION`.
    
6. **Week definitions differ** — `WEEK`, `ISOWEEK`, `DATE_PART('week',...)` can return different week numbers depending on ISO rules.
    
7. **Performance** — functions in WHERE (like `EXTRACT(...)`) may prevent index use; prefer range checks (`col BETWEEN '2025-01-01' AND '2025-01-31'`) when possible.
    

---


#### Tags : [[1 - SQL 🥞]]