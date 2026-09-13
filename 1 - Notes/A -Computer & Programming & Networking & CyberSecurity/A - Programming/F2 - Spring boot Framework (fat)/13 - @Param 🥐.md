
In **Spring Data JPA**, `@Param` is used to bind method parameters to named parameters in a JPQL or SQL query. It tells Spring which method argument corresponds to which placeholder in the query.

Here’s a simple example:

```java
public interface EmployeeRepository extends JpaRepository<Employee, Long> {

    @Query("SELECT e FROM Employee e WHERE e.age >= :age")
    List<Employee> findEmployeesOlderThan(@Param("age") Integer age);
}
```

- `:age` in the query is the **named parameter**.
    
- `@Param("age")` tells Spring to use the method’s `age` argument for `:age`.
    

Without `@Param`, Spring can’t match the method argument to the query parameter if you use named parameters.

⚡ **Quick tip:** If you use **positional parameters** like `?1`, `?2`, `@Param` is optional:

```java
@Query("SELECT e FROM Employee e WHERE e.age >= ?1")
List<Employee> findEmployeesOlderThan(Integer age);
```


##### Tags : [[0 - Spring Framework]]