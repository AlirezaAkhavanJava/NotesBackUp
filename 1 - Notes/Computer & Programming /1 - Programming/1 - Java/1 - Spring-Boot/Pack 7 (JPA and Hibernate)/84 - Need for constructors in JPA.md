
A JPA entity is a plain Java class that Hibernate creates, fills, and tracks for you. A few rules make that possible: how Hibernate gets a fresh instance, how it reads and writes your fields, and what it expects from the class itself. The no-args constructor, getters, and setters are the parts people confuse most, because they look like one package ("the entity boilerplate") but are three different things with three different reasons.

The answer to your question: **Hibernate needs the no-args constructor. It does not need getters or setters.** Your own code needs them, and so do tools like Jackson and MapStruct. That difference is the key to protecting fields that only the application should control.

## Why the no-args constructor is required

When you run `findById(5L)`, Hibernate gets a row of column values back. It has to turn that row into an object, and it can't know what your constructor parameters mean. Is the first `String` the name or the email? So it does this:

1. Calls the no-args constructor to create an empty object.
2. Fills the fields one by one with the column values.

Hibernate also builds **lazy proxies**, which are generated subclasses of your entity that load data on first access (`getReference`, `LAZY` associations). A subclass needs a constructor it can call, and the no-args one is the one it uses.

So the rules for the constructor are:

- It must exist. Without it you get an `InstantiationException` at runtime when an entity is first loaded.
- It can be `protected`. That's the best choice: Hibernate can still call it, but your code can't create half-empty objects by accident.
- The class and its persistent members must not be `final`, or proxies can't subclass them. This is also why a Java `record` can't be an entity, though it works well as a DTO.

Once you add any constructor with arguments, Java stops generating the default one, so you must write the no-args constructor yourself.

## Do getters and setters matter to Hibernate?

It depends on the **access type**, which Hibernate decides by where you put `@Id`:

|`@Id` placed on|Access type|How Hibernate reads and writes data|
|---|---|---|
|a field|field access|reflection directly on the fields; getters and setters are never called|
|a getter method|property access|calls `getX()` and `setX()`|

Almost everyone uses field access, and it's the default in Spring Boot projects. With it, Hibernate fills private fields directly. So an entity with no setters at all is perfectly valid. That's the point that lets you protect fields, as the next section shows.

Getters and setters exist for the code _around_ the entity: your service code, Jackson (JSON), MapStruct (mappers), and so on. They are a convenience for those callers, not a requirement of JPA.

## The danger: user-side and app-side fields mixed in one class

Imagine a user entity where `name` and `email` come from the user, but `id`, `role`, and `createdAt` must only be set by your application. If you accept the entity directly from the request, a user can send fields you never meant to expose:

```java
@PostMapping("/users")
public AppUser create(@RequestBody AppUser user) {   // dangerous
    return userRepository.save(user);
}
```

```json
{ "name": "Sam", "email": "sam@x.com", "role": "ADMIN", "id": 1 }
```

If `role` has a setter, Jackson calls it and the user becomes an admin. This attack is called **mass assignment** (or over-posting): the client sets fields you didn't plan to let it set.

Removing the setter alone isn't enough, which surprises people. By default, Jackson will also write into a **private field** when a getter for it exists. So a getter-only entity bound from `@RequestBody` can still be hit. The real fix has several layers.

## The safe design

**Layer 1: never bind the entity from a request. Use a request DTO with only user-side fields.** This is the main defense. Fields that aren't in the DTO can't be sent, whatever the JSON contains.

```java
public record CreateUserRequest(
    @NotBlank String name,
    @Email @NotBlank String email
) {}
```

**Layer 2: make the entity protect itself.** App-side fields get getters only, and are set inside the entity through its constructor or a method that names the intent.

```java
@Entity
@Table(name = "app_user")
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Long id;                                   // app-side

    @Column(nullable = false, updatable = false)
    private Instant createdAt;                         // app-side

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;                                 // app-side

    @Column(nullable = false)
    private String name;                               // user-side

    @Column(nullable = false, unique = true)
    private String email;                              // user-side

    protected AppUser() {}                             // Hibernate only

    public AppUser(String name, String email) {
        this.name = name;
        this.email = email;
        this.role = Role.USER;
        this.createdAt = Instant.now();
    }

    public void updateProfile(String name, String email) {
        this.name = name;
        this.email = email;
    }

    public void promoteToAdmin() {
        this.role = Role.ADMIN;
    }

    public Long getId() { return id; }
    public Instant getCreatedAt() { return createdAt; }
    public Role getRole() { return role; }
    public String getName() { return name; }
    public String getEmail() { return email; }
}
```

Here is how this answers your "we need both getter and setter, but it isn't safe" problem:

- **User-side fields** can change, but only through `updateProfile(...)`, which is the one door your service uses. If the rule changes later (for example "email can't change after verification"), you edit one method.
- **App-side fields** get a getter and no setter. Hibernate still fills them through field access, so nothing breaks. The only way to change `role` is a method like `promoteToAdmin()`, which your service can guard with its own checks.
- You can still use plain setters for user-side fields if you prefer. What matters is that app-side fields never get one.

**Layer 3: the service applies the DTO to the entity.**

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public AppUser create(CreateUserRequest req) {
        return userRepository.save(new AppUser(req.name(), req.email()));
    }

    @Transactional
    public void updateProfile(Long id, UpdateProfileRequest req) {
        AppUser user = userRepository.findById(id).orElseThrow();
        user.updateProfile(req.name(), req.email());   // no save() needed
    }
}
```

New here: inside a `@Transactional` method, Hibernate watches every entity it loaded and writes the changes at commit. That is called _dirty checking_, and it's why `updateProfile` needs no `save()` call.

**Layer 4: the database column as a last guard.** `@Column(updatable = false)` on `createdAt` tells Hibernate to leave that column out of every `UPDATE` statement, even if some code changes the field in memory. For columns the database fills itself, `insertable = false` does the same for `INSERT`. This protects the data even when application code makes a mistake, and it doesn't replace Layers 1 and 2.

## The other direction: getters leaking data out

Getters can also hurt you on the way out. If you return the entity from a controller, Jackson serializes every getter, so a `getPasswordHash()` ends up in the JSON. Return a response DTO with only the fields the client should see, and keep entities inside the service and persistence layers.

## Related concept: MapStruct and setters

MapStruct generates code that calls setters (or constructors) on the target. If your entity has no setters for app-side fields, MapStruct simply can't map into them, which is the behavior you want. Use it to map the entity to a response DTO freely, and map a request DTO into the entity only through the entity's own methods, like `updateProfile`.


[[Spring Framework]]