## 🧠 What is `EntityManager`?

- It’s the **main interface** in **JPA (Java Persistence API)** that handles **CRUD operations**, queries, and transactions for entities.
    
- Think of it as the **bridge** between your Java objects (entities) and the **database**.
    

---

## ⚙️ Basic Lifecycle

`EntityManager` comes from an `EntityManagerFactory`:

```java
EntityManagerFactory emf = Persistence.createEntityManagerFactory("my-unit");
EntityManager em = emf.createEntityManager();
```

Then you can:

- Start a transaction
    
- Perform operations (persist, find, remove, etc.)
    
- Commit or rollback
    

---

## 🧩 Common Methods

|Method|Purpose|
|---|---|
|`persist(entity)`|Insert new entity (make it managed)|
|`find(EntityClass, id)`|Fetch entity by primary key|
|`merge(entity)`|Update entity (sync changes)|
|`remove(entity)`|Delete entity|
|`createQuery("JPQL")`|Run JPQL queries|
|`createNativeQuery("SQL")`|Run raw SQL|
|`getTransaction()`|Access transaction object (begin/commit/rollback)|
|`close()`|Close the manager|
|`contains(entity)`|Check if entity is managed|
|`flush()`|Force sync to DB immediately|

---

## 💡 Example (Plain JPA)

```java
EntityManagerFactory emf = Persistence.createEntityManagerFactory("my-unit");
EntityManager em = emf.createEntityManager();

em.getTransaction().begin();

Employee emp = new Employee();
emp.setName("John");
emp.setEmail("john@gmail.com");

em.persist(emp);  // insert
em.getTransaction().commit();

Employee found = em.find(Employee.class, emp.getId());  // select
found.setName("John Doe");

em.getTransaction().begin();
em.merge(found);   // update
em.getTransaction().commit();

em.getTransaction().begin();
em.remove(found);  // delete
em.getTransaction().commit();

em.close();
emf.close();
```

---

## 🧠 Entity States

|State|Description|
|---|---|
|**New (Transient)**|Not in DB yet, not tracked by EntityManager.|
|**Managed (Persistent)**|Being tracked; changes auto-saved on commit.|
|**Detached**|Was managed, now disconnected.|
|**Removed**|Marked for deletion on commit.|

---

## ⚙️ With Spring Boot

Spring handles all that setup for you.  
You just inject it:

```java
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class EmployeeService {

    @PersistenceContext
    private EntityManager entityManager;

    public Employee getEmployee(Long id) {
        return entityManager.find(Employee.class, id);
    }

    public void save(Employee emp) {
        entityManager.persist(emp);
    }
}
```

You don’t call `begin()` or `commit()` — Spring handles transactions automatically (via `@Transactional`).

---

### 🐐 TL;DR

|Role|Description|
|---|---|
|`EntityManager`|Core interface for DB operations|
|`persist()`|Insert|
|`find()`|Read|
|`merge()`|Update|
|`remove()`|Delete|
|`createQuery()`|JPQL|
|`createNativeQuery()`|SQL|
|`flush()`|Force save|
|Managed by Spring|If `@Transactional` is used|

##### Tags : [[1 - Junit 5 🥭]]