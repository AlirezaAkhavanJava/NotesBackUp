

`TestEntityManager` is a **helper class in Spring Boot tests** that wraps the standard JPA `EntityManager` with **convenient methods** for testing. It is provided automatically when you use `@DataJpaTest`.

---

### 1. Purpose

- Simplifies testing JPA operations in unit tests.
    
- Provides methods like `persist()`, `find()`, `flush()`, etc., **without manually handling transactions**.
    
- Useful for setting up test data and verifying repository behavior.
    

---

### 2. Basic Usage

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
public class UserRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private UserRepository userRepository;

    @Test
    void testFindUser() {
        // Persist an entity
        User user = new User(null, "Ethan", 30);
        entityManager.persist(user);
        entityManager.flush(); // ensure it's written to DB

        // Use repository to find it
        User found = userRepository.findById(user.getId()).orElse(null);
        assertThat(found).isNotNull();
        assertThat(found.getName()).isEqualTo("Ethan");
    }
}
```

---

### 3. Key Methods

|Method|Description|
|---|---|
|`persist(entity)`|Saves the entity to the DB (like `save`).|
|`persistAndFlush(entity)`|Saves and flushes immediately.|
|`flush()`|Forces pending changes to DB.|
|`find(Class, id)`|Finds entity by ID (like `EntityManager.find`).|
|`remove(entity)`|Deletes an entity.|
|`merge(entity)`|Updates an entity.|

---

### 4. Why Use It Instead of Repository?

- Works well when you **want to bypass repository logic** and directly interact with JPA for setup.
    
- Ensures **database state is exactly what you expect** before running repository methods.
    
- Plays nicely with `@DataJpaTest` transactional rollback behavior.
    

---



##### Tags : [[0 - Spring Framework]]