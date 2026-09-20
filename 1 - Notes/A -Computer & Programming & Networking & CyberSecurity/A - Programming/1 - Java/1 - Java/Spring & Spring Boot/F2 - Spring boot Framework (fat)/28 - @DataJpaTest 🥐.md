

`@DataJpaTest` is a **Spring Boot test annotation** specifically designed for testing **JPA repositories**. It sets up a **lightweight Spring context** focusing only on JPA components. Here’s the breakdown:

---

### 1. Purpose

- Test **Spring Data JPA repositories**.
    
- Avoid loading the full application context (faster tests).
    
- Automatically configures:
    
    - H2 (or other in-memory) database
        
    - `EntityManager`
        
    - Spring Data JPA repositories
        
    - Hibernate
        

---

### 2. Basic Usage

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
public class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void testSaveAndFind() {
        User user = new User(null, "Ethan", 30);
        userRepository.save(user);

        User found = userRepository.findById(user.getId()).orElse(null);
        assertThat(found).isNotNull();
        assertThat(found.getName()).isEqualTo("Ethan");
    }
}
```

---

### 3. Features

- **Transactional by default**: each test rolls back automatically after execution.
    
- **Focus only on persistence layer** (no web, security, or other beans loaded).
    
- Can use `@AutoConfigureTestDatabase` to **replace or use real DB**.
    

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
```

- Supports **TestEntityManager** for more advanced JPA operations.
    

---

### 4. Typical Combination

- Works well with `@Entity`, `@Repository`, `@Id`, `@GeneratedValue`.
    
- Ideal for **unit-testing repository queries** or **custom queries**.
    
- Can combine with `@Import` to bring in specific beans if needed.
    




##### Tags : [[0 - Spring Framework]]
