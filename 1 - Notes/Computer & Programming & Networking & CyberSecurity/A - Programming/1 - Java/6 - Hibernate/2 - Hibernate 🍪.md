**Hibernate** is a **Java ORM (Object–Relational Mapping) framework** that automates the interaction between Java objects and relational databases.

---

### 🔹 In theory

Hibernate maps **Java classes → database tables** and **Java objects → table rows**.  
It converts your Java code into SQL under the hood — you work with objects, Hibernate handles the SQL.

---

### 🔹 Key Features

- **ORM Mapping** – Uses annotations (`@Entity`, `@Table`, etc.)
    
- **Automatic SQL generation** – No manual queries for CRUD
    
- **Transaction management**
    
- **Caching** – Improves performance
    
- **HQL (Hibernate Query Language)** – Object-oriented query language
    
- **Database independence** – Works with MySQL, PostgreSQL, Oracle, etc.
    

---

### 🔹 Example

```java
@Entity
@Table(name = "students")
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
}
```

Saving object using Hibernate:

```java
Session session = sessionFactory.openSession();
session.beginTransaction();

Student s = new Student();
s.setName("Ethan");
session.save(s);

session.getTransaction().commit();
session.close();
```

---

### 🔹 Summary

> Hibernate is a **powerful ORM framework** that simplifies database operations in Java by mapping objects to tables and automating SQL handling.
##### Tags : [[1 - ORM 🍪]]