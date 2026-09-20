
 `$cond` and `$switch` are **MongoDB aggregation operators** used to implement **conditional logic** inside pipelines. Think of them as MongoDB’s way of doing **if-then-else** (or SQL CASE) **per document**.

---

## 1️⃣ `$cond` – single if-then-else

**Definition:**  
`$cond` evaluates a **boolean expression** and returns one value if true, another if false.

**Syntax (object form):**

```js
{
  $cond: {
    if: <condition>, 
    then: <value_if_true>, 
    else: <value_if_false>
  }
}
```

**Syntax (ternary form, shorthand):**

```js
{ $cond: [ <condition>, <value_if_true>, <value_if_false> ] }
```

---

### Example 1 – Pass/Fail

Suppose we have a `students` collection:

```js
db.students.aggregate([
  {
    $project: {
      name: 1,
      gpa: 1,
      status: {
        $cond: { if: { $gte: ["$gpa", 3.5] }, then: "Passed", else: "Failed" }
      }
    }
  }
])
```

- `$gte: ["$gpa", 3.5]` → is GPA ≥ 3.5?
    
- `then: "Passed"` → if true, assign "Passed"
    
- `else: "Failed"` → if false, assign "Failed"
    

**Result:**

```js
{ name: "Sandy", gpa: 4.2, status: "Passed" }
{ name: "Patrick", gpa: 1.4, status: "Failed" }
```

---

### Example 2 – Shorthand ternary form

```js
db.students.aggregate([
  {
    $project: {
      name: 1,
      gpa: 1,
      status: { $cond: [ { $gte: ["$gpa", 3.5] }, "Passed", "Failed" ] }
    }
  }
])
```

Same result, just shorter.

---

## 2️⃣ `$switch` – multiple conditions (like multi-branch CASE)

**Definition:**  
`$switch` evaluates **multiple conditions in order** and returns the `then` of the first condition that matches. You can also define a `default` value.

**Syntax:**

```js
{
  $switch: {
    branches: [
      { case: <condition1>, then: <value1> },
      { case: <condition2>, then: <value2> },
      ...
    ],
    default: <default_value>
  }
}
```

---

### Example – GPA grading

```js
db.students.aggregate([
  {
    $project: {
      name: 1,
      gpa: 1,
      grade: {
        $switch: {
          branches: [
            { case: { $gte: ["$gpa", 4.5] }, then: "A+" },
            { case: { $gte: ["$gpa", 4.0] }, then: "A" },
            { case: { $gte: ["$gpa", 3.5] }, then: "B" },
            { case: { $gte: ["$gpa", 3.0] }, then: "C" }
          ],
          default: "D"
        }
      }
    }
  }
])
```

- Checks each branch **in order**
    
- Returns the first `then` that matches
    
- If none matches, returns `default`
    

**Result:**

```js
{ name: "Plankton", gpa: 4.9, grade: "A+" }
{ name: "Sandy", gpa: 4.2, grade: "A" }
{ name: "Patrick", gpa: 1.4, grade: "D" }
```

---

### 3️⃣ Key Points

1. `$cond` = **single decision**, simple true/false
    
2. `$switch` = **multi-decision**, multiple conditions
    
3. Both work **only in aggregation pipelines** (`$project`, `$addFields`, `$group`, etc.)
    
4. Evaluated **per document**; MongoDB never “shortcuts” other documents
    
5. `$cond` can be **nested** for more complex logic, but `$switch` is cleaner for multiple branches
    

---

### 4️⃣ Nested example (using `$cond`)

```js
db.students.aggregate([
  {
    $project: {
      name: 1,
      gpa: 1,
      remark: {
        $cond: [
          { $gte: ["$gpa", 4.0] }, 
          "Excellent", 
          { $cond: [ { $gte: ["$gpa", 3.0] }, "Good", "Needs Improvement" ] }
        ]
      }
    }
  }
])
```

- Nested `$cond` = multiple if-else
    
- `$switch` is preferred for readability
    

---

### 5️⃣ Mental model

- `$cond` = “if this, then that, else something else”
    
- `$switch` = “check multiple conditions in order, pick the first match”
    
- Both = **functional per-document logic** inside MongoDB aggregation
    

---


##### Tags : [[1 - MongoDB 🍂]]