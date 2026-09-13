Creating a database in MongoDB is straightforward, but MongoDB doesn’t actually create the database until you store some data in it. Here’s a step-by-step guide:

---

### **1. Connect to MongoDB**

If MongoDB is running locally:

```bash
mongo -u admin -p 9908 --authenticationDatabase admin
```

Or, if you are inside a Docker container:

```bash
docker exec -it mongodb mongo -u admin -p 9908 --authenticationDatabase admin
```

---

### **2. Switch to or Create a Database**

Use the `use` command:

```javascript
use myDatabase
```

- This does **not** immediately create the database; it just switches the context to `myDatabase`.
    
- If `myDatabase` doesn’t exist, MongoDB will create it **when you first insert data**.
    

---

### **3. Create a Collection (Table)**

Collections are like tables in SQL:

```javascript
db.createCollection("myCollection")
```

Or you can insert a document directly, which will create the collection automatically:

```javascript
db.myCollection.insertOne({ name: "Ethan", age: 25 })
```

---

### **4. Verify Database Creation**

List all databases:

```javascript
show dbs
```

- The new database will only appear after you insert at least one document.
    

---

✅ **Summary:**

- `use myDatabase` → switches/creates a DB.
    
- Insert a document → database and collection are created.
    
- `show dbs` → lists existing databases.
    

---



###### Tags : [[1 - MongoDB 🍂]]