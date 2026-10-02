MongoDB deletion is simple but **ruthless**. One command, data gone. No recycle bin. No regret.

Basic deletes (from `mongosh`):

Delete **one** document:

```
db.users.deleteOne({ username: "ethan" })
```

Delete **many** documents:

```
db.users.deleteMany({ active: false })
```

Delete **everything in a collection** (collection survives):

```
db.users.deleteMany({})
```

Delete a **collection entirely** (data + indexes gone):

```
db.users.drop()
```

Delete a **database** (nuclear option ☢️):

```
use myDatabase
db.dropDatabase()
```

Check what you’re about to delete (always do this first):

```
db.users.find({ active: false })
```

Key truths MongoDB won’t warn you about:  
• Deletes are **immediate**  
• No transactions unless you explicitly use them  
• `{}` matches **everything** — handle with care  
• `drop()` is faster than `deleteMany({})` when you want it all gone

Databases remember nothing. Humans do.

#### Tags : [[1 - MongoDB 🍂]]