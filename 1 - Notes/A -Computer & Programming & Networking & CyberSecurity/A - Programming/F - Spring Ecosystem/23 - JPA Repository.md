Date : 2025-09-12

`JpaRepository` is a **Spring Data JPA** interface that provides CRUD operations and pagination for entities without you writing boilerplate code. It extends other Spring Data interfaces, so it inherits a lot of functionality.

### Hierarchy

```java
Repository (Marker interface)
   ↑
CrudRepository<T, ID>
   ↑
PagingAndSortingRepository<T, ID>
   ↑
JpaRepository<T, ID>
```

### Key Points

- **Generic Parameters**:
    
    - `T` → The entity type.
        
    - `ID` → The type of the entity’s primary key.
        
- **Features**:
    
    1. **CRUD methods** (from `CrudRepository`):
        
        - `save(entity)`
            
        - `findById(id)`
            
        - `findAll()`
            
        - `deleteById(id)`
            
    2. **Paging & Sorting** (from `PagingAndSortingRepository`):
        
        - `findAll(Pageable pageable)`
            
        - `findAll(Sort sort)`
            
    3. **JPA-specific methods** (from `JpaRepository`):
        
        - `saveAndFlush(entity)`
            
        - `deleteInBatch(entities)`
            
        - `getOne(id)` (lazy-loaded reference)
            
        - `findAllInBatch()`
            
- **Query Generation**:  
    You can define methods by naming convention, and Spring generates the query:
    
    ```java
    List<User> findByLastName(String lastName);
    List<User> findByAgeGreaterThan(int age);
    ```
    
- **Custom Queries**:  
    With `@Query`:
    
    ```java
    @Query("SELECT u FROM User u WHERE u.email = ?1")
    User findByEmail(String email);
    ```
    

### Example

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByUsername(String username);

    @Query("SELECT u FROM User u WHERE u.age >= :age")
    List<User> findAdults(@Param("age") int age);
}
```

Now you can inject and use it:

```java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    public List<User> getUsers() {
        return userRepository.findAll();
    }
}
```

👉 Bottom line: `JpaRepository` saves you from writing DAO implementations manually. It’s the standard way to interact with the database in Spring Data JPA projects.




##### *Tags : [[0 - Spring Framework]]