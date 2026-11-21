

All three achieve the same goal — the container supplying a bean's dependencies instead of the bean creating them itself — but differ in **when** and **how** the container hands them over.

---

## 1. Constructor Injection (recommended default)

Dependencies are supplied as constructor parameters.

```java
@Service
public class UserService {

    private final UserRepository userRepository;
    private final EmailService emailService;

    // @Autowired is optional here — Spring 4.3+ auto-detects
    // it when there's exactly one constructor
    public UserService(UserRepository userRepository, EmailService emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}
```

### Why it's preferred

- **Immutability** — fields can be `final`, so once constructed, dependencies can never be reassigned or left null
- **Guaranteed complete object** — you can't create a `UserService` without its dependencies; there's no half-initialized state
- **Easy to test without Spring at all**:
    
    ```java
    UserService service = new UserService(mockRepo, mockEmailService); // plain Java, no container needed
    ```
    
- **Reveals hidden complexity** — if a constructor needs 8 parameters, that's an honest signal the class is doing too much (a code smell you'd miss with field injection, since fields don't show up as visibly)
- **No circular dependency surprises** — Spring fails fast at startup if A needs B and B needs A via constructors (can't resolve → clear error), rather than letting it slip through

---

## 2. Setter Injection

Dependencies are supplied via setter methods after the object is constructed.

```java
@Service
public class UserService {

    private UserRepository userRepository;

    @Autowired
    public void setUserRepository(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

### When to actually use it

- **Optional dependencies** — the bean can function without it, and you want the option to not set it, or change it later
- Reconfiguring a bean **after** construction (rare in typical apps)

### Downsides

- Fields can't be `final` → mutable, less safe
- Object can exist in a partially-constructed state (created but dependency not yet set) → possible `NullPointerException` if used too early
- Less explicit — you have to read through the whole class to know what it actually needs, versus seeing it all in one constructor signature

---

## 3. Field Injection

Dependencies are injected directly into fields via reflection, bypassing constructors/setters entirely.

```java
@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EmailService emailService;
}
```

### Why it's common in tutorials but discouraged in real projects

- Looks the shortest/cleanest superficially — this is exactly why beginners gravitate to it
- **Can't be `final`** — mutable state, dependencies could theoretically be reassigned
- **Can't construct the object without Spring** — you can't easily do `new UserService()` and manually pass in mocks for testing; you'd need reflection or a full Spring test context, which is slower and more heavyweight
- **Hides the true number of dependencies** — no constructor signature forces you to notice "wait, this class needs 10 things, maybe I should split it up"
- Spring's own documentation explicitly recommends against it for production code

Field injection isn't _broken_ — it works — it's a design/maintainability issue, not a bug.


[[Spring Framework]]