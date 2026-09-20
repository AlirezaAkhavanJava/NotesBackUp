In **Spring Boot**, applications are typically structured into **layers** to keep code maintainable and follow separation of concerns. The three layers you mentioned are standard in layered architecture:

---

### 1. **Persistence Layer (Repository Layer / Data Access Layer)**

- Responsible for interacting with the database.
    
- Uses **JPA, Hibernate, JDBC** or other ORM frameworks.
    
- Contains **Entity classes** (mapped to database tables) and **Repository interfaces**.
    
- Example:
    
    ```java
    @Entity
    public class User {
        @Id
        @GeneratedValue
        private Long id;
        private String name;
    }
    
    public interface UserRepository extends JpaRepository<User, Long> {
        Optional<User> findByName(String name);
    }
    ```
    

---

### 2. **Service Layer (Business Logic Layer)**

- Contains **business logic** and acts as a bridge between persistence and presentation.
    
- Defines how data should be processed before returning it to the client.
    
- Uses **@Service** annotation.
    
- Example:
    
    ```java
    @Service
    public class UserService {
        private final UserRepository userRepository;
    
        public UserService(UserRepository userRepository) {
            this.userRepository = userRepository;
        }
    
        public User createUser(String name) {
            User user = new User();
            user.setName(name);
            return userRepository.save(user);
        }
    
        public Optional<User> getUser(String name) {
            return userRepository.findByName(name);
        }
    }
    ```
    

---

### 3. **Presentation Layer (Controller Layer)**

- Handles **HTTP requests and responses**.
    
- Uses **@RestController** or **@Controller** in Spring.
    
- Delegates work to the service layer, doesn’t contain business logic itself.
    
- Example:
    
    ```java
    @RestController
    @RequestMapping("/users")
    public class UserController {
        private final UserService userService;
    
        public UserController(UserService userService) {
            this.userService = userService;
        }
    
        @PostMapping
        public User createUser(@RequestParam String name) {
            return userService.createUser(name);
        }
    
        @GetMapping("/{name}")
        public User getUser(@PathVariable String name) {
            return userService.getUser(name).orElseThrow();
        }
    }
    ```
    

---

✅ Flow:  
**Controller (Presentation)** → **Service (Business)** → **Repository (Persistence)** → **Database**

---

[[0 - Spring Framework]]