
In Spring Boot, **“Mapper” is not a single Spring stereotype** like `@Service` or `@Repository`. It usually means one of two things:

1. **Persistence Mapper** — most commonly a **MyBatis Mapper** interface.  
2. **Object/DTO Mapper** — e.g. **MapStruct**, ModelMapper, or a custom class that converts Entity ↔ DTO.

Both solve the same general problem: **translating data between two representations** so the rest of the application does not have to do it manually.

---

## 1. What problem does a Mapper solve?

### MyBatis Mapper
A MyBatis Mapper solves the problem of writing repetitive JDBC code:

- Opening/closing connections
- Creating `PreparedStatement`
- Binding parameters
- Iterating `ResultSet`
- Mapping columns to Java fields
- Handling transactions and exceptions

It lets you define an interface method and associate it with SQL, while Spring/MyBatis creates the implementation.

Example problem it removes:

```java
// Without a mapper: lots of JDBC boilerplate
PreparedStatement ps = connection.prepareStatement("SELECT ...");
ps.setLong(1, id);
ResultSet rs = ps.executeQuery();
User user = new User();
user.setId(rs.getLong("id"));
...
```

With a MyBatis Mapper:

```java
@Mapper
public interface UserMapper {
    @Select("SELECT id, name, email FROM users WHERE id = #{id}")
    User findById(@Param("id") Long id);
}
```

### DTO/Object Mapper
A DTO mapper solves the problem of manually copying fields between layers:

```java
UserDto dto = new UserDto();
dto.setId(user.getId());
dto.setName(user.getName());
dto.setEmail(user.getEmail());
```

With MapStruct:

```java
@Mapper(componentModel = "spring")
public interface UserDtoMapper {
    UserDto toDto(User user);
    User toEntity(CreateUserRequest request);
}
```

It also helps:
- Avoid exposing JPA entities directly in REST APIs
- Keep persistence models separate from API models
- Centralize conversion logic
- Reduce bugs from forgotten fields
- Support type conversions, nested mappings, updates, etc.

---

## 2. Which layer owns a Mapper?

| Mapper type | Typical owner layer | Called by | Responsibility |
|---|---|---|---|
| MyBatis Mapper | Persistence / Infrastructure / Data Access layer | Service layer | SQL execution and DB row ↔ Java object mapping |
| DTO Mapper (MapStruct, etc.) | Application / Service layer or dedicated mapper package | Service or Web layer | Entity/Domain ↔ DTO/Request/Response mapping |
| Jackson `ObjectMapper` | Web / Infrastructure layer | Spring MVC / WebFlux | JSON ↔ Java object serialization |

### MyBatis Mapper
- Belongs in the **persistence layer**.
- Usually placed in a package like `com.example.mapper` or `com.example.infrastructure.persistence`.
- Should be called by **services**, not controllers.
- Owns SQL and database result mapping.
- Should not contain business logic.

### DTO Mapper
- Often belongs in the **application/service layer** or a dedicated `mapper` package.
- Called by services when returning DTOs or accepting requests.
- Should only transform data, not decide business rules.
- Can be used in controllers for simple request/response conversion, but service-layer usage is cleaner.

### Jackson ObjectMapper
- Owned by the **web/infrastructure layer**.
- Spring Boot auto-configures it.
- You customize it with `@JsonProperty`, `@JsonIgnore`, `application.properties`, or `Jackson2ObjectMapperBuilderCustomizer`.

---

## 3. How to work with MyBatis Mapper in Spring Boot

### Add dependency

```xml
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>3.0.3</version>
</dependency>
```

### Define the mapper interface

```java
@Mapper
public interface UserMapper {

    @Select("SELECT id, name, email FROM users WHERE id = #{id}")
    User findById(@Param("id") Long id);

    @Insert("""
        INSERT INTO users(name, email)
        VALUES(#{name}, #{email})
        """)
    @Options(useGeneratedKeys = true, keyProperty = "id")
    void insert(User user);
}
```

Or use XML instead of annotations:

```xml
<!-- src/main/resources/mapper/UserMapper.xml -->
<mapper namespace="com.example.mapper.UserMapper">
    <select id="findById" resultType="com.example.domain.User">
        SELECT id, name, email
        FROM users
        WHERE id = #{id}
    </select>
</mapper>
```

Configuration:

```yaml
mybatis:
  mapper-locations: classpath:mapper/*.xml
  type-aliases-package: com.example.domain
```

Or scan all mappers:

```java
@SpringBootApplication
@MapperScan("com.example.mapper")
public class Application { }
```

### Inject and use it in a service

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final UserDtoMapper userDtoMapper;

    @Transactional
    public UserDto create(CreateUserRequest request) {
        User user = userDtoMapper.toEntity(request);
        userMapper.insert(user);
        return userDtoMapper.toDto(user);
    }

    public UserDto findById(Long id) {
        User user = userMapper.findById(id);
        return userDtoMapper.toDto(user);
    }
}
```

Important:
- Put `@Transactional` on the **service**, not on the mapper.
- Do not call mappers directly from controllers.
- Use `@Param` when a method has multiple parameters.
- Use `@Results` / `@ResultMap` for complex column-to-field mappings.

---

## 4. How to work with MapStruct Mapper in Spring Boot

### Add dependencies

```xml
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
    <version>1.5.5.Final</version>
</dependency>

<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct-processor</artifactId>
    <version>1.5.5.Final</version>
    <scope>provided</scope>
</dependency>
```

### Define the mapper

```java
@Mapper(componentModel = "spring")
public interface UserDtoMapper {

    UserDto toDto(User user);

    @Mapping(target = "id", ignore = true)
    User toEntity(CreateUserRequest request);

    @Mapping(target = "id", ignore = true)
    void updateEntity(CreateUserRequest request, @MappingTarget User user);
}
```

MapStruct generates an implementation at compile time, e.g. `UserDtoMapperImpl`, and registers it as a Spring bean because of `componentModel = "spring"`.

### Inject it

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final UserDtoMapper userDtoMapper;

    public UserDto getUser(Long id) {
        User user = userMapper.findById(id);
        return userDtoMapper.toDto(user);
    }
}
```

Useful MapStruct features:
- `@Mapping(source = "...", target = "...")`
- `@MappingTarget` for updates
- `@Mapper(uses = OtherMapper.class)` for nested mappings
- `@BeanMapping(ignoreByDefault = true)` for strict mapping
- `unmappedTargetPolicy = ReportingPolicy.ERROR` to catch missing fields

---

## 5. MyBatis `@Mapper` vs MapStruct `@Mapper`

They have the same simple name but different packages:

```java
org.apache.ibatis.annotations.Mapper   // MyBatis
org.mapstruct.Mapper                   // MapStruct
```

If you use both in the same class, use fully qualified names or separate packages to avoid import conflicts.

---

## 6. Best practices

- Keep mappers thin: no business logic.
- MyBatis mappers belong to the persistence layer.
- DTO mappers belong near the service/application boundary.
- Use constructor injection.
- Use `@Transactional` on service methods.
- Do not expose persistence entities directly from controllers.
- Prefer MapStruct over reflection-based mappers for performance and compile-time safety.
- Test MyBatis mappers with `@MybatisTest`.
- Test MapStruct mappers with plain unit tests.

In short: **a Mapper in Spring Boot is a translation component. A MyBatis Mapper translates SQL ↔ Java objects in the persistence layer; a DTO Mapper translates Entity/Domain ↔ DTO in the service/application layer.**


[[Java]]
[[0 - Spring Framework]]