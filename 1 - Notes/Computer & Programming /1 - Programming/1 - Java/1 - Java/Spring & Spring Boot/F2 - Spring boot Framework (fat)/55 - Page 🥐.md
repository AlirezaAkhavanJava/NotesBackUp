
**`Page<T>` in Spring Data JPA** is a **core interface** that represents **one page of results** from a **paginated query**. It is part of Spring Data's **pagination and sorting** support and is widely used with `PagingAndSortingRepository` or `JpaRepository`.

---

### What is `Page<T>`?

```java
org.springframework.data.domain.Page<T>
```

- `T` is the **entity type** (e.g., `User`, `Product`).
- It contains:
  - A **list of entities** on the current page.
  - **Pagination metadata**: total pages, total elements, current page number, page size, etc.
  - Useful methods to navigate or check pagination state.

---

### Key Methods in `Page<T>`

| Method | Description |
|-------|-------------|
| `List<T> getContent()` | Returns the list of entities on this page |
| `int getNumber()` | Current page number (0-based) |
| `int getSize()` | Number of items per page |
| `long getTotalElements()` | Total number of entities across all pages |
| `int getTotalPages()` | Total number of pages |
| `boolean hasNext()` | Is there a next page? |
| `boolean hasPrevious()` | Is there a previous page? |
| `boolean isFirst()` | Is this the first page? |
| `boolean isLast()` | Is this the last page? |
| `Pageable getPageable()` | The `Pageable` used to request this page |

---

### How to Use It

#### 1. Repository Method

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Page<User> findByAgeGreaterThan(int age, Pageable pageable);
}
```

#### 2. Service / Controller

```java
@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public Page<User> getUsersByAge(int minAge, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("name").ascending());
        return userRepository.findByAgeGreaterThan(minAge, pageable);
    }
}
```

#### 3. REST Controller Example

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping
    public ResponseEntity<Page<User>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "20") int minAge) {

        Page<User> userPage = userService.getUsersByAge(minAge, page, size);

        return ResponseEntity.ok(userPage);
    }
}
```

**Sample JSON Response:**

```json
{
  "content": [ { "id": 1, "name": "Ali", "age": 25 }, ... ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "offset": 0,
    "sort": { "sorted": true, "unsorted": false }
  },
  "totalPages": 5,
  "totalElements": 47,
  "last": false,
  "first": true,
  "numberOfElements": 10,
  "size": 10,
  "number": 0
}
```

---

### `Pageable` – The Request Object

To request a `Page<T>`, you pass a `Pageable`:

```java
Pageable pageable = PageRequest.of(
    pageNumber,     // int
    pageSize,       // int
    Sort.by("field") // optional
);
```

---

### `Page<T>` vs `Slice<T>`

| Feature | `Page<T>` | `Slice<T>` |
|--------|-----------|------------|
| Knows total pages/elements | Yes | No |
| Executes `COUNT` query | Yes | No |
| Performance | Slower (extra query) | Faster |
| Use when | You need total count | Infinite scroll, just need "next" |

> Use `Slice<T>` if you **don’t need total count**.

---

### Custom Query with `@Query`

```java
@Query("SELECT u FROM User u WHERE u.active = true")
Page<User> findActiveUsers(Pageable pageable);
```

---

### Summary

| You Want | Use |
|--------|-----|
| Full pagination (total pages, count) | `Page<T>` |
| Lightweight (no count query) | `Slice<T>` |
| Request pagination | `PageRequest.of(page, size, sort)` |

---

**Official Docs**:  
[https://docs.spring.io/spring-data/jpa/reference/repositories/paging-and-sorting.html](https://docs.spring.io/spring-data/jpa/reference/repositories/paging-and-sorting.html)

Let me know if you want a **working GitHub example** or **DTO mapping with Page**!
#### Tags : [[0 - Spring Framework]]