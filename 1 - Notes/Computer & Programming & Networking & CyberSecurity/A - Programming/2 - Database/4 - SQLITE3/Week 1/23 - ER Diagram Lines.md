
![[Pasted image 20260909165228.png]]


The **lines are the most important part of an ER diagram**, because they tell you how rows in different entities can be related.

Let's use **Crow's Foot notation**, which is very common in database diagrams.

## 1. First, identify the entities

An ER diagram usually starts with boxes:

```text
┌──────────────┐          ┌──────────────┐
│    USER      │          │    POST      │
├──────────────┤          ├──────────────┤
│ PK id        │          │ PK id        │
│ username     │          │ FK user_id   │
│ email        │          │ title        │
└──────────────┘          └──────────────┘
```

Each box represents an **entity**, which usually becomes a table.

Then look at the **line connecting the boxes**.

---

# 2. The symbols at the ends of lines

In Crow's Foot notation, you mainly need to understand these symbols:

```text
|       O       <
│       ○       <
one    zero    many
```

More precisely:

|Symbol|Meaning|
|---|---|
|`|`|
|`O`|Zero / optional|
|`<` / crow's foot|Many|

The symbols can be combined.

---

# 3. `|────|` = One-to-One

```text
┌────────┐       ┌────────┐
│ USER   │ |───| │ PROFILE│
└────────┘       └────────┘
```

Read it as:

> One USER is related to exactly one PROFILE.

And:

> One PROFILE is related to exactly one USER.

Therefore:

```text
USER 1 ───── 1 PROFILE
```

---

# 4. `|────<` = One-to-Many

This is probably the **most important relationship to recognize**.

```text
┌────────┐       ┌────────┐
│ USER   │ |────<│ POST   │
└────────┘       └────────┘
```

Read the line **from left to right**:

```text
USER |────< POST
     1      N
```

Meaning:

> One USER can have many POSTs.

For example:

```text
User 1
 ├── Post 1
 ├── Post 2
 ├── Post 3
 └── Post 4
```

In SQLite, this usually looks like:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
);
```

Notice that the **foreign key is on the MANY side**:

```text
USER                 POST
id  ◄──────────────  user_id
1                     1
                      1
                      1
                      1
```

---

# 5. `O────<` = Zero-to-Many

```text
┌────────┐       ┌────────┐
│ USER   │ O────<│ POST   │
└────────┘       └────────┘
```

The `O` means **zero is allowed**.

So this can mean:

> A USER can have zero or many POSTs.

Therefore:

```text
USER 0..N POST
```

Example:

```text
User 1 → Post 1
       → Post 2

User 2 → nothing

User 3 → Post 3
       → Post 4
       → Post 5
```

---

# 6. `|────O` = One-to-Zero-or-One

```text
┌────────┐       ┌────────┐
│ USER   │ |────O│ PROFILE│
└────────┘       └────────┘
```

This means:

```text
USER 1 ───── 0..1 PROFILE
```

A user must exist, but they **may or may not have a profile**.

For example:

```text
User 1 → Profile 1
User 2 → nothing
User 3 → Profile 3
```

This is useful for optional relationships.

---

# 7. `O────|` = Zero-or-One to One

This is the reverse perspective:

```text
┌────────┐       ┌────────┐
│ PROFILE│ O────|│ USER   │
└────────┘       └────────┘
```

Read:

```text
PROFILE 0..1 ─── 1 USER
```

The same relationship can therefore look different depending on which entity you're reading from.

---

# 8. `O────O` = Zero-to-Zero-or-One

```text
┌────────┐       ┌────────┐
│ A      │ O────O│ B      │
└────────┘       └────────┘
```

This represents an optional relationship on both sides:

```text
A 0..1 ───── 0..1 B
```

Neither side necessarily needs the other.

---

# 9. `|────<` is NOT the same as `O────<`

This distinction is important.

### `|────<`

```text
USER |────< POST
```

means:

```text
1 ─── N
```

The USER side is **exactly one**.

### `O────<`

```text
USER O────< POST
```

means:

```text
0 ─── N
```

The USER side is **optional**.

The circle `O` changes the minimum cardinality from **1 to 0**.

---

# 10. How to read a line correctly

Don't think of the entire line as one symbol.

Instead, inspect **each end independently**.

For example:

```text
USER O────────| POST
     ↑        ↑
     │        │
     │        └── exactly 1
     └─────────── zero or one
```

Therefore:

```text
USER 0..1 ─── 1 POST
```

Another example:

```text
USER |────────< POST
     ↑          ↑
     │          │
     1          many
```

Therefore:

```text
USER 1 ─── N POST
```

---

# 11. The Crow's Foot itself

This:

```text
<
```

is called a **crow's foot** because it looks like one:

```text
     <
    / \
```

It means:

> **Many**

So:

```text
USER ──────< POST
```

means:

```text
USER → many POSTs
```

And:

```text
COURSE ──────< STUDENT
```

would mean one COURSE is associated with many STUDENT rows.

---

# 12. Many-to-Many

Here's an important one:

```text
┌──────────┐              ┌──────────┐
│ STUDENT  │ O──────────< │ COURSE   │
└──────────┘              └──────────┘
```

Be careful: a direct `N:M` relationship usually needs a **junction table** in the actual relational database.

The ER model becomes:

```text
STUDENT
   │
   │ 1
   │
   │ N
   ▼
ENROLLMENT
   ▲
   │ N
   │
   │ 1
 COURSE
```

SQLite:

```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY
);

CREATE TABLE courses (
    id INTEGER PRIMARY KEY
);

CREATE TABLE enrollment (
    student_id INTEGER,
    course_id INTEGER,

    PRIMARY KEY (student_id, course_id),

    FOREIGN KEY (student_id)
        REFERENCES students(id),

    FOREIGN KEY (course_id)
        REFERENCES courses(id)
);
```

This is how:

```text
Student 1 ──┐
Student 2 ──┼── Enrollment ──┬── Course 1
Student 3 ──┘                └── Course 2
```

implements **many-to-many**.

---

# 13. The mental model I recommend

When you see an ER diagram, read it in this order:

```text
1. Find the ENTITY
        ↓
2. Find its PRIMARY KEY
        ↓
3. Find the relationship line
        ↓
4. Look at the symbol on EACH end
        ↓
5. Determine minimum
   (0 or 1)
        ↓
6. Determine maximum
   (1 or many)
        ↓
7. Translate it into:
   1:1
   1:N
   N:M
```

For example:

```text
┌────────┐                    ┌────────┐
│ USER   │ O────────────────< │ POST   │
└────────┘                    └────────┘
     ↑                             ↑
     │                             │
     0                            many
```

You translate that into:

```text
USER 0..N POST
```

Then ask:

> "Which table contains the foreign key?"

Usually:

```text
users.id
   ▲
   │
   │ FK
   │
posts.user_id
```

And you've gone from the **visual database model → relational model → SQLite implementation**.

### Cheat sheet

```text
|────|    = 1 : 1
|────<    = 1 : N
O────|    = 0..1 : 1
O────<    = 0..1 : N
O────O    = 0..1 : 0..1
```

The two concepts to master are **cardinality** (how many?) and **optionality/participation** (is zero allowed?). Once those click, ER diagrams become much easier to read.



[[1 - WHAT IS SQLITE3 🍕]]