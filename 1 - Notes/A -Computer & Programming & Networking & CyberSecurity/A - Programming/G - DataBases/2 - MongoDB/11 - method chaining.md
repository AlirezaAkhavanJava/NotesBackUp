
In MongoDB, **method chaining** mostly happens on a **cursor** (the object returned by `find()` or `aggregate()`).

Below is the **complete, practical list** you’ll actually use.

---

## 1️⃣ `find()` chaining (most common)

```js
db.collection.find(query, projection)
```

You can chain these **cursor methods**:

```js
.sort()
.limit()
.skip()
.project()     // projection (alternative to 2nd param)
.count()       // deprecated, but still seen
.explain()
.hint()
.collation()
.batchSize()
```

### Full example

```js
db.users.find({ active: true })
  .project({ name: 1, age: 1 })
  .sort({ age: -1 })
  .skip(10)
  .limit(5)
```

Execution order:  
**filter → project → sort → skip → limit**

---

## 2️⃣ Projection methods

Either inline:

```js
db.users.find({}, { name: 1, age: 1 })
```

Or chained:

```js
db.users.find().project({ name: 1, age: 1 })
```

---

## 3️⃣ `aggregate()` chaining

Aggregation is already a chain — but as **pipeline stages**:

```js
db.users.aggregate([
  { $match: {} },
  { $project: {} },
  { $sort: {} },
  { $skip: 0 },
  { $limit: 0 },
  { $group: {} },
  { $lookup: {} },
  { $unwind: {} }
])
```

Cursor methods can still be chained **after** aggregation:

```js
db.users.aggregate([...])
  .explain()
```

---

## 4️⃣ `update` methods (NOT real chaining)

Updates don’t chain like queries. You pass **operators** instead:

```js
db.users.updateOne(
  { _id: 1 },
  { 
    $set: { name: "Ethan" },
    $inc: { loginCount: 1 }
  }
)
```

No `.sort()`, `.limit()`, `.skip()` here.

---

## 5️⃣ `delete` methods

No chaining beyond filter:

```js
db.users.deleteOne({ age: { $lt: 18 } })
db.users.deleteMany({ inactive: true })
```

---

## 6️⃣ Cursor helpers

```js
.forEach()
.toArray()
.hasNext()
.next()
```

Example:

```js
db.users.find().forEach(u => print(u.name))
```

---

## Mental model (important)

- `find()` → returns a **cursor**
    
- Cursor → supports **method chaining**
    
- `aggregate()` → pipeline first, cursor second
    
- `update/delete` → **no chaining**, only operators
    

MongoDB chaining is not magic — it’s just **configuring a cursor before execution**.

##### Tags : [[1 - MongoDB 🍂]]