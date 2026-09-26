

# 🧭 **SQL & PostgreSQL Date & Time Functions — Full Cheat Sheet**

---

## 🧱 **1️⃣ Date & Time Data Types**

|SQL Standard / General|PostgreSQL|Description|Example|
|---|---|---|---|
|`DATE`|`DATE`|Only date|`'2025-10-18'`|
|`TIME`|`TIME`|Time of day|`'14:25:00'`|
|`DATETIME`|`TIMESTAMP`|Date + time (no tz)|`'2025-10-18 14:25:00'`|
|`DATETIMEOFFSET`|`TIMESTAMPTZ`|Date + time + timezone|`'2025-10-18 14:25:00+03'`|
|`INTERVAL`|`INTERVAL`|Time span (duration)|`'3 days 5 hours'`|

---

## 🕒 **2️⃣ Current Date & Time**

|SQL|PostgreSQL|Description|Example Result|
|---|---|---|---|
|`GETDATE()`|`NOW()`|Current date + time|`2025-10-18 14:25:00+03`|
|`SYSDATE()`|`CURRENT_TIMESTAMP`|System timestamp|same as above|
|`CURRENT_DATE`|`CURRENT_DATE`|Current date only|`2025-10-18`|
|`CURRENT_TIME`|`CURRENT_TIME`|Current time only|`14:25:00+03`|
|`LOCALTIMESTAMP`|`LOCALTIMESTAMP`|Timestamp (no tz)|`2025-10-18 14:25:00`|
|—|`STATEMENT_TIMESTAMP()`|Time at query start|same|
|—|`TRANSACTION_TIMESTAMP()`|Time transaction began|same|
|—|`CLOCK_TIMESTAMP()`|Real clock time (changes mid-query)|same|

---

## 📆 **3️⃣ Extracting Parts (Day, Month, Year, etc.)**

|SQL|PostgreSQL|Example|Result|
|---|---|---|---|
|`YEAR(date)`|`EXTRACT(YEAR FROM date)`|`EXTRACT(YEAR FROM NOW())`|`2025`|
|`MONTH(date)`|`EXTRACT(MONTH FROM date)`|`EXTRACT(MONTH FROM NOW())`|`10`|
|`DAY(date)` / `DAYOFMONTH(date)`|`EXTRACT(DAY FROM date)`|`EXTRACT(DAY FROM NOW())`|`18`|
|`HOUR(timestamp)`|`EXTRACT(HOUR FROM timestamp)`|—|`14`|
|`MINUTE(timestamp)`|`EXTRACT(MINUTE FROM timestamp)`|—|`25`|
|`SECOND(timestamp)`|`EXTRACT(SECOND FROM timestamp)`|—|`00`|
|`WEEK(date)`|`EXTRACT(WEEK FROM date)`|—|`42`|
|`DAYOFWEEK(date)`|`EXTRACT(DOW FROM date)`|—|`6` (0=Sunday)|
|`DAYOFYEAR(date)`|`EXTRACT(DOY FROM date)`|—|`291`|
|`QUARTER(date)`|`EXTRACT(QUARTER FROM date)`|—|`4`|
|—|`DATE_PART('field', date)`|Alt syntax|same result|

---

## ➕ **4️⃣ Date Arithmetic**

|SQL|PostgreSQL|Example|Result|
|---|---|---|---|
|`DATEADD(day, 5, date)`|`date + INTERVAL '5 days'`|`NOW() + INTERVAL '5 days'`|adds 5 days|
|`DATEADD(month, 2, date)`|`date + INTERVAL '2 months'`|—|adds 2 months|
|`DATEDIFF(day, start, end)`|`end::date - start::date`|`'2025-10-20' - '2025-10-18'`|`2`|
|—|`AGE(end, start)`|`AGE(NOW(), '2024-10-18')`|`1 year`|
|—|`make_interval(days => 10)`|`NOW() + make_interval(days => 10)`|add 10 days|
|—|`JUSTIFY_DAYS(interval)`|normalize (e.g. 30 days → 1 month)|—|

