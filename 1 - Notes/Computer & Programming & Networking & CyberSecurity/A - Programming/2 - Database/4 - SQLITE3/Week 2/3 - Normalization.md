


**Database normalization** is the process of **organizing data in a relational database to reduce unnecessary duplication and prevent data inconsistencies**.

The main idea is:

> **Store each fact in the appropriate place, ideally once, and connect related facts using keys.**

---

## 1. What problem does normalization solve?

Consider this table:

```text
students
+----+--------+-------------+-------------+
| id | name   | course      | instructor  |
+----+--------+-------------+-------------+
| 1  | Ali    | Database    | John        |
| 2  | Sara   | Database    | John        |
| 3  | Reza   | Java        | Mike        |
+----+--------+-------------+-------------+
```

`Database → John` is repeated.

That's **data redundancy**.

Now suppose John changes his name to `Jonathan`.

You have to update every row containing `Database`.

If you update only some rows:

```text
Ali  → Database → Jonathan
Sara → Database → John
```

Now the database contradicts itself.

Normalization helps prevent this.

---

# 2. Normalized design

Instead, separate the entities:

```text
students
+----+------+
| id | name |
+----+------+
| 1  | Ali  |
| 2  | Sara |
| 3  | Reza |
+----+------+

courses
+----+----------+--------------+
| id | name     | instructor   |
+----+----------+--------------+
| 1  | Database | John         |
| 2  | Java     | Mike         |
+----+----------+--------------+

enrollments
+------------+-----------+
| student_id | course_id |
+------------+-----------+
| 1          | 1         |
| 2          | 1         |
| 3          | 2         |
+------------+-----------+
```

Now `John` exists in one appropriate place.

The relationship is represented using:

```text
students
   │
   │ student_id
   ▼
enrollments
   ▲
   │ course_id
   │
courses
```

---

# 3. What does normalization prevent?

Normalization primarily addresses three classic **data anomalies**.

### Insert anomaly

You can't insert information about a course without also providing unrelated student information.

### Update anomaly

The same fact appears in multiple rows, so changing it requires multiple updates.

### Delete anomaly

Deleting a row accidentally deletes the only record of some other fact.

For example:

```text
student | course | instructor
--------+--------+-----------
Ali     | Java   | Mike
```

If Ali drops Java and you delete this row, you might accidentally lose the fact that **Mike teaches Java**.

A normalized design separates those facts.

---

# 4. Normalization forms

Database normalization is commonly discussed in **normal forms**.

The important ones are:

|Normal Form|Main idea|
|---|---|
|**1NF**|Atomic values; no repeating groups|
|**2NF**|1NF + no partial dependency on a composite key|
|**3NF**|2NF + no transitive dependency|
|**BCNF**|Stronger version of 3NF|

For most application development, understanding **1NF → 2NF → 3NF** is essential.

---

## 5. 1NF — First Normal Form

A column should contain **atomic values**, rather than lists of values.

Bad:

```text
students
+----+------+-------------------+
| id | name | courses           |
+----+------+-------------------+
| 1  | Ali  | Java, SQL, Docker |
+----+------+-------------------+
```

`courses` contains multiple values.

Better:

```text
enrollments
+------------+-----------+
| student_id | course    |
+------------+-----------+
| 1          | Java      |
| 1          | SQL       |
| 1          | Docker    |
+------------+-----------+
```

Each cell contains one logical value.

---

# 6. 2NF — Second Normal Form

2NF matters particularly when you have a **composite primary key**.

Suppose:

```text
enrollments
+------------+-----------+--------------+
| student_id | course_id | student_name |
+------------+-----------+--------------+
```

with:

```sql
PRIMARY KEY (student_id, course_id)
```

`student_name` depends only on `student_id`, not on the entire `(student_id, course_id)` key.

That's a **partial dependency**.

So move it:

```text
students
+----+------+
| id | name |
+----+------+

enrollments
+------------+-----------+
| student_id | course_id |
+------------+-----------+
```

---

# 7. 3NF — Third Normal Form

3NF removes **transitive dependencies**.

Bad:

```text
students
+----+------+-------------+-------------+
| id | name | department  | department_head |
+----+------+-------------+-------------+
```

Suppose:

```text
student_id
    ↓
department
    ↓
department_head
```

`department_head` depends on the department, rather than directly on the student.

Separate it:

```text
students
+----+------+----------------+
| id | name | department_id  |
+----+------+----------------+

departments
+----+------+----------------+
| id | name | head           |
+----+------+----------------+
```

Now:

```text
students
    │
    │ department_id
    ▼
departments
```

---

# 8. Normalization in SQLite

Normalization isn't a special SQLite command.

You **normalize your database by designing its schema properly**.

For example:

```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE courses (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE enrollments (
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,

    PRIMARY KEY (student_id, course_id),

    FOREIGN KEY (student_id)
        REFERENCES students(id),

    FOREIGN KEY (course_id)
        REFERENCES courses(id)
);
```

This is a normalized relational design.

---

# 9. The important mental model

Think of normalization as answering:

> **"Where does this fact belong?"**

For example:

```text
Student
 ├── id
 └── name

Course
 ├── id
 └── name

Enrollment
 ├── student_id
 └── course_id
```

Each table represents a meaningful entity or relationship.

Then **primary keys and foreign keys connect them**.

So the progression you're learning in CS50 is roughly:

```text
Real-world problem
        ↓
Identify entities
        ↓
Design tables
        ↓
Define relationships
        ↓
Normalize the design
        ↓
Create schema
        ↓
Insert data
        ↓
Query with SQL
```

**Schema = the database's blueprint.**

**Normalization = a set of principles for designing that blueprint so data is organized, consistent, and minimally redundant.**


[[1 - WHAT IS SQLITE3 🍕]]
[[1 - SQL 🥞]]