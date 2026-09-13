
MongoDB handles **conditionals** mostly inside **queries and aggregation pipelines**. Think “if-then-else” for documents, but in JSON style.

---

## 1️⃣ Conditional **in queries** (filtering documents)

### Comparison operators (basic “conditions”)

```js
db.students.find({ gpa: { $gt: 3 } })      // gpa > 3
db.students.find({ gpa: { $gte: 4 } })     // gpa >= 4
db.students.find({ gpa: { $lt: 2 } })      // gpa < 2
db.students.find({ gpa: { $lte: 3 } })     // gpa <= 3
db.students.find({ gpa: { $ne: 3.5 } })    // gpa != 3.5
db.students.find({ gpa: { $in: [3, 4, 5] } })  // gpa = 3 OR 4 OR 5
db.students.find({ gpa: { $nin: [1, 2] } })    // gpa != 1 AND != 2
```

### Logical operators

```js
db.students.find({
  $and: [
    { gpa: { $gte: 3 } },
    { gpa: { $lte: 4 } }
  ]
})

db.students.find({
  $or: [
    { name: "SpongeBob" },
    { gpa: { $gte: 4 } }
  ]
})

db.students.find({ gpa: { $not: { $lt: 3 } } })   // NOT (gpa < 3)
```

---

## 2️⃣ Conditional **inside aggregation** (transforming documents)

### `$cond` (if-then-else)

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

Output:

```js
{ name: "Patrick", gpa: 1.4, status: "Failed" }
{ name: "Sandy", gpa: 4.2, status: "Passed" }
```

### `$ifNull`

Replace `null` with default:

```js
{ $ifNull: ["$nickname", "No Nickname"] }
```

### `$switch`

Multiple conditions:

```js
{
  $switch: {
    branches: [
      { case: { $gte: ["$gpa", 4.5] }, then: "Excellent" },
      { case: { $gte: ["$gpa", 3] }, then: "Good" }
    ],
    default: "Average"
  }
}
```

---

### 3️⃣ Mental model

- Query = “should this document pass?” → boolean conditions
    
- Aggregation = “what value should this field take?” → conditional expressions
    
- Operators: `$gt`, `$lt`, `$eq`, `$cond`, `$ifNull`, `$switch`
    

MongoDB is like **an army of tiny if-statements**, either **filtering the troops** or **decorating them with tags**.

##### Tags : [[1 - MongoDB 🍂]]