---

## 🧮 **5️⃣ Formatting & Parsing**

|SQL|PostgreSQL|Example|Result|
|---|---|---|---|
|`CONVERT(varchar, date, style)`|`TO_CHAR(date, format)`|`TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS')`|`'2025-10-18 14:25:00'`|
|`CAST(string AS DATE)`|`TO_DATE(string, format)`|`TO_DATE('2025-10-18','YYYY-MM-DD')`|date value|
|`STR_TO_DATE(string, format)`|`TO_TIMESTAMP(string, format)`|`TO_TIMESTAMP('2025-10-18 14:25','YYYY-MM-DD HH24:MI')`|timestamp value|
|—|`TO_CHAR(date, 'FMDay, Mon DD YYYY')`|—|`'Sat, Oct 18 2025'`|
|—|`DATE_TRUNC('month', date)`|truncate to start of month|`2025-10-01 00:00:00`|

---

## 📏 **6️⃣ Comparison, Ranges, and Checks**

|SQL|PostgreSQL|Example|
|---|---|---|
|`WHERE date BETWEEN '2025-01-01' AND '2025-12-31'`|same|filters range|
|`WHERE date1 < GETDATE()`|`WHERE date1 < NOW()`|past records|
|`WHERE MONTH(date) = 10`|`WHERE EXTRACT(MONTH FROM date) = 10`|filter October|
|`EOMONTH(date)`|`(date_trunc('month', date) + INTERVAL '1 month' - INTERVAL '1 day')::date`|end of month|

---

## 📅 **7️⃣ Named Conversions & Date Names**

|SQL|PostgreSQL|Example|Result|
|---|---|---|---|
|`DATENAME(dw, date)`|`TO_CHAR(date, 'FMDay')`|`TO_CHAR(NOW(),'FMDay')`|`'Saturday'`|
|`MONTHNAME(date)`|`TO_CHAR(date, 'FMMonth')`|—|`'October'`|
|`FORMAT(date, 'MMMM dd, yyyy')`|`TO_CHAR(date, 'Month DD, YYYY')`|—|`'October 18, 2025'`|

---

## 🌍 **8️⃣ Time Zones**

|SQL|PostgreSQL|Example|Result|
|---|---|---|---|
|—|`AT TIME ZONE`|`NOW() AT TIME ZONE 'UTC'`|UTC timestamp|
|—|`SET TIME ZONE 'Asia/Tehran';`|change session tz|affects NOW()|
|—|`timezone('America/New_York', timestamp)`|convert manually|—|

---

## 🧠 **9️⃣ Construction & Validation**

|SQL|PostgreSQL|Example|
|---|---|---|
|—|`MAKE_DATE(YYYY,MM,DD)`|`MAKE_DATE(2025,10,18)`|
|—|`MAKE_TIMESTAMP(YYYY,MM,DD,HH,MI,SS)`|`MAKE_TIMESTAMP(2025,10,18,14,30,0)`|
|`ISDATE(string)`|Regex or TRY_CAST check|`'2025-10-18' ~ '^\d{4}-\d{2}-\d{2}$'`|

---

## 🔢 **10️⃣ Interval & Age**

|SQL|PostgreSQL|Example|Result|
|---|---|---|---|
|`TIMESTAMPDIFF(unit, start, end)`|`AGE(end, start)`|`AGE('2025-10-18','2020-10-18')`|`5 years`|
|—|`EXTRACT(EPOCH FROM (end - start))`|difference in seconds||
|—|`(end::date - start::date)`|difference in days||
|—|`JUSTIFY_INTERVAL()`|normalize interval||

---

## ⚙️ **11️⃣ Rules You Must Remember**

1. `GETDATE()` ≈ `NOW()` (but with tz in PostgreSQL).
    
2. Use **INTERVAL** for time math; integers only work with `DATE`.
    
3. `BETWEEN` is **inclusive** on both sides.
    
4. `AGE()` gives **years, months, days** — not numeric.
    
5. `EXTRACT()` gives **numbers**, `TO_CHAR()` gives **text**.
    
