
In **Hibernate**, the `Configuration` class is the bootstrap entry point for setting up Hibernate.

---

- *`Configuration` = **Hibernate setup box**.*
    
- *Inside the box you put:*
    
    - *Database connection details (URL, username, password).*
        
    - *Entity classes (like `Alien`, `User`, etc).*
        
- *Once the box is ready, you use it to create the **`SessionFactory`**.*
    
- *After that, Hibernate knows **how to talk to the database** and **which classes to save/load***

1. **`configure()`**
    
    - Loads settings from `hibernate.cfg.xml`.
        
    - Example:
        
        ```java
        Configuration cfg = new Configuration().configure();
        ```
        
2. **`configure(String resource)`**
    
    - Loads a custom config file.
        
    - Example:
        
        ```java
        `cfg.configure("my-hibernate.cfg.xml");`
        ```
        
3. **`addAnnotatedClass(Class<?> clazz)`**
    
    - Tells Hibernate about an entity class (with `@Entity`).
        
    - Example:
        
        ```java
        `cfg.addAnnotatedClass(Alien.class);`
        ```
        
4. **`addResource(String resourceName)`**
    
    - Adds a mapping file (`.hbm.xml`).
        
    - Example:
        
        ```java
        `cfg.addResource("alien.hbm.xml");`
        ```
        
5. **`setProperty(String key, String value)`**
    
    - Sets a property (like DB URL, username, dialect) manually.
        
    - Example:
        
        ```java
        `cfg.setProperty("hibernate.show_sql", "true");`
        ```
        
6. **`getProperties()`**
    
    - Returns all current Hibernate properties.
        
7. **`buildSessionFactory()`**
    
    - Uses all settings + mappings to create the **`SessionFactory`** (the main object you use later).
        
    - Example:
        
        ```java
        `SessionFactory factory = cfg.buildSessionFactory();`
        ```
        

---

⚡ In practice, you mostly use only:

- `configure()`
    
- `addAnnotatedClass()`
    
- `buildSessionFactory()`
    

The others are more for fine-tuning.

---
The **main job** of `Configuration` is to **load settings from `hibernate.cfg.xml` (or `.properties`)** and then **collect all entity mappings**.

But:

- It can also be used without XML → you can set properties and mappings **in code** (`setProperty`, `addAnnotatedClass`).
    
- After collecting all info, it builds the `SessionFactory`.
    

So:  
👉 `Configuration` = **“loader + collector”** of Hibernate settings + entity mappings


---
##### Why SessionFactory needs Configuration ? 
> `Configuration` is needed to **tell Hibernate**:

1. **Database info** – URL, username, password, dialect, etc.
    
2. **Entity mappings** – which classes map to which tables.
    
3. **Other settings** – e.g., show SQL, caching, connection pool, etc.
    

>Without `Configuration`, Hibernate cannot:

- Connect to your database.
    
- Know what tables exist or how your classes map to them.
    
- Build the `SessionFactory` that produces sessions.
    

> In short:  
**`Configuration` = the instruction manual Hibernate reads to know how to work with your database.**



---

### **SessionFactory**

- **What it is:** A **big object that knows how to connect to the database** and manage entities.
    
- **Purpose:** Creates `Session` objects whenever you need them.
    
- **Life-cycle:** Heavyweight → create **once** at the start, reuse everywhere.
    
- **Analogy:** A **factory** that produces workers.
    

---

### **Session**

- **What it is:** A **lightweight object for doing actual database work**.
    
- **Purpose:** Save, read, update, delete data.
    
- **Life-cycle:** Short-lived → open, do work, close.
    
- **Analogy:** A **worker from the factory** doing a job.
    

---

**Flow in plain words:**

1. `Configuration` → tells Hibernate the plan.
    
2. `SessionFactory` → builds the factory based on that plan.
    
3. `Session` → a worker from the factory that actually talks to the database.
    

---























[[0 - Spring Framework]]