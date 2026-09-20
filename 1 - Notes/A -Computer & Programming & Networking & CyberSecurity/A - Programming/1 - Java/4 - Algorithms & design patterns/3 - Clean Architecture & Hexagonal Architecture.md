### Clean Architecture
**Clean Architecture**, proposed by Robert C. Martin (Uncle Bob), is a design philosophy that emphasizes separation of concerns, independence from frameworks, testability, and maintainability. It organizes code into concentric layers, each with a specific responsibility, ensuring that business logic remains independent of external systems like databases, UI, or frameworks.

#### Key Principles of Clean Architecture:
1. **Independence of Frameworks**: The architecture doesn't depend on specific libraries or frameworks, making it adaptable.
2. **Testability**: Business logic can be tested independently of UI, database, or external services.
3. **Independent of UI**: The UI can change without affecting the core logic.
4. **Independent of Database**: The business logic isn't tied to a specific database or storage mechanism.
5. **Dependency Rule**: Dependencies point inward—outer layers depend on inner layers, but inner layers know nothing about outer layers.

#### Layers in Clean Architecture:
1. **Entities**: Core business objects containing business rules and data, independent of any external system.
2. **Use Cases (Interactors)**: Contain application-specific business logic, orchestrating the flow of data to and from entities.
3. **Interface Adapters**: Convert data between the use cases and external systems (e.g., UI, database). Controllers, presenters, and gateways reside here.
4. **Frameworks and Drivers**: The outermost layer, including UI, databases, web frameworks, and other external systems.

#### Example in Java:
```java
// Entity
public class User {
    private String id;
    private String name;

    public User(String id, String name) {
        this.id = id;
        this.name = name;
    }

    public String getName() {
        return name;
    }
}

// Use Case
public interface UserService {
    void createUser(String id, String name);
}

public class UserServiceImpl implements UserService {
    private final UserRepository repository;

    public UserServiceImpl(UserRepository repository) {
        this.repository = repository;
    }

    @Override
    public void createUser(String id, String name) {
        User user = new User(id, name);
        repository.save(user);
    }
}

// Interface Adapter (Repository Interface)
public interface UserRepository {
    void save(User user);
}

// Framework/Driver (e.g., Database Implementation)
public class JpaUserRepository implements UserRepository {
    @Override
    public void save(User user) {
        // JPA-specific code to save user to database
    }
}

// Controller (Interface Adapter)
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    public void createUser(String id, String name) {
        userService.createUser(id, name);
    }
}
```

In this example, the `User` entity is independent, the `UserService` defines the use case, and the `UserRepository` and `UserController` act as adapters to external systems (database and UI, respectively).

---

### Hexagonal Architecture
**Hexagonal Architecture** (also known as Ports and Adapters) is a design pattern introduced by Alistair Cockburn to create loosely coupled systems that are independent of external technologies. It focuses on isolating business logic (the core) from external systems (like UI or databases) by defining "ports" (interfaces) and "adapters" (implementations).

#### Key Principles of Hexagonal Architecture:
1. **Separation of Business Logic**: The core application logic is isolated from external systems.
2. **Ports**: Interfaces that define how the core interacts with the outside world (input/output).
3. **Adapters**: Concrete implementations of ports that connect the core to external systems (e.g., databases, REST APIs, UI).
4. **Invert Dependency**: The core defines what it needs via ports, and adapters implement those needs, ensuring the core remains independent.
5. **Flexibility**: External systems can be swapped (e.g., change database or UI) without modifying the core.

#### Structure:
- **Core**: Contains business logic and entities, along with ports (interfaces) defining interactions.
- **Ports**: Interfaces for input (e.g., API calls from UI) and output (e.g., database operations).
- **Adapters**: Implementations of ports, handling communication with external systems like databases, message queues, or web frameworks.

#### Example in Java:
```java
// Core: Entity
public class Order {
    private String id;
    private String product;

    public Order(String id, String product) {
        this.id = id;
        this.product = product;
    }

    public String getProduct() {
        return product;
    }
}

// Core: Port (Output Port)
public interface OrderRepository {
    void save(Order order);
}

// Core: Port (Input Port)
public interface OrderService {
    void createOrder(String id, String product);
}

// Core: Use Case (Business Logic)
public class OrderServiceImpl implements OrderService {
    private final OrderRepository repository;

    public OrderServiceImpl(OrderRepository repository) {
        this.repository = repository;
    }

    @Override
    public void createOrder(String id, String product) {
        Order order = new Order(id, product);
        repository.save(order);
    }
}

// Adapter: Database Adapter (Implements Output Port)
public class DatabaseOrderRepository implements OrderRepository {
    @Override
    public void save(Order order) {
        // Save order to database (e.g., using JDBC or JPA)
        System.out.println("Saving order: " + order.getProduct());
    }
}

// Adapter: REST Controller (Input Adapter)
public class OrderController {
    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    public void handleCreateOrder(String id, String product) {
        orderService.createOrder(id, product);
    }
}
```

In this example:
- The `Order` entity and `OrderServiceImpl` form the core.
- `OrderRepository` and `OrderService` are ports defining input/output interactions.
- `DatabaseOrderRepository` is an output adapter for database operations, and `OrderController` is an input adapter for handling HTTP requests.

---

### Key Differences Between Clean and Hexagonal Architecture
1. **Conceptual Focus**:
   - **Clean Architecture**: Emphasizes layered separation with a strict dependency rule (inner layers are independent).
   - **Hexagonal Architecture**: Focuses on isolating the core via ports and adapters, with flexibility for external systems.

2. **Structure**:
   - **Clean Architecture**: Uses concentric layers (Entities, Use Cases, Interface Adapters, Frameworks/Drivers).
   - **Hexagonal Architecture**: Centers around a core with ports (interfaces) and adapters (implementations).

3. **Dependency Management**:
   - Both architectures invert dependencies, but Clean Architecture enforces a strict inward dependency flow, while Hexagonal Architecture uses ports to define interactions explicitly.

4. **Granularity**:
   - Clean Architecture is broader, providing a high-level structure for the entire application.
   - Hexagonal Architecture is often applied at the module or component level, focusing on isolating specific business logic.

5. **Terminology**:
   - Clean Architecture uses terms like "entities," "use cases," and "interface adapters."
   - Hexagonal Architecture uses "ports" and "adapters."

---

### Applying in Java
Both architectures are well-suited for Java due to its strong support for interfaces, dependency injection (e.g., Spring), and modular design. Key practices in Java include:
- Use **interfaces** to define ports (Hexagonal) or abstract use cases/adapters (Clean).
- Leverage **dependency injection** (e.g., Spring, Guice) to wire adapters and repositories.
- Organize code into **packages** to reflect layers (Clean) or core/adapters (Hexagonal).
- Ensure **testability** by mocking ports or repositories in unit tests.

Both architectures promote maintainable, testable, and flexible codebases, making them ideal for large-scale Java applications.

#### Tags : [[Algorithm & Design Pattern]]