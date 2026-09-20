https://www.youtube.com/watch?v=oq-c3D67WqM

 it’s an interface used for **pagination and sorting** in repositories. It allows you to fetch a subset of data rather than all records at once. 

Here’s a quick breakdown:

---

### 1. `Pageable` basics

`Pageable` has three main things:

- **Page number** (`page`) – starts at 0.
    
- **Page size** (`size`) – how many items per page.
    
- **Sort** (`sort`) – optional ordering.
    

---

### 2. Repository usage

```java
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
    Page<User> findByAge(int age, Pageable pageable);
}
```

---

### 3. Service / Controller usage

```java
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

Pageable pageable = PageRequest.of(0, 10, Sort.by("name").ascending());
Page<User> users = userRepository.findByAge(25, pageable);

users.getContent().forEach(System.out::println); // actual list
System.out.println(users.getTotalPages());       // total pages
System.out.println(users.getTotalElements());    // total elements
```

---

✅ **Key points**

- `Page` gives you metadata: total pages, total elements, current page, etc.
    
- You can combine `Pageable` with `Sort`.
    
- For large datasets, it’s much better than fetching everything at once.
    

---

`Pageable` is a Spring Data interface used for pagination and sorting. It's a powerful feature that helps handle large datasets efficiently.

## Basic Usage

### 1. Controller Level
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping
    public Page<User> getUsers(Pageable pageable) {
        return userService.getAllUsers(pageable);
    }
    
    @GetMapping("/search")
    public Page<User> searchUsers(
            @RequestParam String name,
            Pageable pageable) {
        return userService.findUsersByName(name, pageable);
    }
}
```

### 2. Service Level
```java
@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    public Page<User> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable);
    }
    
    public Page<User> findUsersByName(String name, Pageable pageable) {
        return userRepository.findByFirstNameContainingIgnoreCase(name, pageable);
    }
    
    public Page<User> getActiveUsers(int page, int size, String[] sort) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(sort));
        return userRepository.findByStatus("ACTIVE", pageable);
    }
}
```

### 3. Repository Level
```java
public interface UserRepository extends JpaRepository<User, Long> {
    
    // Pagination with derived query
    Page<User> findByLastName(String lastName, Pageable pageable);
    
    // Pagination with custom query
    @Query("SELECT u FROM User u WHERE u.age > :minAge")
    Page<User> findUsersOlderThan(@Param("minAge") int minAge, Pageable pageable);
    
    // Slice for large datasets (more efficient than Page)
    Slice<User> findByEmailContaining(String email, Pageable pageable);
    
    // List with pagination
    List<User> findByFirstName(String firstName, Pageable pageable);
}
```

## Creating Pageable Instances

### 1. Using PageRequest
```java
// Basic pagination
Pageable pageable = PageRequest.of(0, 10); // page 0, size 10

// With sorting
Pageable pageable = PageRequest.of(0, 10, Sort.by("lastName").ascending());

// Multiple sort criteria
Pageable pageable = PageRequest.of(0, 10, 
    Sort.by("lastName").ascending()
        .and(Sort.by("firstName").ascending()));

// Direction specified
Pageable pageable = PageRequest.of(0, 10, 
    Sort.Direction.DESC, "createdDate");
```

### 2. Complex Sorting
```java
// Multiple sort orders
Sort sort = Sort.by(
    Sort.Order.asc("lastName"),
    Sort.Order.desc("createdDate"),
    Sort.Order.asc("firstName")
);
Pageable pageable = PageRequest.of(0, 20, sort);

// Case insensitive sorting
Sort sort = Sort.by(Sort.Order.by("firstName").ignoreCase());
Pageable pageable = PageRequest.of(0, 10, sort);
```

## Working with Page and Slice

### Page vs Slice
```java
@Service
public class UserService {
    
    public void demonstratePageVsSlice() {
        // Page - includes total elements count (expensive for large datasets)
        Page<User> page = userRepository.findAll(PageRequest.of(0, 10));
        List<User> users = page.getContent();
        int totalPages = page.getTotalPages();
        long totalElements = page.getTotalElements();
        boolean hasNext = page.hasNext();
        
        // Slice - doesn't include total count (more efficient)
        Slice<User> slice = userRepository.findAll(PageRequest.of(0, 10));
        List<User> sliceUsers = slice.getContent();
        boolean sliceHasNext = slice.hasNext();
        // No totalPages or totalElements in Slice
    }
}
```

## Custom Page Implementation

### 1. Custom Response DTO
```java
public class PageResponse<T> {
    private List<T> content;
    private int currentPage;
    private int pageSize;
    private long totalElements;
    private int totalPages;
    private boolean first;
    private boolean last;
    
    public static <T> PageResponse<T> of(Page<T> page) {
        PageResponse<T> response = new PageResponse<>();
        response.setContent(page.getContent());
        response.setCurrentPage(page.getNumber());
        response.setPageSize(page.getSize());
        response.setTotalElements(page.getTotalElements());
        response.setTotalPages(page.getTotalPages());
        response.setFirst(page.isFirst());
        response.setLast(page.isLast());
        return response;
    }
    
