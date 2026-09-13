### 🧩 1. **Configuration**

Hibernate loads your **database settings** and **entity mappings** — either from:

- `hibernate.cfg.xml`, or
    
- a **Java Configuration class**.
    

It knows:

- Which DB to connect to (`jdbc:mysql://...`)
    
- Which entities exist (`@Entity` classes)
    

---

### 🏭 2. **Build the `SessionFactory`**

```java
SessionFactory factory = new Configuration()
    .configure("hibernate.cfg.xml")
    .buildSessionFactory();
```

- Created **once** at app startup.
    
- Reads all configs and builds internal metadata.
    
- Ready to produce sessions.
    

---

### ⚙️ 3. **Open a Session**

```java
Session session = factory.openSession();
```

- Think of a `Session` as a **connection** to the DB.
    
- It manages your persistent objects (entities).
    

---

### 🔒 4. **Begin a Transaction**

```java
session.beginTransaction();
```

- All DB operations (insert/update/delete) happen inside a **transaction**.
    
- If something fails → rollback happens.
    

---

### 🧱 5. **Create a Java Object**

```java
Student s = new Student();
s.setName("Ethan");
s.setEmail("ethan@mail.com");
```

This is a **transient object** — not yet stored in the database.

---

### 💾 6. **Save the Object**

```java
session.save(s);
```

Now the object becomes **persistent** — Hibernate:

- Generates an **SQL `INSERT` statement**.
    
- Sends it to the DB through JDBC.
    
- Assigns the generated ID (if applicable).
    

---

### ✅ 7. **Commit the Transaction**

```java
session.getTransaction().commit();
```

- Confirms the insert.
    
- The record is **physically written** to the database.
    

---

### 🔚 8. **Close the Session**

```java
session.close();
```

- Ends the connection.
    
- The object becomes **detached** (still exists in memory, but no longer managed by Hibernate).
    

---

### 🧭 Summary Workflow

```
Configuration → SessionFactory → Session → Transaction → save(object) → commit → close
```

---

##### Tags : [[1 - ORM 🍪]]