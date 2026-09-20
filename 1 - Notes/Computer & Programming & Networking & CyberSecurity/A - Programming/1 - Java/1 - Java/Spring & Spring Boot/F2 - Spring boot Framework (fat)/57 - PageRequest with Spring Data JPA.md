
Here's a **complete, working example** of using `PageRequest` with Spring Data JPA, including:

- Entity
- Repository
- Service
- REST Controller
- DTO Projection (to avoid exposing entity directly)
- Full pagination response

---

### 1. **Entity** – `User.java`

```java
@Entity
@Table(name = "users")
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String email;
    private int age;
    private boolean active;

    // Getters and Setters
}
```

---

### 2. **DTO** – `UserDTO.java`

```java
public class UserDTO {
    private Long id;
    private String name;
    private String email;
    private int age;

    // Constructor, Getters
    public UserDTO(Long id, String name, String email, int age) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.age = age;
    }
}
```

---

### 3. **Repository** – `UserRepository.java`

```java
public interface UserRepository extends JpaRepository<User, Long> {

    @Query("SELECT new com.example.dto.UserDTO(u.id, u.name, u.email, u.age) " +
           "FROM User u WHERE u.active = true")
    Page<UserDTO> findActiveUsers(Pageable pageable);
}
```

---

### 4. **Service** – `UserService.java`

```java
@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public Page<UserDTO> getActiveUsers(int page, int size, String sortBy, String direction) {
        Sort sort = Sort.by(Sort.Direction.fromString(direction), sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);
        return userRepository.findActiveUsers(pageable);
    }
}
```

---

### 5. **Controller** – `UserController.java`

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping
    public Page<UserDTO> getActiveUsers(
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(100) int size,
            @RequestParam(defaultValue = "name") String sortBy,
            @RequestParam(defaultValue = "asc") String direction) {

        return userService.getActiveUsers(page, size, sortBy, direction);
    }
}
```

---

### 6. **Sample API Calls**

| URL | Result |
|-----|--------|
| `GET /api/users` | Page 0, 10 items, sorted by `name ASC` |
| `GET /api/users?page=1&size=5&sortBy=age&direction=desc` | Page 1, 5 items, age DESC |
| `GET /api/users?size=20` | Page 0, 20 items |

---

### 7. **Sample JSON Response**

```json
{
  "content": [
    {
      "id": 3,
      "name": "Zara",
      "email": "zara@example.com",
      "age": 28
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "offset": 0,
    "sort": {
      "sorted": true,
      "empty": false
    }
  },
  "totalPages": 4,
  "totalElements": 37,
  "last": false,
  "first": true,
  "numberOfElements": 10,
  "size": 10,
  "number": 0
}
```

---

### 8. **GitHub-Ready Project Structure**

```
src/
 └── main/
     ├── java/
     │   └── com/example/
     │       ├── DemoApplication.java
     │       ├── entity/User.java
     │       ├── dto/UserDTO.java
     │       ├── repository/UserRepository.java
     │       ├── service/UserService.java
     │       └── controller/UserController.java
     └── resources/
         └── application.yml
```

`application.yml`:
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/testdb
    username: postgres
    password: password
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
```

---

### Run It!

```bash
./mvnw spring-boot:run
```

Then open:  
[http://localhost:8080/api/users](http://localhost:8080/api/users)

---





#### Tags : [[0 - Spring Framework]]