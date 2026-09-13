


# 🧱 **1️⃣ Formatting Dates & Times**

PostgreSQL uses **`TO_CHAR()`** to convert dates/timestamps to **formatted strings**.  
SQL Server uses **`CONVERT()`** or **`FORMAT()`**. MySQL uses **`DATE_FORMAT()`**.

---

## 🕰️ **PostgreSQL: `TO_CHAR()`**

### **Syntax**

```sql
TO_CHAR(date_or_timestamp, 'format_string')
```

|Format Pattern|Meaning|Example|
|---|---|---|
|`YYYY`|4-digit year|`2025`|
|`YY`|2-digit year|`25`|
|`MM`|Month number (01–12)|`10`|
|`Mon`|Short month|`Oct`|
|`Month`|Full month|`October`|
|`DD`|Day of month|`18`|
|`DY`|Abbreviated day name|`Sat`|
|`Day`|Full day name|`Saturday`|
|`HH24`|Hour (0–23)|`14`|
|`HH12`|Hour (1–12)|`2`|
|`MI`|Minutes|`37`|
|`SS`|Seconds|`52`|
|`MS`|Milliseconds|`481`|
|`AM/PM`|12-hour format|`PM`|

**Example:**

```sql
SELECT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS') AS formatted;
-- 2025-10-18 14:37:52
```

---


# 🧱 **2️⃣ Casting Dates & Times**

Casting is converting **between types**, e.g., `string → date`, `timestamp → date`, `date → string`.

---

## 🐘 **PostgreSQL Casting**

|Operation|Syntax|Example|Result|
|---|---|---|---|
|String → Date|`TO_DATE(string, format)`|`TO_DATE('2025-10-18','YYYY-MM-DD')`|`2025-10-18`|
|String → Timestamp|`TO_TIMESTAMP(string, format)`|`TO_TIMESTAMP('2025-10-18 14:37','YYYY-MM-DD HH24:MI')`|`2025-10-18 14:37:00`|
|Timestamp → Date|`timestamp::date`|`NOW()::date`|`2025-10-18`|
|Date → Timestamp|`date::timestamp`|`'2025-10-18'::timestamp`|`2025-10-18 00:00:00`|
|Date/TS → Text|`TO_CHAR(date, 'format')`|`TO_CHAR(NOW(),'YYYY-MM-DD')`|`'2025-10-18'`|
|Text → Interval|`INTERVAL '1 day'`|`'1 day'::interval`|`1 day`|

**Alternative cast syntax:**

```sql
CAST('2025-10-18' AS DATE)
CAST(NOW() AS DATE)
```

---


## 🧩 **3️⃣ Rules & Best Practices**

1. Always **store dates in `DATE` or `TIMESTAMP`** — not strings.
    
2. Use **ISO format** `'YYYY-MM-DD'` for text → date conversions.
    
3. `TO_CHAR()` produces **text** — cannot be used directly in date math without casting back.
    
4. `TO_DATE()` / `TO_TIMESTAMP()` can **fail on invalid strings** — validate or use `TRY_CAST` in SQL Server.
    
5. Casting with `::type` in PostgreSQL is equivalent to `CAST(value AS type)`.
    
6. Use **`DATE_TRUNC()`** before formatting if you need uniform precision.
    
7. When formatting, **24-hour vs 12-hour** matters (`HH24` vs `HH12`).
    
8. Timezones are **ignored in text formatting** unless you use `'TZ'` or `timestamptz`.
    

---

## 🔧 **4️⃣ Example Combo Queries**

### PostgreSQL:

```sql
SELECT
    NOW() AS original_ts,
    NOW()::date AS date_only,
    TO_CHAR(NOW(), 'YYYY-MM-DD') AS formatted_date,
    TO_CHAR(NOW(), 'FMDay, Month DD YYYY HH24:MI:SS') AS readable
```


---





### Tags : [[1 - SQL 🥞]]