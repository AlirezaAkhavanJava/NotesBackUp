
### **1️⃣ TestEntityManager**

`TestEntityManager` is a Spring Boot test utility that’s basically a thin wrapper around JPA’s `EntityManager`, designed for testing with `@DataJpaTest`.

You use it to:

- Persist entities in a test DB
    
- Find entities
    
- Flush or clear the persistence context
    

Example:

```java
@Autowired
private TestEntityManager entityManager;

@Test
void testPersistGamer() {
    Gamers gamer = new Gamers(); // normally use constructor or setter
    gamer.setName("Mark Davis");
    
    entityManager.persist(gamer);
    entityManager.flush();

    Gamers found = entityManager.find(Gamers.class, gamer.getId());
    assertEquals("Mark Davis", found.getName());
}
```

---

### **2️⃣ Lombok `@Builder`**

`@Builder` gives you a fluent API to construct objects without lots of constructors or setters.

Example:

```java
Gamers gamer = Gamers.builder()
                     .name("Mark Davis")
                     .score(100)
                     .build();
```

---

### **3️⃣ How They Work Together**

You combine them to make your test setup cleaner:

```java
Gamers gamer = Gamers.builder()
                     .name("Mark Davis")
                     .score(100)
                     .build();

entityManager.persist(gamer);
entityManager.flush();

Gamers found = entityManager.find(Gamers.class, gamer.getId());
assertEquals("Mark Davis", found.getName());
```

**Why this is nice:**

- `@Builder` avoids long constructors or messy setters
    
- `TestEntityManager` persists it immediately in the test DB
    
- Together, your test is short, readable, and expressive
    

---

💡 **Pro tip:**  
If your entity has relationships (like `@OneToMany`), you can also use `@Builder` with `@Singular` to add collections, making complex test data easy to build without manually managing lists.

---



##### Tags : [[0 - Spring Framework]]