6. `DATE_TRUNC()` rounds _down_ to start of unit (month, day, hour, etc.).
    
7. **NULL dates** break math; use `COALESCE(date, NOW())` to protect.
    
8. **TIMESTAMPTZ** auto-adjusts for timezone; **TIMESTAMP** doesn’t.
    
9. Avoid using `EXTRACT()` directly in WHERE for indexed columns (it prevents index usage).
    
10. `TO_DATE()` / `TO_TIMESTAMP()` **throw error on invalid text** — validate before use.
    

---

## 🧮 **12️⃣ Example Combo Query**

```sql
SELECT 
    id,
    TO_CHAR(order_date, 'YYYY-MM-DD') AS formatted_date,
    EXTRACT(YEAR FROM order_date) AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month,
    (NOW() - order_date)::interval AS age_interval,
    (NOW()::date - order_date::date) AS days_passed,
    order_date + INTERVAL '7 days' AS delivery_estimate,
    TO_CHAR(order_date, 'FMDay, Month DD YYYY') AS readable
FROM orders
WHERE order_date BETWEEN CURRENT_DATE - INTERVAL '90 days' AND CURRENT_DATE;
```

---

✅ **Covers every major function:**

- Current time
    
- Extraction
    
- Math
    
- Formatting
    
- Conversion
    
- Timezones
    
- Intervals
    
- Validation
    
---

# 🧱 **1️⃣ What `DATE_TRUNC()` Does**

`DATE_TRUNC()` **rounds or "truncates"** a date/time value to a specific **precision level** — e.g. to the start of the year, month, day, hour, etc.

It **zeroes out** all smaller time components.

---

### 🧩 **Syntax**

```sql
DATE_TRUNC(field, source)
```

|Parameter|Description|
|---|---|
|`field`|The precision level to keep (e.g. `'year'`, `'month'`, `'day'`, `'hour'`, etc.)|
|`source`|A date, timestamp, or timestamptz value|

🧠 Returns:

- **`timestamp`** if input is `timestamp`
    
- **`timestamptz`** if input is `timestamptz`
    

---

# 🕒 **2️⃣ Example: Basic Usage**

```sql
SELECT
    NOW() AS original,
    DATE_TRUNC('year', NOW()) AS start_of_year,
    DATE_TRUNC('month', NOW()) AS start_of_month,
    DATE_TRUNC('day', NOW()) AS start_of_day,
    DATE_TRUNC('hour', NOW()) AS start_of_hour;
```

|Result|
|---|
|original → `2025-10-18 14:37:52.481123+03`|
|year → `2025-01-01 00:00:00+03`|
|month → `2025-10-01 00:00:00+03`|
|day → `2025-10-18 00:00:00+03`|
|hour → `2025-10-18 14:00:00+03`|

---

# 📆 **3️⃣ Supported Truncation Fields**

|Field|Meaning|Example Result|
|---|---|---|
|`'microseconds'`|Keep microsecond precision|`2025-10-18 14:37:52.481000`|
|`'milliseconds'`|Keep milliseconds|`2025-10-18 14:37:52.000000`|
|`'second'`|Zero out below seconds|`2025-10-18 14:37:52`|
|`'minute'`|Round to start of minute|`2025-10-18 14:37:00`|
|`'hour'`|Start of hour|`2025-10-18 14:00:00`|
|`'day'`|Midnight that day|`2025-10-18 00:00:00`|
|`'week'`|Start of week (Sunday)|`2025-10-12 00:00:00`|
|`'month'`|First of month|`2025-10-01 00:00:00`|
|`'quarter'`|First day of quarter|`2025-10-01 00:00:00`|
|`'year'`|Jan 1st that year|`2025-01-01 00:00:00`|
|`'decade'`|2020-01-01|Start of decade|
|`'century'`|2001-01-01|Start of century|
|`'millennium'`|2001-01-01|Start of millennium|

---

# ⚙️ **4️⃣ Common Use Cases**

### ✅ **a) Grouping by Month or Year**

