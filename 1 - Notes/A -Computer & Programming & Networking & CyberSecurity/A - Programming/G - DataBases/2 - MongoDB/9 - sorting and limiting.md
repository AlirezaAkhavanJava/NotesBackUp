
MongoDB sorting + limiting is simple, but there are two **contexts** where people get confused: **find()** vs **aggregate()**. Let’s slice it cleanly.

---

### 1️⃣ Sorting & limiting with `find()`

This is the everyday query path.

```js
db.users.find()
  .sort({ age: -1 })   // -1 = descending, 1 = ascending
  .limit(5)
```

Meaning:  
“Give me **5 users**, sorted by **age descending** (oldest first).”

Multiple fields are allowed:

```js
db.users.find()
  .sort({ age: -1, name: 1 })
  .limit(10)
```

MongoDB sorts by `age` first, then by `name` if ages match.

---

### 2️⃣ Sorting & limiting with `aggregate()`

Used when you need **pipelines**, transformations, joins, grouping, etc.

```js
db.users.aggregate([
  { $sort: { age: -1 } },
  { $limit: 5 }
])
```

Pipeline order **matters**.  
`$sort` must come **before** `$limit`, or MongoDB will limit first and then sort fewer docs (wrong result).

---

### 3️⃣ Real-world example

“Top 3 most expensive products”

```js
db.products.find()
  .sort({ price: -1 })
  .limit(3)
```

Or aggregation version:

```js
db.products.aggregate([
  { $sort: { price: -1 } },
  { $limit: 3 }
])
```

---

### 4️⃣ Performance rule (important)

Sorting is **expensive** without an index.

If you do this often:

```js
.sort({ createdAt: -1 })
```

Create an index:

```js
db.posts.createIndex({ createdAt: -1 })
```

Otherwise MongoDB sorts in memory and may spill to disk (slow).

---

### Mental model

- `sort()` = order the documents
    
- `limit()` = cut the list
    
- **Sort first, limit second**
    
- Indexes make sorting fast
    

MongoDB is not magical — it just lines documents up and chops the line ✂️

###### Tags : [[1 - MongoDB 🍂]]