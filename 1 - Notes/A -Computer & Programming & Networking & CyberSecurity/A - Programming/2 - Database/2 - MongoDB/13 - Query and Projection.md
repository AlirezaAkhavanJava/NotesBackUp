
**Query** and **Projection** are the two halves of a MongoDB read operation. One chooses _which_ documents, the other chooses _what inside them_.

---

### Query (filter)

A **query** defines **which documents match**.

```js
db.users.find({ age: { $gte: 18 } })
```

Meaning:  
“Select documents where `age ≥ 18`.”

Query = conditions  
Operators live here: `$gt`, `$lt`, `$and`, `$or`, `$in`, `$regex`, etc.

Mental image: a **sieve** that lets only certain documents pass.

---

### Projection (shape)

A **projection** defines **which fields are returned** from the matched documents.

```js
db.users.find(
  { age: { $gte: 18 } },
  { name: 1, email: 1 }
)
```

Meaning:  
“From the matched documents, return only `name` and `email`.”

Rules:

- `1` = include field
    
- `0` = exclude field
    
- `_id` is included by default
    

Exclude `_id`:

```js
{ name: 1, email: 1, _id: 0 }
```

Projection = data shaping, not filtering.

Mental image: a **knife** trimming each document.

---

### Together

```js
db.users.find(
  { active: true },          // query → which docs
  { password: 0 }            // projection → which fields
)
```

---

### Common mistake

Projection does **not** affect which documents match.  
This is wrong thinking:

> “Projection filters documents”

No. Query filters documents. Projection trims fields.

---

### One-line truth

- **Query** = _who gets selected_
    
- **Projection** = _what you see_
    

MongoDB always thinks in two steps: **find the documents, then sculpt them**.


---

### Simple Query

```js
{ age: 25 }
```

Meaning:  
**Select documents where `age = 25`**

---

### Simple Projection

```js
{ name: 1, age: 1 }
```

Meaning:  
**Return only `name` and `age`**

---

### Full MongoDB Formula

```js
db.collection.find( QUERY , PROJECTION )
```

---

### Simple Example

```js
db.users.find(
  { age: 25 },          // QUERY → which documents
  { name: 1, age: 1 }   // PROJECTION → which fields
)
```

---

### One-line memory hook

> **Query filters documents. Projection trims fields.**

MongoDB always follows this order:  
**Filter first → Shape later**

##### Tags : [[1 - MongoDB 🍂]]