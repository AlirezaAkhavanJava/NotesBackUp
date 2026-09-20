Filtering in MongoDB means **selecting documents that match conditions**. Think “WHERE clause”, but in document-land.

I’ll go from basics → real patterns.

---

### 1️⃣ Basic filtering (`find`)

```js
db.users.find({ age: 25 })
```

Equals only.

Multiple conditions = **AND** by default:

```js
db.users.find({ age: 25, country: "Iran" })
```

---

### 2️⃣ Comparison operators

```js
db.users.find({ age: { $gt: 18 } })   // >
db.users.find({ age: { $gte: 18 } })  // >=
db.users.find({ age: { $lt: 30 } })   // <
db.users.find({ age: { $lte: 30 } })  // <=
db.users.find({ age: { $ne: 25 } })   // !=
```

---

### 3️⃣ Logical operators

**OR**

```js
db.users.find({
  $or: [
    { role: "ADMIN" },
    { role: "MODERATOR" }
  ]
})
```

**AND (explicit)**

```js
db.users.find({
  $and: [
    { age: { $gte: 18 } },
    { active: true }
  ]
})
```

**NOT**

```js
db.users.find({ age: { $not: { $gt: 30 } } })
```

---

### 4️⃣ Arrays

```js
db.users.find({ tags: "java" }) // contains
```

Multiple required values:

```js
db.users.find({ tags: { $all: ["java", "spring"] } })
```

Any match:

```js
db.users.find({ tags: { $in: ["java", "go"] } })
```

---

### 5️⃣ Nested documents

```js
db.users.find({ "address.city": "Tehran" })
```

---

### 6️⃣ Regex (text-like filtering)

```js
db.users.find({ name: { $regex: "^Eth", $options: "i" } })
```

Starts with “Eth”, case-insensitive.

---

### 7️⃣ Filtering in aggregation

When pipelines are involved, filtering is done with `$match`.

```js
db.users.aggregate([
  { $match: { age: { $gte: 18 } } },
  { $sort: { age: -1 } },
  { $limit: 5 }
])
```

`$match` should be **as early as possible** for performance.

---

### 8️⃣ Exists & null checks

```js
db.users.find({ phone: { $exists: true } })
```

Null or missing:

```js
db.users.find({ phone: null })
```

---

### 9️⃣ Performance truth (important)

MongoDB filtering is fast **only if indexed**.

If you filter often:

```js
db.users.find({ email: "x@y.com" })
```

Create index:

```js
db.users.createIndex({ email: 1 })
```

Otherwise MongoDB scans everything. No mercy.

---

### Mental model

- `find()` = filter documents
    
- Operators = fine-grained control
    
- `$match` = filtering inside pipelines
    
- Indexes = speed
    

MongoDB doesn’t “query tables”; it **screens documents** like a bouncer checking IDs.

##### Tags : [[1 - MongoDB 🍂]]