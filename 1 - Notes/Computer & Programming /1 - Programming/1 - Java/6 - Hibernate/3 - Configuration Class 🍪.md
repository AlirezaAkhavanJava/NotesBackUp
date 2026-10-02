In Hibernate (or Spring with Hibernate), a **Configuration class** defines how Hibernate connects to the database and manages entities.

You can configure it in **two ways**:

1. XML (`hibernate.cfg.xml`)
    
2. **Java-based Configuration class** ✅ (modern way)
    

---

### 🔹 Example — Hibernate Configuration Class

```java
import org.hibernate.SessionFactory;
import org.hibernate.cfg.Configuration;
import com.example.entity.Student;

public class HibernateConfig {

    private static SessionFactory sessionFactory;

    static {
        try {
            // Create Configuration instance
            Configuration config = new Configuration();

            // Load database connection settings
            config.setProperty("hibernate.connection.driver_class", "com.mysql.cj.jdbc.Driver");
            config.setProperty("hibernate.connection.url", "jdbc:mysql://localhost:3306/schooldb");
            config.setProperty("hibernate.connection.username", "root");
            config.setProperty("hibernate.connection.password", "password");

            // Hibernate settings
            config.setProperty("hibernate.dialect", "org.hibernate.dialect.MySQLDialect");
            config.setProperty("hibernate.hbm2ddl.auto", "update");  // auto-create/update tables
            config.setProperty("show_sql", "true");

            // Register entity classes
            config.addAnnotatedClass(Student.class);

            // Build SessionFactory
            sessionFactory = config.buildSessionFactory();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static SessionFactory getSessionFactory() {
        return sessionFactory;
    }
}
```

---

### 🔹 What this class does

- Defines **database connection properties**
    
- Registers **entity classes**
    
- Builds a **`SessionFactory`** (used to open sessions and perform CRUD)
    
- Keeps all config in **Java code instead of XML**
    

---

In plain **Hibernate (non-Spring)**, the **database connection details** — like the URL, username, password, and driver — come from the **configuration**, either:

- from a **Java config class** (like the one I showed), **or**
    
- from an **XML file** (`hibernate.cfg.xml`).
    

Example (Java-based):

```java
config.setProperty("hibernate.connection.url", "jdbc:mysql://localhost:3306/schooldb");
config.setProperty("hibernate.connection.username", "root");
config.setProperty("hibernate.connection.password", "password");
```

That’s how Hibernate knows **which database to connect to** and **how**.

---

But in **Spring Boot**, it’s different — those settings usually go in `application.properties` or `application.yml`, not in Java code.  
Example in Spring Boot:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/schooldb
spring.datasource.username=root
spring.datasource.password=password
spring.jpa.hibernate.ddl-auto=update
```

So:

- In **Hibernate alone** → config class (or XML)
    
- In **Spring Boot + Hibernate/JPA** → `application.properties` handles it.

---

## Most common methods : 

### 🔹 1. `configure()`

```java
Configuration cfg = new Configuration().configure();
```

- Loads settings from **`hibernate.cfg.xml`** (by default).
    
- You can also specify a custom file:
    
    ```java
    configure("myconfig.xml");
    ```
    
- Reads DB connection info, dialect, mapping, etc.
    

---

### 🔹 2. `addAnnotatedClass(Class clazz)`

```java
cfg.addAnnotatedClass(Student.class);
```

- Registers a class annotated with `@Entity`.
    
- Lets Hibernate know that this class should be mapped to a table.
    

---

### 🔹 3. `addResource(String resourceName)`

```java
cfg.addResource("student.hbm.xml");
```

- Adds an XML mapping file (old style mapping, before annotations).
    

---

### 🔹 4. `setProperty(String key, String value)`

```java
cfg.setProperty("hibernate.connection.url", "jdbc:mysql://localhost:3306/testdb");
```

- Manually sets or overrides Hibernate properties in Java code.
    
- Common keys:
    
    - `hibernate.connection.driver_class`
        
    - `hibernate.connection.username`
        
    - `hibernate.connection.password`
        
    - `hibernate.dialect`
        
    - `hibernate.hbm2ddl.auto`
        

---

### 🔹 5. `buildSessionFactory()`

```java
SessionFactory factory = cfg.buildSessionFactory();
```

- Builds the **`SessionFactory`** using the configuration and mappings provided.
    
- This is the **final step** in configuration — after this, you can open sessions and interact with the DB.
    

---

### 🔹 6. (Less common) `addPackage(String packageName)`

Registers all mapping files or annotated classes within a package.

---

### 🧭 Typical usage example:

```java
Configuration cfg = new Configuration();
cfg.configure("hibernate.cfg.xml");
cfg.addAnnotatedClass(Student.class);
SessionFactory factory = cfg.buildSessionFactory();
```

---

### 🧩 Summary

|Method|Purpose|
|---|---|
|`configure()`|Load XML config|
|`setProperty()`|Manually set DB or Hibernate properties|
|`addAnnotatedClass()`|Register entity class|
|`addResource()`|Add XML mapping|
|`buildSessionFactory()`|Build the SessionFactory|
|`addPackage()`|Register a package of mappings|


##### Tags : [[1 - ORM 🍪]]