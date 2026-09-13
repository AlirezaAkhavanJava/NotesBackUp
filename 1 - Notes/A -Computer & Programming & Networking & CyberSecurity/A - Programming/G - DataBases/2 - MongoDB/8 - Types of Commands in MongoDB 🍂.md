
### Types of Commands in MongoDB

MongoDB commands are operations you send to the server, either via the **mongosh** shell, drivers (e.g., Node.js, Python), or directly as database commands. They are broadly categorized based on their purpose.

Here is a comprehensive overview of the main types of MongoDB commands:

| Category                  | Description                                                                 | Common Examples                                                                 |
|---------------------------|-----------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| **Query and Read Operations** | Retrieve data from collections                                              | `find`, `findOne`, `countDocuments`, `distinct`, `aggregate`                    |
| **Insert Operations**     | Add new documents to a collection                                           | `insertOne`, `insertMany` (methods); `insert` (legacy command)                  |
| **Update Operations**     | Modify existing documents                                                   | `updateOne`, `updateMany`, `replaceOne`, `findOneAndUpdate`                      |
| **Delete Operations**     | Remove documents from a collection                                          | `deleteOne`, `deleteMany`, `findOneAndDelete`                                   |
| **Aggregation**           | Process data and return computed results (pipeline-based)                   | `aggregate` (with stages like `$match`, `$group`, `$sort`, `$project`, etc.)    |
| **Index Management**      | Create, list, and drop indexes for performance                               | `createIndex`, `dropIndex`, `listIndexes`, `getIndexes`                          |
| **Collection Management** | Create, modify, or delete collections                                       | `createCollection`, `drop`, `renameCollection`, `collStats`                     |
| **Database Management**   | Manage databases (create, drop, stats)                                       | `dropDatabase`, `create`, `stats`, `currentOp`, `listDatabases`                 |
| **Replication Commands**  | Manage replica sets (e.g., status, configuration)                            | `replSetGetStatus`, `replSetInitiate`, `replSetReconfig`, `replSetStepDown`     |
| **Sharding Commands**     | Manage sharded clusters (balancing, chunk operations)                        | `addShard`, `enableSharding`, `shardCollection`, `moveChunk`, `balancerStatus`  |
| **Authentication & Security** | User management, roles, authentication                                      | `createUser`, `dropUser`, `grantRolesToUser`, `usersInfo`, `authSchemaUpgrade`  |
| **Server Administration** | Server status, profiling, logging, shutdown                                 | `serverStatus`, `dbStats`, `hostInfo`, `top`, `shutdownServer`, `setParameter`  |
| **Diagnostic Commands**   | Debugging and diagnostics                                                   | `validate`, `compact`, `collMod`, `dataSize`, `planCacheClear`                  |
| **Geospatial Queries**    | Location-based queries                                                      | Special operators in `find`/`aggregate`: `$geoWithin`, `$near`, `$geoIntersects`|
| **Text Search**           | Full-text search capabilities                                               | `text` index + `$text` operator in queries                                      |

### How Commands Are Executed

1. **In mongosh (Shell Methods)** – Most common for interactive use:
   ```javascript
   db.collection.find({ age: { $gt: 30 } })
   db.collection.insertOne({ name: "Alice" })
   ```

2. **As Database Commands** – Using `db.runCommand()`:
   ```javascript
   db.runCommand({ count: "collectionName", query: { age: { $gt: 30 } } })
   db.runCommand({ createIndexes: "collectionName", indexes: [{ key: { age: 1 }, name: "age_idx" }] })
   ```

3. **In Drivers** – Equivalent methods exist in language-specific drivers (e.g., `collection.find()` in Node.js).

### Key Notes
- Many shell methods (like `find`, `insertOne`) are **helpers** that translate to underlying database commands.
- All operations ultimately become commands sent to the MongoDB server.
- For a full list of commands, run in mongosh:
  ```javascript
  db.runCommand({ listCommands: 1 })
  ```
  This returns all available commands with descriptions and required privileges.

For the latest and complete reference, see the official MongoDB documentation:  
https://www.mongodb.com/docs/manual/reference/command/

This categorization applies to MongoDB versions 6.x through 8.x (as of late 2025).

###### Tags : [[1 - MongoDB 🍂]]