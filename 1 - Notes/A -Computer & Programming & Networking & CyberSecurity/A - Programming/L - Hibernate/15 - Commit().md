
In Hibernate, the **`commit()`** method is part of the **`Transaction`** class and is used to **finalize a transaction** by saving all changes made in the session to the database.

---

## 🔹 1. **In theory**

- When you perform operations like `save()`, `update()`, or `delete()` in a Hibernate session, the changes are **not immediately written** to the database.
    
- They exist in **Hibernate’s session cache** until you **commit the transaction**.
    
- Calling `commit()` ensures that all changes are **persisted atomically**.
    

---

## 🔹 2. **Usage Example**

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();  // start transaction

try {
    Student student = new Student("Ethan", "Ward");
    session.save(student);                     // change is staged in session

    tx.commit();                                // changes are written to the DB
} catch (Exception e) {
    tx.rollback();                              // undo changes if error occurs
} finally {
    session.close();
}
```

---

## 🔹 3. **Key Points**

- Must be called **after all DB operations** in the transaction are done.
    
- If `commit()` succeeds → all changes are **permanently saved**.
    
- If an exception occurs before commit → you should call `rollback()` to **discard changes**.
    
- Hibernate automatically **flushes the session** before committing.
    

---

## 🔹 4. **Lifecycle Context**

```
Session open → begin Transaction → perform CRUD → commit → close Session
```

---

### 🧭 Summary

> `commit()` in Hibernate **confirms all changes** made in a transaction and writes them to the database.  
> It ensures **atomicity**: either all operations succeed, or if you rollback, none are applied.


##### Tags : [[1 - ORM 🍪]]