    // getters and setters
}
```

### 2. Controller with Custom Response
```java
@GetMapping("/custom")
public PageResponse<User> getUsersCustom(Pageable pageable) {
    Page<User> page = userService.getAllUsers(pageable);
    return PageResponse.of(page);
}
```

## Request Parameters

Spring automatically binds these request parameters to Pageable:

### Default Parameters
```
GET /api/users?page=0&size=20&sort=lastName,asc&sort=firstName,desc
```

- `page` - page number (0-based)
- `size` - page size
- `sort` - sort property and direction

### Custom Parameter Names
```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        PageableHandlerMethodArgumentResolver resolver = new PageableHandlerMethodArgumentResolver();
        resolver.setOneIndexedParameters(true); // Use 1-based page indexing
        resolver.setMaxPageSize(100); // Maximum page size
        resolver.setPageParameterName("pageNumber");
        resolver.setSizeParameterName("pageSize");
        resolvers.add(resolver);
    }
}
```

## Advanced Examples

### 1. Custom Pagination Utility
```java
@Component
public class PaginationUtil {
    
    public Pageable createPageable(Integer page, Integer size, String sortBy, String direction) {
        if (page == null) page = 0;
        if (size == null) size = 20;
        if (size > 100) size = 100; // Limit page size
        
        Sort sort = createSort(sortBy, direction);
        return PageRequest.of(page, size, sort);
    }
    
    private Sort createSort(String sortBy, String direction) {
        if (sortBy == null) {
            return Sort.unsorted();
        }
        
        Sort.Direction sortDirection = Sort.Direction.ASC;
        if (direction != null && direction.equalsIgnoreCase("desc")) {
            sortDirection = Sort.Direction.DESC;
        }
        
        return Sort.by(sortDirection, sortBy);
    }
}
```

### 2. Service with Advanced Pagination
```java
@Service
public class AdvancedUserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PaginationUtil paginationUtil;
    
    public Map<String, Object> getUsersWithMetadata(int page, int size, String[] sort) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(sort));
        Page<User> userPage = userRepository.findAll(pageable);
        
        Map<String, Object> response = new HashMap<>();
        response.put("users", userPage.getContent());
        response.put("currentPage", userPage.getNumber());
        response.put("totalItems", userPage.getTotalElements());
        response.put("totalPages", userPage.getTotalPages());
        response.put("hasNext", userPage.hasNext());
        response.put("hasPrevious", userPage.hasPrevious());
        
        return response;
    }
    
    public Page<User> findUsersWithFilters(UserFilter filter, Pageable pageable) {
        Specification<User> spec = Specification.where(null);
        
        if (filter.getFirstName() != null) {
            spec = spec.and((root, query, cb) -> 
                cb.like(cb.lower(root.get("firstName")), 
                       "%" + filter.getFirstName().toLowerCase() + "%"));
        }
        
        if (filter.getMinAge() != null) {
            spec = spec.and((root, query, cb) -> 
                cb.greaterThanOrEqualTo(root.get("age"), filter.getMinAge()));
        }
        
        return userRepository.findAll(spec, pageable);
    }
}
```

### 3. Global Pagination Configuration
```java
@Configuration
public class PaginationConfig {
    
    @Bean
    public PageableHandlerMethodArgumentResolver pageableResolver() {
        PageableHandlerMethodArgumentResolver resolver = 
            new PageableHandlerMethodArgumentResolver();
        
        resolver.setFallbackPageable(PageRequest.of(0, 20));
        resolver.setOneIndexedParameters(true);
        resolver.setMaxPageSize(100);
        
        return resolver;
    }
}
```

## Testing Pageable

```java
@SpringBootTest
class UserServiceTest {
    
    @Autowired
    private UserService userService;
    
    @Test
    void testPagination() {
        // Given
        Pageable pageable = PageRequest.of(0, 10, Sort.by("lastName"));
        
        // When
        Page<User> result = userService.getAllUsers(pageable);
        
        // Then
        assertThat(result.getContent()).hasSize(10);
        assertThat(result.getNumber()).isEqualTo(0);
        assertThat(result.getTotalElements()).isGreaterThan(0);
    }
}
```

## Best Practices

1. **Set reasonable page size limits** to prevent excessive data transfer
2. **Use Slice instead of Page** when total count isn't needed for large datasets
3. **Always validate pageable parameters** in controllers
4. **Use consistent sorting** across paginated endpoints
5. **Consider implementing cursor-based pagination** for infinite scroll scenarios
6. **Cache frequently accessed pages** when appropriate
7. **Use projections** to limit returned data in paginated responses

Pageable makes it easy to implement efficient, scalable pagination in Spring Data JPA applications while maintaining clean, readable code.

#### Tags : [[0 - Spring Framework]]