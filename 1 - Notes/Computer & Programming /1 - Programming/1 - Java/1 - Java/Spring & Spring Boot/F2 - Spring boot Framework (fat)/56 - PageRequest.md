

**`PageRequest` in Spring Data JPA** is the **standard implementation** of the `Pageable` interface. It is used to **define pagination and sorting parameters** when querying data with `Page<T>` or `Slice<T>`.

---

### Class
```java
org.springframework.data.domain.PageRequest
```

---

### Purpose
Creates a `Pageable` object with:
- **Page number** (0-based)
- **Page size**
- **Optional sorting**

Used in repository methods that return `Page<T>` or `Slice<T>`.

---

## How to Create `PageRequest`

### 1. **Basic (page + size)**
```java
Pageable pageable = PageRequest.of(0, 10); // page 0, 10 items
```

### 2. **With Sorting (ascending)**
```java
Pageable pageable = PageRequest.of(
    0,                  // page number
    10,                 // page size
    Sort.by("name").ascending()
);
```

### 3. **With Sorting (descending)**
```java
Pageable pageable = PageRequest.of(
    1, 
    20, 
    Sort.by("createdAt").descending()
);
```

### 4. **Multiple Sort Fields**
```java
Pageable pageable = PageRequest.of(
    0,
    15,
    Sort.by("age").descending().and(Sort.by("name").ascending())
);
```

### 5. **Using `Sort.Direction`**
```java
Pageable pageable = PageRequest.of(
    0, 10,
    Sort.Direction.DESC, "salary", "id"
);
// Sorts by salary DESC, then id DESC
```

---

## Usage in Repository

```java
public interface UserRepository extends JpaRepository<User, Long> {
    
    // Spring parses method name + Pageable
    Page<User> findByActiveTrue(Pageable pageable);

    // With custom @Query
    @Query("SELECT u FROM User u WHERE u.country = ?1")
    Page<User> findByCountry(String country, Pageable pageable);
}
```

---

## In Controller (REST API)

```java
@GetMapping("/users")
public Page<User> getUsers(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size,
        @RequestParam(defaultValue = "name") String sortBy,
        @RequestParam(defaultValue = "asc") String direction) {

    Sort sort = Sort.by(Sort.Direction.fromString(direction), sortBy);
    Pageable pageable = PageRequest.of(page, size, sort);

    return userRepository.findAll(pageable);
}
```

**Example Request:**
```
GET /users?page=2&size=5&sortBy=age&direction=desc
```

---

## Key Methods (from `Pageable`)

| Method | Description |
|-------|-------------|
| `int getPageNumber()` | Current page (0-based) |
| `int getPageSize()` | Items per page |
| `long getOffset()` | `pageNumber * pageSize` |
| `Sort getSort()` | Sorting info |
| `Pageable next()` | Next page |
| `Pageable previousOrFirst()` | Previous or first page |

---

## Best Practices

| Tip | Example |
|-----|--------|
| **Always validate `page` and `size`** | `@Min(0) int page`, `@Max(100) int size` |
| **Set default/max page size** | Use `@PageableDefault` |
| **Use `@PageableDefault`** | Clean controller params |

```java
@GetMapping("/users")
public Page<User> getUsers(
    @PageableDefault(size = 20, sort = "id", direction = Sort.Direction.DESC) 
    Pageable pageable) {
    
    return userRepository.findAll(pageable);
}
```

---

## `@PageableDefault` Example

```java
@GetMapping("/users")
public Page<User> getUsers(
    @PageableDefault(page = 0, size = 15, sort = "createdAt", direction = Sort.Direction.DESC)
    Pageable pageable) {
    
    return userRepository.findAll(pageable);
}
```

Default request: `/users` → page 0, 15 items, sorted by `createdAt DESC`

---

## `PageRequest.of()` – Factory Methods

| Method | Use Case |
|-------|---------|
| `PageRequest.of(page, size)` | Simple pagination |
| `PageRequest.of(page, size, sort)` | With `Sort` object |
| `PageRequest.of(page, size, direction, properties...)` | Quick sort by multiple fields |

---

## Common Pitfalls

| Issue | Fix |
|------|-----|
| `page= -1` → `IncorrectResultSizeException` | Validate `page >= 0` |
| Too large `size` → performance issues | Limit max size (e.g., 100) |
| No sorting → unpredictable order | Always define `Sort` for consistent results |

---

## Summary

| You Need | Use |
|--------|-----|
| Page 1, 20 items, sort by name ASC | `PageRequest.of(0, 20, Sort.by("name"))` |
| Dynamic sort from API | `Sort.by(Direction.fromString(dir), field)` |
| Default pagination | `@PageableDefault` |

---

**Official Docs**:  
[https://docs.spring.io/spring-data/commons/reference/repositories/core-concepts.html#repositories.paging-and-sorting](https://docs.spring.io/spring-data/commons/reference/repositories/core-concepts.html#repositories.paging-and-sorting)

---




##### Tags : [[0 - Spring Framework]]