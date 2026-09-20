
In Hibernate, the **`Session`** class is the **main interface** used to interact with the database.  
It represents a **single unit of work** — basically one connection between your Java app and the database.

---

### 🔹 In theory

A `Session`:

- Is created from a `SessionFactory`.
    
- Manages persistent objects (entities).
    
- Handles CRUD operations.
    
- Wraps one **transactional context** (usually one per request).
    

---

### 🔹 Example

```java
Session session = sessionFactory.openSession(); // Open a session
session.beginTransaction();                     // Start a transaction

Student student = new Student();
student.setName("Ethan");
session.save(student);                          // INSERT into DB

session.getTransaction().commit();              // Commit changes
session.close();                                // Close session
```

---

### 🔹 Common Methods

|Method|Description|
|---|---|
|`save(object)`|Inserts a new record|
|`update(object)`|Updates an existing record|
|`delete(object)`|Deletes a record|
|`get(Entity.class, id)`|Fetches by primary key|
|`createQuery("from Student")`|Runs HQL queries|

---

### 🔹 Lifecycle

`SessionFactory` → creates → `Session` → performs work → closes


---

 Here’s a clear list of the most **important and commonly used methods** in Hibernate’s `Session` class (from `org.hibernate.Session`) : 



## 🔹 1. **Basic CRUD Methods**

|Method|Description|
|---|---|
|`save(Object entity)`|Inserts a new record (returns generated ID).|
|`persist(Object entity)`|Similar to `save()`, but follows JPA semantics (no return).|
|`update(Object entity)`|Updates an existing record in the database.|
|`merge(Object entity)`|Copies the state of a detached entity into the current session.|
|`delete(Object entity)`|Deletes a record from the database.|
|`get(Class<T> entityType, Serializable id)`|Fetches an entity by primary key (returns `null` if not found).|
|`load(Class<T> entityType, Serializable id)`|Fetches entity lazily — throws exception if not found.|

---

## 🔹 2. **Transaction Management**

|Method|Description|
|---|---|
|`beginTransaction()`|Starts a new database transaction.|
|`getTransaction()`|Returns the current transaction object.|
|`flush()`|Forces synchronization between session and database (executes pending SQL).|
|`clear()`|Clears the session cache (detaches all managed entities).|
|`close()`|Closes the session and releases database connection.|
|`isOpen()`|Checks if the session is still open.|

---

## 🔹 3. **Query Execution**

|Method|Description|
|---|---|
|`createQuery(String hql)`|Creates an HQL (Hibernate Query Language) query.|
|`createNativeQuery(String sql)`|Creates a raw SQL query.|
|`createCriteria(Class entityClass)` _(deprecated)_|Creates a criteria query (older API).|
|`createNamedQuery(String name)`|Uses a pre-defined named query.|

---

## 🔹 4. **Entity State Management**

|Method|Description|
|---|---|
|`evict(Object entity)`|Removes a specific entity from the session cache.|
|`contains(Object entity)`|Checks if an entity is currently managed by this session.|
|`refresh(Object entity)`|Reloads an entity’s state from the database.|
|`detach(Object entity)`|Detaches a managed entity (stops tracking changes).|

---

## 🔹 5. **SessionFactory Access**

```java
SessionFactory factory = session.getSessionFactory();
```

Gets the factory that created the session.

---

### 🔹 Example Usage

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

Student s = new Student("Ethan", "Ward");
session.save(s);

tx.commit();
session.close();
```

---
This is one of the **most confusing but essential** parts of Hibernate. Let’s break down `save()`, `persist()`, and `merge()` properly 


## ⚙️ 1. `save(Object entity)`

**Hibernate-only method** (not part of JPA).

|Aspect|Description|
|---|---|
|**Purpose**|Saves a _transient_ object (new object) to the database.|
|**Return Value**|Returns the _generated primary key_ (Serializable).|
|**When to Use**|When you want the inserted object’s ID immediately.|
|**Behavior**|Makes the entity **persistent** (managed by the session).|

✅ Example:

```java
Long id = (Long) session.save(student);
```

🧠 Note: Even if the transaction fails later, Hibernate _may_ assign an ID early — before commit.



## ⚙️ 2. `persist(Object entity)`

**Part of JPA specification**, and Hibernate supports it.

|Aspect|Description|
|---|---|
|**Purpose**|Similar to `save()`, but follows _JPA rules_.|
|**Return Value**|`void` — doesn’t return ID.|
|**When to Use**|When writing JPA-standard code (portable across providers).|
|**Behavior**|Entity becomes **persistent**, but no SQL is sent until flush/commit.|

✅ Example:

```java
session.persist(student);
```

🧠 Difference:

- `persist()` is _JPA compliant_, and **won’t insert immediately** — it waits until transaction commit or flush.
    
- `save()` inserts **immediately** and returns ID.
    



## ⚙️ 3. `merge(Object entity)`

|Aspect|Description|
|---|---|
|**Purpose**|Updates or attaches a **detached** entity back to the session.|
|**Return Value**|Returns a **new managed instance** (the one bound to the session).|
|**When to Use**|When you modify an entity _outside of a session_ and need to reattach it.|
|**Behavior**|Copies values from detached entity → persistent entity in session.|

✅ Example:

```java
Student detached = new Student(1L, "Ethan", "Ward");
Student managed = (Student) session.merge(detached);
```

🧠 After this, `managed` is tracked, but `detached` is not.



|Method|Part of JPA?|Returns|Works on|Inserts Immediately?|Use Case|
|---|---|---|---|---|---|
|`save()`|❌ No|ID|New entity|✅ Yes|Quick Hibernate insert|
|`persist()`|✅ Yes|void|New entity|❌ No (delayed)|Standard JPA insert|
|`merge()`|✅ Yes|Managed entity|Detached entity|❌ No (may update)|Reattach or update|



💡 **Simple analogy:**

- `save()` → “Add this object to DB right now and give me its ID.”
    
- `persist()` → “Schedule this new object for saving when transaction commits.”
    
- `merge()` → “Take this old object I’ve been editing and sync it with the DB again.”
    


### 🧠 Summary

> The **`Session`** class in Hibernate is your **gateway to the database**. It manages persistent objects and handles all database operations within a transaction.
> 
> The `Session` class is Hibernate’s main interface for **CRUD, transactions, and queries**.  
> It acts as a **bridge** between your Java objects and the database.


##### [[1 - ORM 🍪]]