```sql
SELECT
  DATE_TRUNC('month', order_date) AS month,
  COUNT(*) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;
```

→ Gives monthly totals — all dates truncated to 1st of each month.

---

### ✅ **b) Daily Aggregation**

```sql
SELECT
  DATE_TRUNC('day', created_at) AS day,
  COUNT(*) AS new_users
FROM users
GROUP BY day
ORDER BY day;
```

---

### ✅ **c) Weekly Reports**

```sql
SELECT
  DATE_TRUNC('week', sale_date) AS week_start,
  SUM(amount) AS total_sales
FROM sales
GROUP BY week_start;
```

🧠 **PostgreSQL weeks start on Sunday** — adjust with `SET datestyle` or add `+ INTERVAL '1 day'` if needed.

---

### ✅ **d) Combine with INTERVAL**

```sql
WHERE created_at >= DATE_TRUNC('day', NOW() - INTERVAL '7 days');
```

→ last 7 full days only.

---

# 🧩 **5️⃣ SQL Server / MySQL Equivalent**

|Purpose|PostgreSQL|SQL Server Equivalent|
|---|---|---|
|Truncate to day|`DATE_TRUNC('day', date)`|`CAST(CONVERT(date, GETDATE()) AS datetime)`|
|Truncate to month|`DATE_TRUNC('month', date)`|`DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)`|
|Truncate to year|`DATE_TRUNC('year', date)`|`DATEADD(year, DATEDIFF(year, 0, GETDATE()), 0)`|

⚙️ MySQL ≥ 8.0.13 has:

```sql
DATE_TRUNC('month', NOW());
```

(but fewer field options than PostgreSQL)

---

# 🧠 **6️⃣ Rules to Remember**

|Rule|Explanation|
|---|---|
|🧩 Truncates _down_ — never rounds up.||
|⏱ Works on `timestamp` and `timestamptz`.||
|🕒 Time zone matters for `timestamptz`.||
|📆 `week` starts on Sunday (0).||
|🧮 Can be nested inside other functions (e.g. `TO_CHAR(DATE_TRUNC('month', date), 'Mon YYYY')`).||
|⚙️ Useful for GROUP BY on time periods.||
|🧱 Returns **timestamp**, not text — use `TO_CHAR()` if you want formatted output.||
|🚫 No direct SQL standard equivalent — PostgreSQL-only (MySQL & SQL Server use workarounds).||

---

# 🔧 **7️⃣ Advanced Tricks**

### 🔹 Find start of previous month:

```sql
DATE_TRUNC('month', NOW()) - INTERVAL '1 month';
```

### 🔹 Find start of current week (Monday-based):

```sql
DATE_TRUNC('week', NOW() + INTERVAL '1 day') - INTERVAL '1 day';
```

### 🔹 Truncate timestamps in reports:

```sql
SELECT DATE_TRUNC('hour', event_time) AS hour_bucket, COUNT(*) FROM logs GROUP BY hour_bucket;
```

### 🔹 Round to quarter hour:

```sql
DATE_TRUNC('hour', ts) + INTERVAL '15 min' * FLOOR(EXTRACT(MINUTE FROM ts) / 15)
```

---

# 🧩 **8️⃣ Quick Reference**

|Field|Example Output|
|---|---|
|`'minute'`|`2025-10-18 14:37:00`|
|`'hour'`|`2025-10-18 14:00:00`|
|`'day'`|`2025-10-18 00:00:00`|
|`'week'`|`2025-10-12 00:00:00`|
|`'month'`|`2025-10-01 00:00:00`|
|`'quarter'`|`2025-10-01 00:00:00`|
|`'year'`|`2025-01-01 00:00:00`|

---

# 🔥 **9️⃣ Real-World Example: Time Bucketed Stats**

```sql
SELECT
  DATE_TRUNC('hour', login_time) AS hour,
  COUNT(*) AS total_logins
FROM user_logins
WHERE login_time >= NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour;
```

→ Produces one row per hour for the last 24 hours, counting logins.



### Tags : [[1 - SQL 🦬]]