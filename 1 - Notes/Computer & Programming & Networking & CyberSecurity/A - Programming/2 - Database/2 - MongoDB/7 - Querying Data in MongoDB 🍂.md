### Querying Data in MongoDB

MongoDB uses the `find()` method to query documents in a collection. It returns a **cursor** (you can iterate over it or convert to an array).

#### Basic Syntax
```javascript
db.collection.find(query, projection)
```
- **query**: A document specifying the filter criteria (like WHERE in SQL). `{}` means match all documents.
- **projection** (optional): Specifies which fields to return (like SELECT in SQL).

#### Examples in mongosh (MongoDB Shell)

Assume we have a collection `users` with these documents:
```javascript
{ _id: 1, name: "Alice", age: 28, city: "New York", active: true }
{ _id: 2, name: "Bob", age: 35, city: "Chicago", active: false }
{ _id: 3, name: "Charlie", age: 28, city: "New York", active: true }
```

1. **Find all documents**
   ```javascript
   db.users.find()
   ```
   Or prettified:
   ```javascript
   db.users.find().pretty()
   ```

2. **Find documents matching a condition**
   ```javascript
   // All users from New York
   db.users.find({ city: "New York" }).pretty()
   
   // Users older than 30
   db.users.find({ age: { $gt: 30 } }).pretty()
   
   // Active users
   db.users.find({ active: true }).pretty()
   ```

2. **Common Query Operators**


   | Operator       | Meaning                  | Example                              |
   |----------------|--------------------------|--------------------------------------|
   | `$eq`          | Equals                   | `{ age: { $eq: 28 } }`               |
   | `$gt`          | Greater than             | `{ age: { $gt: 30 } }`               |
   | `$gte`         | Greater than or equal    | `{ age: { $gte: 28 } }`              |
   | `$lt` / `$lte` | Less than / ≤            | `{ age: { $lt: 30 } }`               |
   | `$ne`          | Not equal                | `{ city: { $ne: "Chicago" } }`       |
   | `$in`          | In array                 | `{ city: { $in: ["New York", "LA"] } }` |
   | `$nin`         | Not in array             | `{ city: { $nin: ["Chicago"] } }`    |
   | `$and`         | Logical AND              | `{ $and: [{ age: { $gt: 25 } }, { active: true }] }` |
   | `$or`          | Logical OR               | `{ $or: [{ city: "New York" }, { age: 35 }] }` |


4. **Query on embedded fields and arrays**
   Assume a document:
   ```javascript
   {
     name: "Alice",
     address: { street: "123 Main", zip: "10001" },
     hobbies: ["reading", "cycling"]
   }
   ```
   ```javascript
   // Embedded field
   db.users.find({ "address.zip": "10001" })
   
   // Array contains value
   db.users.find({ hobbies: "reading" })
   
   // Array contains all values
   db.users.find({ hobbies: { $all: ["reading", "cycling"] } })
   ```

5. **Projection: Select specific fields**
   ```javascript
   // Return only name and age (exclude _id)
   db.users.find({}, { name: 1, age: 1, _id: 0 }).pretty()
   
   // Exclude city field
   db.users.find({}, { city: 0 }).pretty()
   ```

6. **Sorting, Limiting, and Skipping**
   ```javascript
   // Sort by age descending, then name ascending
   db.users.find().sort({ age: -1, name: 1 }).pretty()
   
   // Limit to 2 results
   db.users.find().limit(2)
   
   // Skip first 2 results (for pagination)
   db.users.find().skip(2)
   
   // Combine: page 2, 5 items per page, sorted by name
   db.users.find().sort({ name: 1 }).skip(5).limit(5)
   ```

7. **Count documents**
   ```javascript
   db.users.countDocuments({ city: "New York" })  // Preferred in newer versions
   // or
   db.users.find({ city: "New York" }).count()   // Deprecated
   ```

8. **Find one document only**
   ```javascript
   db.users.findOne({ name: "Alice" })
   ```

These examples work in **mongosh**, the MongoDB Shell, and are similar in drivers (Node.js, Python, etc.), though syntax varies slightly by language.

For more advanced queries (aggregation, text search, geospatial), check the official MongoDB docs: https://www.mongodb.com/docs/manual/tutorial/query-documents/

##### Tags : [[1 - MongoDB 🍂]]