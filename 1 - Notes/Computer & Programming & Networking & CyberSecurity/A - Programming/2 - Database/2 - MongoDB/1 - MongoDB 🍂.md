

----

# MongoDB – Complete Notes (Basic to Advanced)

### 1. **Introduction**

- MongoDB is a **NoSQL database** that stores data in **flexible, JSON-like documents** called **BSON** (Binary JSON).
    
- Unlike relational databases (tables, rows), MongoDB uses **collections** (similar to tables) and **documents** (similar to rows).
    
- Good for applications with **dynamic schemas** or **unstructured data**.
    

---

### 2. **Basic Concepts**

|Term|Explanation|
|---|---|
|**Database**|A container for collections (like a folder).|
|**Collection**|A group of documents (like a table).|
|**Document**|A JSON-like object with key-value pairs (like a row).|
|**Field**|A key in a document (like a column).|
|**_id**|Unique identifier for each document (auto-generated if not provided).|

**Example Document:**

```json
{
  "_id": 1,
  "name": "Ethan",
  "age": 28,
  "skills": ["Java", "Spring", "MongoDB"],
  "address": { "city": "Berlin", "country": "Germany" }
}
```

---

### 3. **Basic CRUD Operations**

#### a) Create (Insert)

```javascript
// Insert one document
db.users.insertOne({ name: "Ethan", age: 28 });

// Insert many documents
db.users.insertMany([
  { name: "Alice", age: 25 },
  { name: "Bob", age: 30 }
]);
```

#### b) Read (Find)

```javascript
// Find all documents
db.users.find();

// Find with condition
db.users.find({ age: { $gt: 26 } });

// Find specific fields only
db.users.find({}, { name: 1, _id: 0 });
```

#### c) Update

```javascript
// Update one document
db.users.updateOne({ name: "Ethan" }, { $set: { age: 29 } });

// Update multiple documents
db.users.updateMany({ age: { $lt: 30 } }, { $set: { status: "young" } });
```

#### d) Delete

```javascript
// Delete one document
db.users.deleteOne({ name: "Bob" });

// Delete many documents
db.users.deleteMany({ age: { $gt: 30 } });
```

---

### 4. **Query Operators**

- **Comparison Operators:** `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin`
    
- **Logical Operators:** `$and`, `$or`, `$not`, `$nor`
    
- **Element Operators:** `$exists`, `$type`
    
- **Array Operators:** `$all`, `$elemMatch`, `$size`, `$push`, `$pull`
    

**Example:**

```javascript
db.users.find({
  age: { $gte: 25, $lte: 30 },
  skills: { $in: ["MongoDB"] }
});
```

---

### 5. **Indexes**

- Improve query performance.
    
- Types: Single field, Compound, Unique, TTL (expire documents), Text, Geospatial.
    

**Example:**

```javascript
db.users.createIndex({ name: 1 }); // ascending index
db.users.createIndex({ age: 1, name: -1 }); // compound index
```

---

### 6. **Aggregation**

- MongoDB’s **pipeline framework** for data analysis.
    
- Stages: `$match`, `$group`, `$project`, `$sort`, `$limit`, `$unwind`.
    

**Example – Average age by status:**

```javascript
db.users.aggregate([
  { $match: { status: "young" } },
  { $group: { _id: "$status", avgAge: { $avg: "$age" } } }
]);
```

---

### 7. **Advanced Features**

#### a) Schema Validation

- MongoDB allows enforcing rules for documents using **JSON Schema**.
    

```javascript
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "age"],
      properties: {
        name: { bsonType: "string" },
        age: { bsonType: "int", minimum: 0 }
      }
    }
  }
});
```

#### b) Transactions

- Multi-document ACID transactions are supported in **replica sets**.
    

```javascript
const session = db.getMongo().startSession();
session.startTransaction();
try {
  db.users.updateOne({ name: "Ethan" }, { $set: { age: 30 } }, { session });
  db.orders.insertOne({ user: "Ethan", product: "Book" }, { session });
  session.commitTransaction();
} catch (e) {
  session.abortTransaction();
}
session.endSession();
```

#### c) Capped Collections

- Fixed-size collections for high-performance inserts.
    

```javascript
db.createCollection("logs", { capped: true, size: 100000 });
```

#### d) Change Streams

- Real-time notifications for data changes.
    

```javascript
db.users.watch().on("change", data => {
  printjson(data);
});
```

#### e) GridFS

- Store large files (images, videos) across multiple documents.
    

---

### 8. **Connection (MongoDB Drivers)**

- MongoDB can be connected from **Java, Python, Node.js, etc.**  
    **Example – Java Connection:**
    

```java
MongoClient mongoClient = MongoClients.create("mongodb://localhost:27017");
MongoDatabase database = mongoClient.getDatabase("testDB");
MongoCollection<Document> collection = database.getCollection("users");
```

---

### 9. **Backup & Restore**

- `mongodump` and `mongorestore` for backups.
    
- `mongoexport` and `mongoimport` for JSON/CSV data transfer.
    

---

### 10. **Best Practices**

- Use **indexes** wisely.
    
- Keep **collections small**; consider sharding for huge datasets.
    
- Avoid deeply nested documents for frequent updates.
    
- Validate schema for critical collections.
    
- Monitor performance using **MongoDB Atlas** or **Compass**.
    

---

### Tags : [[0 - Spring Framework]][[1 - SQL 🦬]]