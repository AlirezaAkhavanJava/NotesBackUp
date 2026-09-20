
In Hibernate, **updating data** means modifying an existing entity and saving those changes back to the database. Here’s a clear, step-by-step explanation:

---

## 🔹 1. **Using `Session.update()`**

- `update()` is used to **reattach a detached entity** to the session and mark it for update.
    

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

// Suppose we already have a detached Student object
Student student = new Student();
student.setId(1L);        // Existing primary key
student.setName("Ethan Ward Updated");

session.update(student);   // Marks entity for update
tx.commit();
session.close();
```

**Notes:**

- The entity must **already exist in the database**.
    
- Throws `NonUniqueObjectException` if the session already contains an entity with the same ID.
    

---

## 🔹 2. **Using `Session.merge()`**

- `merge()` copies the state of a detached entity into a **managed entity** in the session.
    
- Safer than `update()` if the session might already contain the entity.
    

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

Student detachedStudent = new Student(1L, "Ethan Ward Updated");
Student managedStudent = (Student) session.merge(detachedStudent);

tx.commit();
session.close();
```

**Notes:**

- Returns a **managed entity**.
    
- Doesn’t throw exceptions if the session already has the entity.
    

---

## 🔹 3. **Updating after fetching**

- You can fetch the entity first, then modify it. Hibernate **automatically detects changes** and updates at commit.
    

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

Student student = session.get(Student.class, 1L);
student.setName("Ethan Ward Updated"); // modify property

tx.commit();  // changes are automatically persisted
session.close();
```

**Notes:**

- No need to call `update()` if the entity is **managed** (attached to session).
    
- Hibernate uses **dirty checking** to detect changes.
    

---

## 🔹 4. **HQL Update Query**

- Can update entities directly without fetching.
    

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

int updatedCount = session.createQuery(
    "UPDATE Student s SET s.name = :name WHERE s.id = :id")
    .setParameter("name", "Ethan Ward Updated")
    .setParameter("id", 1L)
    .executeUpdate();

tx.commit();
session.close();
```

**Notes:**

- Does **bulk update**, bypassing session cache.
    
- Returns the **number of rows affected**.
    

---

## 🔹 Summary Table

|Method|When to Use|Notes|
|---|---|---|
|`update()`|Detached entity not in session|Throws exception if same entity exists in session|
|`merge()`|Detached entity possibly in session|Safer, returns managed entity|
|Fetch & modify|Entity is managed|Automatic update via dirty checking|
|HQL update|Bulk updates|Bypasses session, returns row count|

---

💡 **Senior Tip:**

- Prefer **fetch → modify → commit** for a single entity.
    
- Use `merge()` when unsure about session state.
    
- Use HQL only for bulk updates or when you want to avoid fetching all entities.
    

---



##### Tags : [[2 - Hibernate 🍪]]