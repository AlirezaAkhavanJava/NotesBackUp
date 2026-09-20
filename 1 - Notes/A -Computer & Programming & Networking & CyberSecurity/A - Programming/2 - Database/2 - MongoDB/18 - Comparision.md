
MongoDB **comparison query operators** are how you tell the database “not this exactly… but _like this_.” Think of them as calibrated lies—precise, controlled, and very useful.

Core comparison operators (used inside a query):

`$eq` — equal

```
db.users.find({ age: { $eq: 25 } })
```

`$ne` — not equal

```
db.users.find({ age: { $ne: 25 } })
```

`$gt` — greater than

```
db.users.find({ age: { $gt: 18 } })
```

`$gte` — greater than or equal

```
db.users.find({ age: { $gte: 18 } })
```

`$lt` — less than

```
db.users.find({ age: { $lt: 60 } })
```

`$lte` — less than or equal

```
db.users.find({ age: { $lte: 60 } })
```

Combine them (very common):

```
db.users.find({
  age: { $gte: 18, $lt: 60 }
})
```

Other important comparison operators people forget:

`$in` — value in a list

```
db.users.find({ role: { $in: ["ADMIN", "USER"] } })
```

`$nin` — value not in a list

```
db.users.find({ role: { $nin: ["BANNED"] } })
```

`$exists` — field exists (or not)

```
db.users.find({ email: { $exists: true } })
```

`$type` — field type

```
db.users.find({ age: { $type: "int" } })
```

Deep truth:  
• MongoDB queries are **JSON-shaped**, not SQL-shaped  
• Multiple operators on one field are **ANDed** automatically  
• Missing fields ≠ `null` (this bites people hard)

MongoDB doesn’t ask _what table_. It asks _what shape of reality do you want back_.

##### Tags : [[1 - MongoDB 🍂]]