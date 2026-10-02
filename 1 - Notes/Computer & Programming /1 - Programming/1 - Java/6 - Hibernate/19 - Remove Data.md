
In Hibernate, **removing data** means deleting an existing entity from the database. You can do it in several ways depending on whether the entity is **managed**, **detached**, or via **HQL**.

---

## 🔹 1. **Using `Session.delete()`**

- Deletes an entity **attached to the session** or **detached** if reattached first.
    

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

// Fetch entity first (managed)
Student student = session.get(Student.class, 1L);
session.delete(student);   // Marks entity for deletion

tx.commit();                // DELETE executed in DB
session.close();
```

**Notes:**

- The entity must exist in the database.
    
- If the entity is detached, you may need `session.merge()` first.
    

---

## 🔹 2. **Removing a Detached Entity**

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

Student detachedStudent = new Student();
detachedStudent.setId(1L);  // Existing ID

// Reattach and delete
session.delete(session.merge(detachedStudent));

tx.commit();
session.close();
```

- `merge()` returns a **managed entity**, which can then be deleted.
    

---

## 🔹 3. **Using HQL / JPQL Delete Query**

- Deletes entities **directly in bulk**, without fetching them.
    

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

int deletedCount = session.createQuery(
    "DELETE FROM Student s WHERE s.id = :id")
    .setParameter("id", 1L)
    .executeUpdate();

tx.commit();
session.close();
```

- `executeUpdate()` returns the **number of rows deleted**.
    
- Bulk delete bypasses session cache; be careful with entities already loaded in the session.
    

---

## 🔹 4. **Cascade Delete**

- If an entity has relationships with **cascade = CascadeType.REMOVE**, deleting the parent will **automatically delete related entities**.
    

```java
@OneToMany(mappedBy = "student", cascade = CascadeType.REMOVE)
private List<Course> courses;
```

Deleting the student:

```java
session.delete(student);  // Also deletes all courses
```

---

## 🔹 Summary Table

|Method|When to Use|Notes|
|---|---|---|
|`session.delete(entity)`|Managed or reattached entity|Entity is removed on commit|
|Detached entity + merge|Detached entity|Reattach first, then delete|
|HQL delete|Bulk delete|Bypasses session cache, fast|
|Cascade remove|Relationships|Deletes dependent entities automatically|

---

💡 **Senior Tip:**

- Prefer **fetch → delete** for a single entity to avoid mistakes.
    
- Use **HQL delete** for bulk deletions.
    
- Always check cascade settings to prevent accidental deletion of related data.
    





##### Tags : [[2 - Hibernate 🍪]]