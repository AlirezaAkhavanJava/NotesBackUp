

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


---

## ⚙️ Big Picture

|Concept|`EntityManager`|`Session`|
|---|---|---|
|Belongs to|JPA (standard API)|Hibernate (implementation)|
|Goal|Portable JPA interface|Hibernate’s native control|
|Creation|`EntityManagerFactory`|`SessionFactory`|
|Query Language|JPQL|HQL (Hibernate Query Language)|
|Transaction|`EntityTransaction`|`Transaction`|
|Use in Spring|`@PersistenceContext`|`@Autowired SessionFactory`|

---

## 🧩 Method Comparison Table

|Operation|`EntityManager`|`Session` (Hibernate)|Description|
|---|---|---|---|
|Insert|`persist(entity)`|`save(entity)`|Adds entity to DB|
|Find by ID|`find(Entity.class, id)`|`get(Entity.class, id)` or `byId()`|Retrieves entity|
|Lazy fetch|`getReference()`|`load()`|Returns proxy; fetches on access|
|Update|`merge(entity)`|`update()` or `saveOrUpdate()`|Updates detached entity|
|Delete|`remove(entity)`|`delete(entity)`|Removes entity|
|Flush|`flush()`|`flush()`|Syncs persistence context to DB|
|Clear cache|`clear()`|`clear()`|Detaches all managed entities|
|Check managed|`contains(entity)`|`contains(entity)`|Is entity tracked?|
|Create JPQL|`createQuery("JPQL")`|`createQuery("HQL")`|Run object-oriented queries|
|Create SQL|`createNativeQuery("SQL")`|`createNativeQuery("SQL")`|Run raw SQL|
|Get transaction|`getTransaction()`|`beginTransaction()`|Manual transaction|
|Close|`close()`|`close()`|Ends session|

---

## 🔁 Example: Same Operation, Two Ways

### 🔹 JPA Style

```java
EntityManager em = emf.createEntityManager();
em.getTransaction().begin();

Employee e = new Employee("John");
em.persist(e);

em.getTransaction().commit();
em.close();
```

### 🔹 Hibernate Style

```java
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

Employee e = new Employee("John");
session.save(e);

tx.commit();
session.close();
```

---

## 🧠 Spring Boot Integration

|Feature|JPA (`EntityManager`)|Hibernate (`Session`)|
|---|---|---|
|Injection|`@PersistenceContext EntityManager em;`|`@Autowired SessionFactory sf;`|
|Transaction|`@Transactional` handled automatically|Same via Spring’s proxy|
|Portability|✅ Works with any JPA provider|❌ Hibernate-specific|
|Advanced Hibernate features|Limited|✅ Full control (filters, stats, etc.)|

---

## 🐐 TL;DR

|Want|Use|
|---|---|
|Standard JPA and portability|`EntityManager`|
|Hibernate-only features or optimization|`Session`|
|Both worlds (Spring)|Inject `EntityManager` and call `unwrap(Session.class)`|

Example:

```java
Session session = entityManager.unwrap(Session.class);
```

---


##### Tags :[[1 - ORM 🍪]]