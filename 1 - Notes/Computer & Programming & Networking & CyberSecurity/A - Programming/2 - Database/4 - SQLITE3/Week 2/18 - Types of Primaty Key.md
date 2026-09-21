

## 1. Simple Primary Key

A primary key consisting of **one column**.

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL
);
```

Here:

```sql
id INTEGER PRIMARY KEY
```

`id` uniquely identifies each row.

---

## 2. Composite Primary Key

A primary key consisting of **two or more columns**.

```sql
CREATE TABLE enrollments (
    student_id INTEGER,
    course_id INTEGER,

    PRIMARY KEY (student_id, course_id)
);
```

The **combination** must be unique.

```text
student_id | course_id
-----------+----------
1          | 10        ✓
1          | 20        ✓
2          | 10        ✓
1          | 10        ✗ duplicate
```

Neither column needs to be unique by itself.

This is probably the type you meant by **"joint"** — the correct term is **composite primary key**.

---

## 3. Natural Primary Key

A value that already exists naturally in the real-world data.

Example:

```sql
CREATE TABLE countries (
    country_code TEXT PRIMARY KEY,
    name TEXT NOT NULL
);
```

Here `country_code` such as `US`, `DE`, or `IR` can naturally identify a country.

---

## 4. Surrogate Primary Key

An artificially generated identifier whose purpose is simply to identify the row.

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL
);
```

The `id` doesn't represent any meaningful property of the user. It's just an identifier.

This is extremely common in application databases.

---

### The important distinction

```text
Primary Key
│
├── Simple PK
│   └── one column
│
└── Composite PK
    └── multiple columns
```

And separately, **how the key gets its value**:

```text
Primary Key
│
├── Natural Key
│   └── meaningful real-world value
│
└── Surrogate Key
    └── artificially generated ID
```

So **composite** describes the **structure** of the key, while **natural/surrogate** describes the **nature/origin of its value**.


[[1 - WHAT IS SQLITE3 🍕]]