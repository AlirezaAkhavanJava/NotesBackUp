
### Creating a Collection in MongoDB

In MongoDB, **collections are created implicitly** in most cases. You don't need to create a collection explicitly before using it—MongoDB automatically creates the collection (and even the database if it doesn't exist) when you insert the first document into it.

#### Implicit Creation (Recommended for most use cases)
Simply insert a document, and the collection will be created automatically.

#### Explicit Creation
Use the *`db.createCollection()`* method if you need to specify options (e.g., capped collections, validation rules, or collation).

### Inserting Documents

Use the modern methods:
- `db.collection.insertOne()` → for a single document.
- `db.collection.insertMany()` → for multiple documents.

(Note: Older methods like `db.collection.insert()` are deprecated in recent versions.)

### Step-by-Step Example Using mongosh (MongoDB Shell)

1. Connect to MongoDB and switch to a database (it will create the DB implicitly on first insert):
``` javaScript
	use myDatabase
```

2. **Insert a single document** (this creates the collection `myCollection` if it doesn't exist):
   ``` javaScript
   db.myCollection.insertOne({
     name: "John Doe",
     age: 30,
     city: "New York"
   })
   ```
   - Output example:
     ``` javaScript
     {
       acknowledged: true,
       insertedId: ObjectId("...")
     }
     ```
   - If the document doesn't have an `_id` field, MongoDB generates a unique `ObjectId` automatically.

3. **Insert multiple documents**:
   ``` javaScript
   db.myCollection.insertMany([
     { name: "Jane Smith", age: 25, city: "Los Angeles" },
     { name: "Bob Johnson", age: 35, city: "Chicago" }
   ])
   ```
   - Output example:
    ``` json
     {
       acknowledged: true,
       insertedIds: {
         '0': ObjectId("..."),
         '1': ObjectId("...")
       }
     }
     ```

4. Verify the documents:
   ```json
   db.myCollection.find().pretty()
   ```
   - This queries and displays all documents in a readable format.

### Explicitly Creating a Collection (with options example)

If you need a capped collection (fixed size, overwrites old documents):
```json
db.createCollection("myCappedCollection", { capped: true, size: 1024 * 1024, max: 100 })
```

### Notes
- Collection and database names must follow MongoDB naming rules (e.g., no `$` in names, case-sensitive).
- Documents are JSON-like (BSON) objects.
- Always handle errors in production code (e.g., duplicate `_id` will throw an error).

For the latest details, refer to the official MongoDB documentation on [inserting documents](https://www.mongodb.com/docs/manual/tutorial/insert-documents/) and [creating collections](https://www.mongodb.com/docs/manual/reference/method/db.createCollection/). This behavior is consistent across recent versions (including 8.x as of late 2025).
##### Tags : [[1 - MongoDB 🍂]]