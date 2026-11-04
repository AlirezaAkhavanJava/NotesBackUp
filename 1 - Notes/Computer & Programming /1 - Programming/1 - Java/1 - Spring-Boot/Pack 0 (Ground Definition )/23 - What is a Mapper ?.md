

A **mapper** is a small piece of code whose only job is to convert one kind of object into another, for example turning a `User` entity into a `UserResponse` DTO, or a `CreateUserRequest` into a `User`. It copies the relevant fields across, renames or reshapes them where needed, and leaves everything else behind. Mappers exist because the layers of an application deliberately use different object shapes (entities for persistence, DTOs for the API), and something has to translate between them. Keeping that translation in one dedicated place stops it from being scattered through your controllers and services.

## The problem mappers solve

In the DTO tutorial we wrote a private `toResponse` method inside the service. That works for one DTO, but it stops scaling quickly:

- Every resource needs several conversions (entity to response, request to entity, entity to summary, update request applied onto an existing entity).
- The same conversion gets copy-pasted into several services.
- Adding a field to an entity means hunting down every place that builds a DTO by hand, and forgetting one produces a silent bug where the field is just `null` in the response.
- Services become cluttered with boring field-copying code that hides the real business logic.

A mapper centralizes all of this: one class per resource, one method per conversion, and the rest of your code simply calls it.

## The manual approach

The simplest mapper is a plain Spring component:

```java
@Component
public class UserMapper {

    public UserResponse toResponse(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail());
    }

    public User toEntity(CreateUserRequest request, String encodedPassword) {
        return new User(request.name(), request.email(), encodedPassword);
    }
}
```

This is explicit, easy to debug, and needs no library. It is a perfectly good choice for small projects, and also whenever a conversion involves real decisions (hashing a password, computing a value, choosing between fields). Its weakness is volume: with dozens of DTOs, the field-by-field code becomes tedious and easy to get out of sync.

## MapStruct: generating the boilerplate

**MapStruct** is the standard library for this in Spring projects. You declare an interface, and at **compile time** it generates the implementation class for you, plain Java with no reflection and no runtime cost.

Add the dependency and the annotation processor (Maven):

```xml
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
    <version>1.6.3</version>
</dependency>

<!-- in maven-compiler-plugin -->
<annotationProcessorPaths>
    <path>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct-processor</artifactId>
        <version>1.6.3</version>
    </path>
</annotationProcessorPaths>
```

Then define the mapper:

```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    UserResponse toResponse(User user);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "password", ignore = true)
    User toEntity(CreateUserRequest request);
}
```

- `componentModel = "spring"` makes the generated class a Spring bean, so you can inject `UserMapper` like any other dependency.
- Fields with the same name and type are mapped automatically.
- `@Mapping` handles the exceptions: renaming (`source = "fullName", target = "name"`), ignoring, constants, or expressions.

After building, look in `target/generated-sources` and you will find a normal `UserMapperImpl` class. Reading it once is the best way to demystify what MapStruct does.

## Using it in a service

```java
@Service
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    // constructor omitted

    @Transactional(readOnly = true)
    public UserResponse get(Long id) {
        return userMapper.toResponse(userRepository.findById(id).orElseThrow());
    }
}
```

The service now reads as business flow, with no field-copying noise.

## Useful MapStruct features

**Nested objects and collections.** If `Order` has a `user` and you want `OrderResponse` to include a `UserResponse`, MapStruct reuses the other mapper method automatically (declare it with `uses = UserMapper.class`). Lists are handled by declaring `List<UserResponse> toResponses(List<User> users);`.

**Updating an existing entity.** For PUT/PATCH endpoints you often want to apply a request onto a managed entity rather than create a new one:

```java
@Mapping(target = "id", ignore = true)
void updateEntity(UpdateUserRequest request, @MappingTarget User user);
```

This pairs naturally with dirty checking: modify the managed entity inside a transaction and Hibernate writes the changes.

**Ignoring nulls in partial updates.** Add `nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE` so `null` fields in a PATCH request do not overwrite existing data.

**Custom logic.** Use `@Mapping(target = "fullName", expression = "java(user.getFirstName() + \" \" + user.getLastName())")` for small cases, or write a `default` method in the interface for anything more involved.

**Compile-time safety.** By default, MapStruct warns when a target field has no source. You can raise this to an error with `unmappedTargetPolicy = ReportingPolicy.ERROR`, which turns the "forgot to map the new field" bug into a build failure.

## MapStruct vs. ModelMapper

||MapStruct|ModelMapper|
|---|---|---|
|When it works|Compile time (generated code)|Runtime (reflection)|
|Errors found|At build|At runtime|
|Performance|As fast as hand-written|Slower|
|Debuggability|Read the generated class|Harder to trace|

MapStruct is the usual recommendation because mistakes surface early and there is no hidden magic.

## Common mistakes

- **Mapping outside a transaction.** If the mapper touches a lazy collection after the session closes, you get `LazyInitializationException`. Map inside the transactional service method.
- **Mapping bidirectional relationships both ways.** `User` to `Order` to `User` recurses forever. Map only the direction your DTO needs, or use a flat DTO with just an ID or name.
- **Putting business logic in the mapper.** Hashing passwords, checking permissions, or calling repositories belong in the service. A mapper should be a pure, side-effect-free translation.
- **Mapping straight onto entities with Lombok `@Data` or setters everywhere.** It works, but it weakens the entity's invariants. Prefer constructors or focused methods where it matters.
- **Forgetting to test it.** A tiny unit test that maps an object and asserts the fields catches most regressions.

## Related concepts to study next

- **MapStruct advanced features**: `@AfterMapping`, qualifiers, and mapping to records or immutable types with builders
- **Spring Data projections**, which skip the entity and mapper entirely for read-only queries
- **Domain model vs. persistence model**, and when a mapper sits between them in hexagonal architecture
- **Bean Validation** on request DTOs, since validation happens before mapping
- **Unit testing mappers** with plain JUnit, no Spring context needed



[[Spring Framework]]