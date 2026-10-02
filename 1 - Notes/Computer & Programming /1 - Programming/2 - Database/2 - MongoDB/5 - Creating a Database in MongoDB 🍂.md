


MongoDB does not have an explicit "create database" command. Instead, a database is created implicitly when you switch to it and insert data into a collection.

#### Steps (using mongosh, the MongoDB Shell):
1. Connect to your MongoDB server:  
   ```bash
   mongosh
   ```

2. Switch to the new database (this creates it if it doesn't exist, but it won't appear in listings yet):  
   ``` java
   use myNewDatabase
   ```

3. Insert a document into a collection (this actually creates the database and collection):  
   ```
   db.myCollection.insertOne({ name: "Example Document" })
   ```

4. Verify the database exists:  
   ```
   show dbs
   ```
   Your `myNewDatabase` should now appear.

**Note**: Empty databases do not persist and won't show in `show dbs`. Always insert at least one document to make it permanent.

In tools like **MongoDB Compass** or **Atlas UI**, you can create databases explicitly via the graphical interface by specifying a database and collection name, often with an initial insert.

### Removing (Dropping) a Database in MongoDB

To delete a database permanently (including all its collections and data):

#### Steps (using mongosh):
1. Switch to the database you want to drop:  
   ```
   use myDatabaseToDrop
   ```

2. Drop it:  
   ```
   db.dropDatabase()
   ```

   Output example:  
   ```
   { ok: 1, dropped: "myDatabaseToDrop" }
   ```

3. Verify:  
   ```
   show dbs
   ```
   The database should no longer appear.

**Warnings**:
- This operation is irreversible—back up data first if needed (e.g., using `mongodump`).
- You need appropriate privileges (e.g., `dbOwner` role on the database).
- Avoid dropping system databases like `admin`, `config`, or `local`—it can render your cluster unusable.
- In sharded clusters, run on a `mongos` if recreating a database with the same name afterward.

These behaviors are consistent across recent MongoDB versions (including 8.0+ as of late 2025). For Atlas-managed clusters, you can also drop databases via the Atlas UI by selecting the database and clicking the trash icon (with confirmation).

##### Tags : [[1 - MongoDB 🍂]]