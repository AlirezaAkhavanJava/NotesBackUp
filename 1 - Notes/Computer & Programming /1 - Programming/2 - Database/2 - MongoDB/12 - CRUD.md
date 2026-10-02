
CRUD in MongoDB is the **four fundamental operations on documents**. No ceremony, no SQL drama.

---

## 1️⃣ Create

Insert documents.

```js
db.users.insertOne({
  name: "Ethan",
  age: 25,
  active: true
})
```

Multiple:

```js
db.users.insertMany([
  { name: "Ava", age: 22 },
  { name: "Noah", age: 30 }
])
```

MongoDB auto-creates `_id` if you don’t.

---

## 2️⃣ Read

Fetch (query) documents.

```js
db.users.find({ age: { $gte: 18 } })
```

One document:

```js
db.users.findOne({ name: "Ethan" })
```

With chaining:

```js
db.users.find({ active: true })
  .sort({ age: -1 })
  .limit(5)
```

---

## 3️⃣ Update

Modify existing documents.

Single:

```js
db.users.updateOne(
  { name: "Ethan" },
  { $set: { age: 26 } }
)
```

Multiple:

```js
db.users.updateMany(
  { active: false },
  { $set: { banned: true } }
)
```

Replace (dangerous):

```js
db.users.replaceOne(
  { _id: 1 },
  { name: "New User" }
)
```

---

## 4️⃣ Delete

Remove documents.

```js
db.users.deleteOne({ name: "Ethan" })
```

```js
db.users.deleteMany({ inactive: true })
```

---

## The real-world CRUD flow

```js
// C
insertOne()

// R
find(), findOne()

// U
updateOne(), updateMany()

// D
deleteOne(), deleteMany()
```

---

## Hard truths

- No update operator = **document overwrite**
    
- No filter in update/delete = **global damage**
    
- Indexes matter for Read & Update filters
    
- MongoDB is document-first, not table-first
    

CRUD is the alphabet. Everything else in MongoDB is just poetry written with these four letters.

#### Tags : [[1 - MongoDB 🍂]]