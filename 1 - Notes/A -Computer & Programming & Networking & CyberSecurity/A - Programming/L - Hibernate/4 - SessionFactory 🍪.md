
The **`SessionFactory`** class in Hibernate is the **core factory** responsible for creating and managing `Session` objects.

---

### 🔹 In theory

`SessionFactory` is a **thread-safe**, **heavyweight** object that represents your **entire database configuration**.  
It’s created **once** per application (usually at startup) and reused throughout the app.

Think of it like:

> 🏭 `SessionFactory` = a factory that produces `Session` objects (each used for one unit of work).

---

### 🔹 Example

```java
import org.hibernate.SessionFactory;
import org.hibernate.cfg.Configuration;

public class HibernateUtil {
    private static final SessionFactory sessionFactory;

    static {
        try {
            sessionFactory = new Configuration()
                    .configure("hibernate.cfg.xml")   // or use Java-based config
                    .buildSessionFactory();
        } catch (Throwable ex) {
            throw new ExceptionInInitializerError(ex);
        }
    }

    public static SessionFactory getSessionFactory() {
        return sessionFactory;
    }
}
```

Usage:

```java
Session session = HibernateUtil.getSessionFactory().openSession();
```

---

### 🔹 Key Points

- Created once → reused (singleton)
    
- Thread-safe
    
- Reads configuration (DB URL, username, dialect, etc.)
    
- Builds a **connection pool** internally
    
- Produces `Session` instances for DB operations
    

---

 **`SessionFactory`** in Hibernate is the **heavyweight, thread-safe object** that creates `Session` objects. Here’s a breakdown of its **important methods** and what they do:


## 🔹 1. **Creating Sessions**

|Method|Description|
|---|---|
|`openSession()`|Opens a **new Session**. You have to close it manually.|
|`getCurrentSession()`|Returns the **current session** bound to the context (like a thread). Often used with Spring transactions.|

---

## 🔹 2. **Managing the Factory**

|Method|Description|
|---|---|
|`close()`|Closes the `SessionFactory` and releases all resources (connections, caches).|
|`isClosed()`|Checks if the `SessionFactory` is already closed.|

---

## 🔹 3. **Metadata & Statistics**

|Method|Description|
|---|---|
|`getStatistics()`|Returns a `Statistics` object to monitor queries, sessions, cache hits, etc.|
|`getClassMetadata(Class entityClass)`|Returns metadata about an entity (properties, identifier, table name).|
|`getAllClassMetadata()`|Returns metadata for all mapped entities.|

---

## 🔹 4. **Caching**

|Method|Description|
|---|---|
|`getCache()`|Access the **second-level cache** for entities and collections.|

---

## 🔹 Example Usage

```java
// Create SessionFactory
SessionFactory factory = new Configuration()
        .configure("hibernate.cfg.xml")
        .addAnnotatedClass(Student.class)
        .buildSessionFactory();

// Open a session
Session session = factory.openSession();
Transaction tx = session.beginTransaction();

Student s = new Student("Ethan", "Ward");
session.save(s);

tx.commit();
session.close();

// Close factory when application ends
factory.close();
```

---

### 🧭 Summary

> The **`SessionFactory`** is the **central Hibernate object** that initializes Hibernate, holds configuration settings, manages connections, and creates `Session` objects for interacting with the database.
> 
> The `SessionFactory` is the **central factory for sessions**.  
> You use it to **open sessions**, access metadata, manage caches, and finally **close it** when your application shuts down.


##### Tags : [[1 - ORM 🍪]]