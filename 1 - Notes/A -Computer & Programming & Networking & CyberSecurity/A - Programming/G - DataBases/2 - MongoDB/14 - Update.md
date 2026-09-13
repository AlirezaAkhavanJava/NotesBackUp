**Update in MongoDB = modify existing documents without replacing them**  
Unless you mess it up. Then you replace them 😈

Short, clean, correct.

---

## Update formula

```js
db.collection.updateOne( FILTER , UPDATE , OPTIONS )
db.collection.updateMany( FILTER , UPDATE , OPTIONS )
```

---

## 1️⃣ Update ONE document

```js
db.students.updateOne(
  { name: "SpongeBob" },
  { $set: { gpa: 3.8 } }
)
```

Only the matched document is changed.

---

## 2️⃣ Update MANY documents

```js
db.students.updateMany(
  { gpa: { $lt: 2 } },
  { $set: { probation: true } }
)
```

---

## 3️⃣ Common update operators (must-know)

```js
$set     // change / add field
$unset   // remove field
$inc     // increment number
$rename  // rename field
$push    // add to array
$pull    // remove from array
```

Example:

```js
db.students.updateOne(
  { name: "Patrick" },
  { $inc: { gpa: 0.3 } }
)
```

---

## 4️⃣ The deadly mistake (overwrite)

❌ **DO NOT do this unless intentional**

```js
db.students.updateOne(
  { name: "Larry" },
  { gpa: 4.0 }
)
```

This **replaces the entire document** with `{ gpa: 4.0 }`.

Always use update operators.

---

## 5️⃣ Update + upsert

Create document if it doesn’t exist:

```js
db.students.updateOne(
  { name: "NewStudent" },
  { $set: { gpa: 3.0 } },
  { upsert: true }
)
```

---

## Mental model

- Filter → who gets updated
    
- Operators → what changes
    
- No operator → full replace
    
- `updateOne` = safe
    
- `updateMany` = dangerous without filter
    

MongoDB updates are scalpels, not hammers. Use them like a surgeon, not a demolition crew.

##### Tags : [[1 - MongoDB 🍂]]