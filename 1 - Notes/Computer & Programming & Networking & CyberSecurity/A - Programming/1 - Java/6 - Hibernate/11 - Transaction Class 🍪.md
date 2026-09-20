In Hibernate, the **`Transaction`** class represents a **unit of work** with the database. It allows you to **commit** or **rollback** changes made in a `Session`.

---

## 🔹 1. **In theory**

- Every database operation (insert, update, delete) should happen inside a **transaction**.
    
- `Transaction` ensures **atomicity** — either all changes succeed or none are applied.
    
- Obtained from a `Session` object.
    

---

## 🔹 2. **Creating a Transaction**

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();  // Start a transaction
```

---

## 🔹 3. **Commit / Rollback**

```java
try {
    Student s = new Student("Ethan", "Ward");
    session.save(s);

    tx.commit();  // Save changes to the database
} catch (Exception e) {
    tx.rollback();  // Undo changes if an error occurs
} finally {
    session.close();
}
```

- `commit()` → Writes all changes to the DB.
    
- `rollback()` → Undoes all changes in the current transaction.
    

---

## 🔹 4. **Common Methods**

|Method|Description|
|---|---|
|`begin()` / `beginTransaction()`|Starts a new transaction (usually via Session).|
|`commit()`|Commits the transaction (saves changes).|
|`rollback()`|Rolls back the transaction (undoes changes).|
|`setTimeout(int seconds)`|Sets timeout for the transaction.|
|`isActive()`|Checks if the transaction is currently active.|

---

## 🔹 5. **Lifecycle**

```
Session open → begin Transaction → perform CRUD → commit/rollback → close Session
```

---


## 🔹 1. **Transaction Lifecycle Methods**

|Method|Description|
|---|---|
|`begin()`|Starts a new transaction. _(Usually done via `Session.beginTransaction()`.)_|
|`commit()`|Commits the current transaction; all changes are persisted to the database.|
|`rollback()`|Rolls back the current transaction; discards all uncommitted changes.|
|`setTimeout(int seconds)`|Sets the maximum time the transaction is allowed to run.|

---

## 🔹 2. **Transaction State Methods**

|Method|Description|
|---|---|
|`isActive()`|Returns `true` if the transaction is still active (not committed or rolled back).|
|`getStatus()`|Returns the current status of the transaction (e.g., ACTIVE, COMMITTED, ROLLED_BACK).|
|`markRollbackOnly()`|Marks the transaction so that it can **only be rolled back**, not committed.|

---

## 🔹 3. **Utility / Cleanup Methods**

|Method|Description|
|---|---|
|`registerSynchronization(Synchronization sync)`|Registers a callback to be notified before or after transaction completion.|
|`enlistInJtaTransaction()`|Enlists the transaction in a JTA transaction (for Java EE).|

---

### 🔹 Example Usage

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();  // start transaction

try {
    Student s = new Student("Ethan", "Ward");
    session.save(s);

    tx.commit();  // save changes
} catch (Exception e) {
    tx.rollback();  // undo changes
} finally {
    session.close();
}
```

---
### 🧭 Summary

> The `Transaction` class is responsible for **starting, committing, and rolling back database operations**.  
> Its methods let you **control transaction boundaries** and check the state of ongoing transactions.
> 
> The **`Transaction`** class in Hibernate manages **atomic units of work**.  
> You always wrap DB operations in a transaction to ensure **consistency** and **recoverability** in case of errors.




##### Tags : [[1 - ORM 🍪]]